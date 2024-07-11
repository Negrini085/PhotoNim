import geometry, pcg, hdrimage, material, scene, shape, hitrecord

from std/fenv import epsilon
from std/strutils import repeat
from std/terminal import fgWhite, fgRed, fgYellow, fgGreen, eraseLine, styledWrite, resetAttributes
from std/strformat import fmt
from std/math import pow
from std/sequtils import applyIt, filterIt

from std/threadpool import parallel, spawn, spawnX, sync
# {.experimental.}


type
    RendererKind* = enum
        rkOnOff, rkFlat, rkPathTracer

    Renderer* = object
        case kind*: RendererKind
        of rkFlat: discard

        of rkOnOff:
            hitCol*: Color

        of rkPathTracer:
            directSamples*: int
            indirectSamples*: int
            depthLimit*, rouletteLimit*: int


    CameraKind* = enum
        ckOrthogonal, ckPerspective

    Camera* = object
        renderer*: Renderer

        viewport*: tuple[width, height: int]
        transformation*: Transformation

        case kind*: CameraKind
        of ckOrthogonal: discard
        of ckPerspective: 
            distance*: float32 



proc newFlatRenderer*(): Renderer {.inline.} = Renderer(kind: rkFlat)
proc newOnOffRenderer*(hitCol = WHITE): Renderer {.inline.} = Renderer(kind: rkOnOff, hitCol: hitCol)

proc newPathTracer*(directSamples: SomeInteger = 5, indirectSamples: SomeInteger = 5, depthLimit: SomeInteger = 10, rouletteLimit: SomeInteger = 3): Renderer {.inline.} =
    Renderer(kind: rkPathTracer, directSamples: directSamples, indirectSamples: indirectSamples, depthLimit: depthLimit, rouletteLimit: rouletteLimit)


proc newOrthogonalCamera*(renderer: Renderer, viewport: tuple[width, height: int], transformation = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckOrthogonal, renderer: renderer, viewport: viewport, transformation: transformation)

proc newPerspectiveCamera*(renderer: Renderer, viewport: tuple[width, height: int], distance: float32, transformation = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckPerspective, renderer: renderer, viewport: viewport, transformation: transformation, distance: distance)

proc aspectRatio*(camera: Camera): float32 {.inline.} = camera.viewport.width.float32 / camera.viewport.height.float32


proc fireRay*(camera: Camera; pixel: Point2D): Ray {.inline.} = 
    let (origin, dir) = 
        case camera.kind
        of ckOrthogonal: (newPoint3D(-1, (1 - 2 * pixel.u) * camera.aspectRatio, 2 * pixel.v - 1), eX)
        of ckPerspective: (newPoint3D(-camera.distance, 0, 0), newVec3f(camera.distance, (1 - 2 * pixel.u ) * camera.aspectRatio, 2 * pixel.v - 1))
    
    Ray(origin: origin, dir: dir, tSpan: (epsilon(float32), float32 Inf), depth: 0).transform(camera.transformation)



proc displayProgress(current, total: int) =
    let
        percentage = int(100 * current / total)
        progress = 50 * current div total
        bar = "[" & repeat("#", progress) & repeat("-", 50 - progress) & "]"
        color = if percentage <= 50: fgYellow else: fgGreen

    stdout.eraseLine
    stdout.styledWrite(fgWhite, "Rendering progress: ", fgRed, "0% ", fgWhite, bar, color, fmt" {percentage}%")
    stdout.flushFile


proc sampleLights*(scene: Scene, worldRay: Ray, hitHandler: ObjectHandler, worldHitPt: Point3D, hitNormal: Normal): Color =
    for lightHandler in scene.handlers.filterIt(it.isLight):
        case lightHandler.kind:
        of hkPoint:
            let 
                lightDir = (worldHitPt - apply(lightHandler.transformation, ORIGIN3D)).Vec3f.normalize
                lightRay = newRay(worldHitPt, lightDir)
                lightHit = scene.tree.getClosestHit(scene.handlers, lightRay)
                distance2 = lightDir.norm2
            
            if lightHit.info.val.isNil or pow(lightHit.info.t, 2) <= distance2: continue

            let
                lightHitPt = lightRay.at(lightHit.info.t)
                lightHitSurfacePt = lightHit.info.val.shape.getUV(lightHitPt)

                brdfFactor = hitHandler.material.brdf.eval(hitNormal.Vec3f, -lightDir, worldRay.dir)
                angleFactor = max(0, dot(-lightDir, hitNormal.Vec3f))

            result += lightHandler.material.emittedRadiance.getColor(lightHitSurfacePt) * brdfFactor * angleFactor / distance2

        of hkShape: discard
            # for _ in 0..<camera.renderer.directSamples:
                # let
                #     lightSamplePt = lightHandler.shape.samplePoint(rg)
                #     lightPos = apply(lightHandler.transformation, lightSamplePt)
                #     lightDir = (lightPos - worldHitPt).Vec3f.normalize
                #     lightRay = newRay(worldHitPt, lightDir)
                #     lightHit = scene.tree.getClosestHit(scene.handlers, lightRay)
                #     distance2 = (lightPos - worldHitPt).norm2

                # if lightHit.info.val.isNil or pow(lightHit.info.t, 2) > distance2:
                #     let
                #         brdfFactor = hitHandler.material.brdf.eval(hitNormal.Vec3f, lightDir, worldRay.dir)
                #         angleFactor = max(0, dot(lightDir, hitNormal.Vec3f))
                #         pdf = lightHandler.shape.pdf(worldHitPt, lightPos)

                #     result += (lightHandler.material.emittedRadiance.getColor(Point2D(0.0, 0.0)) * brdfFactor * angleFactor / (pdf * distance2)) / camera.renderer.numLightSamples.float32

        
        of hkMesh: discard


