import geometry, hdrimage, pcg

from std/fenv import epsilon 
from std/math import floor, sqrt, cos, sin, arccos, degToRad, PI


type Ray* = ref object
    origin*: Point3D
    dir*: Vec3f
    tSpan*: Interval[float32]
    depth*: int

proc newRay*(origin: Point3D, direction: Vec3f, depth: int = 0): Ray {.inline.} = 
    Ray(origin: origin, dir: direction, tSpan: (float32 1.0, float32 Inf), depth: depth)  

proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline.} = 
    areClose(a.origin, b.origin, eps) and areClose(a.dir, b.dir, eps)

proc transform*(ray: Ray; transformation: Transformation): Ray {.inline.} =
    case transformation.kind: 
    of tkIdentity: ray
    of tkTranslation: 
        Ray(
            origin: apply(transformation, ray.origin), 
            dir: ray.dir, 
            tSpan: ray.tSpan, depth: ray.depth
        )
    else: 
        Ray(
            origin: apply(transformation, ray.origin), 
            dir: apply(transformation, ray.dir), 
            tSpan: ray.tSpan, depth: ray.depth
        )

proc at*(ray: Ray; time: float32): Point3D {.inline.} = ray.origin + ray.dir * time


type
    CameraKind* = enum
        ckOrthogonal, ckPerspective

    Camera* = object
        rs*: ReferenceSystem
        viewport*: tuple[width, height: int]

        case kind*: CameraKind
        of ckOrthogonal: discard
        of ckPerspective: 
            distance*: float32 

proc aspectRatio*(camera: Camera): float32 {.inline.} = camera.viewport.width.float32 / camera.viewport.height.float32


proc newOrthogonalCamera*(viewport: tuple[width, height: int], origin: Point3D = ORIGIN3D, rotation = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckOrthogonal, viewport: viewport, rs: newReferenceSystem(origin, rotation))

proc newPerspectiveCamera*(viewport: tuple[width, height: int], distance: float32, origin: Point3D = ORIGIN3D, rotation = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckPerspective, viewport: viewport, distance: distance, rs: newReferenceSystem(origin, rotation))


proc fireRay*(camera: Camera; pixel: Point2D): Ray {.inline.} = 
    case camera.kind
    of ckOrthogonal: newRay(newPoint3D(-1, (1 - 2 * pixel.u) * camera.aspectRatio, 2 * pixel.v - 1), eX)
    of ckPerspective: newRay(newPoint3D(-camera.distance, 0, 0), newVec3f(camera.distance, (1 - 2 * pixel.u ) * camera.aspectRatio, 2 * pixel.v - 1))
    

type
    PigmentKind* = enum
        pkUniform, pkTexture, pkCheckered

    Pigment* = object
        case kind*: PigmentKind
        of pkUniform: 
            color*: Color
        of pkTexture: 
            texture*: ptr HDRImage
        of pkCheckered:
            grid*: tuple[c1, c2: Color, nRows, nCols: int]

proc newUniformPigment*(color: Color): Pigment {.inline.} = Pigment(kind: pkUniform, color: color)
proc newTexturePigment*(texture: HDRImage): Pigment {.inline.} = Pigment(kind: pkTexture, texture: addr texture)
proc newCheckeredPigment*(color1, color2: Color, nRows, nCols: int): Pigment {.inline.} = Pigment(kind: pkCheckered, grid: (color1, color2, nRows, nCols))

proc getColor*(pigment: Pigment; uv: Point2D): Color =
    case pigment.kind: 
    of pkUniform: pigment.color

    of pkTexture: 
        var (col, row) = (floor(uv.u * pigment.texture.width.float32).int, floor(uv.v * pigment.texture.height.float32).int)
        if col >= pigment.texture.width: col = pigment.texture.width - 1
        if row >= pigment.texture.height: row = pigment.texture.height - 1

        return pigment.texture[].getPixel(col, row)

    of pkCheckered:
        let (col, row) = (floor(uv.u * pigment.grid.nCols.float32).int, floor(uv.v * pigment.grid.nRows.float32).int)
        return (if (col mod 2) == (row mod 2): pigment.grid.c1 else: pigment.grid.c2)


type 
    BRDFKind* = enum 
        DiffuseBRDF, SpecularBRDF

    BRDF* = object
        pigment*: Pigment

        case kind*: BRDFKind
        of DiffuseBRDF:
            reflectance*: float32
        of SpecularBRDF:
            threshold_angle*: float32


proc newDiffuseBRDF*(pigment = newUniformPigment(WHITE), reflectance = 1.0): BRDF {.inline.} =
    BRDF(kind: DiffuseBRDF, pigment: pigment, reflectance: reflectance)

proc newSpecularBRDF*(pigment = newUniformPigment(WHITE), angle = 180.0): BRDF {.inline.} =
    BRDF(kind: SpecularBRDF, pigment: pigment, threshold_angle: (0.1 * degToRad(angle)).float32) 


proc eval*(brdf: BRDF; normal: Normal, in_dir, out_dir: Vec3f, uv: Point2D): Color {.inline.} =
    case brdf.kind: 
    of DiffuseBRDF: 
        return brdf.pigment.getColor(uv) * (brdf.reflectance / PI)

    of SpecularBRDF: 
        if abs(arccos(dot(normal.Vec3f, in_dir.normalize)) - arccos(dot(normal.Vec3f, out_dir.normalize))) <= brdf.threshold_angle: 
            return brdf.pigment.getColor(uv)
        else: return BLACK


proc scatter*(refSystem: ReferenceSystem, hitRay: Ray, brdf: BRDF, rg: var PCG): Ray =
    case brdf.kind:
    of DiffuseBRDF:
        let 
            cos2 = rg.rand
            (c, s) = (sqrt(cos2), sqrt(1 - cos2))
            phi = 2 * PI * rg.rand
        
        Ray(
            origin: ORIGIN3D, 
            dir: [float32 c * cos(phi), c * sin(phi), s], 
            tSpan: (float32 1e-3, float32 Inf), 
            depth: hitRay.depth + 1
        )

    of SpecularBRDF: 
        Ray(
            origin: ORIGIN3D,
            dir: refSystem.project(hitRay.dir - 2 * dot(refSystem.base[0], hitRay.dir) * refSystem.base[0]),
            tspan: (float32 1e-3, float32 Inf), 
            depth: hitRay.depth + 1
        )