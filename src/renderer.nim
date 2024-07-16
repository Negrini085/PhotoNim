import pcg, geometry, color, pigment, brdf, material, scene, shape, ray, hitrecord


type
    RendererKind* = enum rkOnOff, rkFlat, rkPathTracer
    Renderer* = object
        case kind*: RendererKind
        of rkFlat: discard
        of rkOnOff: hitColor*: Color
        of rkPathTracer:
            nRays*, depthLimit*, rouletteLimit*: int


proc newFlatRenderer*(): Renderer {.inline.} = Renderer(kind: rkFlat)

proc newOnOffRenderer*(hitColor = WHITE): Renderer {.inline.} = Renderer(kind: rkOnOff, hitColor: hitColor)

proc newPathTracer*(nRays, depthLimit, rouletteLimit: SomeInteger): Renderer {.inline.} =
    Renderer(kind: rkPathTracer, nRays: nRays, depthLimit: depthLimit, rouletteLimit: rouletteLimit)


proc sampleRay*(renderer: Renderer; scene: Scene, worldRay: Ray, rg: var PCG): Color =
    
    case renderer.kind
    of rkOnOff: 
        let closestHit = scene.tree.getClosestHit(worldRay)
        if closestHit.info.hit.isNil: return scene.bgColor
        else: return renderer.hitColor

    of rkFlat: 
        let closestHit = scene.tree.getClosestHit(worldRay)
        if closestHit.info.hit.isNil: return scene.bgColor
        return closestHit.info.hit.material.brdf.pigment.getColor(closestHit.info.hit.shape.getUV(closestHit.pt))

    of rkPathTracer: 
        if (worldRay.depth > renderer.depthLimit): return BLACK

        let closestHit = scene.tree.getClosestHit(worldRay)
        if closestHit.info.hit.isNil: return scene.bgColor
        
        let 
            hitNormal = closestHit.info.hit.shape.getNormal(closestHit.pt, closestHit.rayDir)
            hitSurfacePt = closestHit.info.hit.shape.getUV(closestHit.pt)
            worldHitPt = apply(closestHit.info.hit.transformation, closestHit.pt)

        result = BLACK
        if closestHit.info.hit.material.kind == mkEmissive: 
            result += closestHit.info.hit.material.eRadiance.getColor(hitSurfacePt)

        var hitColor = closestHit.info.hit.material.brdf.pigment.getColor(hitSurfacePt)
        if areClose(hitColor.luminosity, 0.0): return result
        
        if worldRay.depth >= renderer.rouletteLimit:
            let q = max(0.05, 1 - hitColor.luminosity)
            if rg.rand > q: hitColor /= (1.0 - q)
            else: return result

        let nRaysInv = 1 / renderer.nRays.float32
        for _ in 0..<renderer.nRays:
            let 
                outDir = closestHit.info.hit.material.brdf.scatterDir(hitNormal, closestHit.rayDir, rg).normalize
                scatteredRay = Ray(
                    origin: worldHitPt, 
                    dir: apply(closestHit.info.hit.transformation, outDir),
                    depth: worldRay.depth + 1
                )

            result += nRaysInv * hitColor * renderer.sampleRay(scene, scatteredRay, rg)