proc sampleRay(camera: Camera; scene: Scene, worldRay: Ray, rg: var PCG): Color =
    
    case camera.renderer.kind
    of rkOnOff: discard
    of rkFlat: discard

    of rkPathTracer: 
        if (worldRay.depth > camera.renderer.depthLimit): return BLACK

        let closestHit = scene.tree.getClosestHit(scene.handlers, worldRay)
        if closestHit.info.val.isNil: return scene.bgColor
        
        if closestHit.info.val.isLight: return BLUE

        let 
            hitSurfacePt = closestHit.info.val.shape.getUV(closestHit.pt)
            worldHitPt = apply(closestHit.info.val.transformation, closestHit.pt)
            worldHitNormal = apply(closestHit.info.val.transformation, closestHit.normal)
        
        result = closestHit.info.val.material.emittedRadiance.getColor(hitSurfacePt)
        result += scene.sampleLights(worldRay, closestHit.info.val, worldHitPt, worldHitNormal)

        # var hitCol = closestHit.info.val.material.brdf.pigment.getColor(hitSurfacePt)
        # if worldRay.depth >= camera.renderer.rouletteLimit:
        #     let q = max(0.05, 1 - hitCol.luminosity)
        #     if rg.rand > q: hitCol /= (1.0 - q)
        #     else: return result

        let hitColor = closestHit.info.val.material.brdf.pigment.getColor(hitSurfacePt)

        let invNumRays = 1 / camera.renderer.directSamples.float32
        for _ in 0..<camera.renderer.directSamples:
            let 
                outDir = closestHit.info.val.material.brdf.scatterDir(closestHit.normal, closestHit.dir, rg).normalize
                scatteredRay = Ray(
                    origin: worldHitPt, 
                    dir: apply(closestHit.info.val.transformation, outDir),
                    tSpan: (1e-5.float32, Inf.float32),
                    depth: worldRay.depth + 1
                )

            result += invNumRays * hitColor * camera.sampleRay(scene, scatteredRay, rg)

        
proc samplePixel(x, y: int, rgSetUp: RandomSetUp, aaSamples: int; camera: Camera, scene: Scene): Color =
    let aaFactor = 1 / aaSamples.float32

    var rg = newPCG(rgSetUp)
    for u in 0..<aaSamples:
        for v in 0..<aaSamples:
            let ray = camera.fireRay(
                newPoint2D(
                    (x.float32 + (u.float32 + rg.rand) * aaFactor) / camera.viewport.width.float32,
                    1 - (y.float32 + (v.float32 + rg.rand) * aaFactor) / camera.viewport.height.float32
                )
            )

            result += camera.sampleRay(scene, ray, rg)
    
    result *= pow(aaFactor, 2)


proc sample*(camera: Camera; scene: Scene, rgSetUp: RandomSetUp, aaSamples: int = 1, displayProgress = true): HDRImage =
    var rg = newPCG(rgSetUp)

    result = newHDRImage(camera.viewport.width, camera.viewport.height)
    for y in 0..<camera.viewport.height:
        if displayProgress: displayProgress(y, camera.viewport.height - 1)
        for x in 0..<camera.viewport.width:
            result.setPixel(x, y, samplePixel(x, y, newRandomSetUp(rg.random, rg.random), aaSamples, camera, scene))

    if displayProgress: stdout.eraseLine; stdout.resetAttributes


proc samples*(camera: Camera; scene: Scene, rgSetUp: RandomSetUp, nSamples: int = 1, aaSamples: int = 1, displayProgress = true): HDRImage =
    result = newHDRImage(camera.viewport.width, camera.viewport.height)

    if nSamples > 1:
        var rg = newPCG(rgSetUp)
        for _ in countup(0, nSamples): 
            spawn stack(
                addr result, 
                camera.sample(scene, newRandomSetUp(rg.random, rg.random), aaSamples, displayProgress = false)
            )
        
        sync()
        result.pixels.applyIt(it / nSamples.float32)

    else: result = camera.sample(scene, rgSetUp, aaSamples, displayProgress = true)