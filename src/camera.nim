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
        viewport*: tuple[width, height: int]
        transformation*: Transformation

        case kind*: CameraKind
        of ckOrthogonal: discard
        of ckPerspective: 
            distance*: float32 

proc aspectRatio*(camera: Camera): float32 {.inline.} = camera.viewport.width.float32 / camera.viewport.height.float32


proc newOrthogonalCamera*(viewport: tuple[width, height: int], transformation = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckOrthogonal, viewport: viewport, transformation: transformation)

proc newPerspectiveCamera*(viewport: tuple[width, height: int], distance: float32, transformation = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckPerspective, viewport: viewport, transformation: transformation, distance: distance)


proc fireRay*(camera: Camera; pixel: Point2D): Ray {.inline.} = 
    let (origin, dir) = 
        case camera.kind
        of ckOrthogonal: (newPoint3D(-1, (1 - 2 * pixel.u) * camera.aspectRatio, 2 * pixel.v - 1), eX)
        of ckPerspective: (newPoint3D(-camera.distance, 0, 0), newVec3f(camera.distance, (1 - 2 * pixel.u ) * camera.aspectRatio, 2 * pixel.v - 1))
    
    Ray(origin: origin, dir: dir, tSpan: (float32 1.0, float32 Inf), depth: 0).transform(camera.transformation)


type
    PigmentKind* = enum pkUniform, pkTexture, pkCheckered

    Pigment* = object
        case kind*: PigmentKind
        of pkUniform: 
            color*: Color
        of pkTexture: 
            texture*: ptr HDRImage
        of pkCheckered:
            grid*: tuple[c1, c2: Color, nRows, nCols: int]

    BRDFKind* = enum DiffuseBRDF, SpecularBRDF

    BRDF* = object
        pigment*: Pigment

        case kind*: BRDFKind
        of DiffuseBRDF:
            reflectance*: float32
        of SpecularBRDF:
            thresholdAngle*: float32

    Material* = tuple[brdf: BRDF, radiance: Pigment]


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


proc newDiffuseBRDF*(pigment = newUniformPigment(WHITE), reflectance = 1.0): BRDF {.inline.} =
    BRDF(kind: DiffuseBRDF, pigment: pigment, reflectance: reflectance)

proc newSpecularBRDF*(pigment = newUniformPigment(WHITE), angle = 180.0): BRDF {.inline.} =
    BRDF(kind: SpecularBRDF, pigment: pigment, thresholdAngle: (0.1 * degToRad(angle)).float32) 


# proc eval*(brdf: BRDF; normal: Normal, in_dir, out_dir: Vec3f, uv: Point2D): Color {.inline.} =
#     case brdf.kind: 
#     of DiffuseBRDF: 
#         return brdf.pigment.getColor(uv) * (brdf.reflectance / PI)

#     of SpecularBRDF: 
#         if abs(arccos(dot(normal.Vec3f, in_dir.normalize)) - arccos(dot(normal.Vec3f, out_dir.normalize))) <= brdf.threshold_angle: 
#             return brdf.pigment.getColor(uv)
        # else: return BLACK


proc scatterDir*(brdf: BRDF, hitDir: Vec3f, hitNormal: Normal, rg: var PCG): Vec3f =
    # shape local
    case brdf.kind:
    of DiffuseBRDF:
        let 
            (cos2, phi) = (rg.rand, 2 * PI * rg.rand)
            c = sqrt(cos2)
        
        return [float32 c * cos(phi), c * sin(phi), sqrt(1 - cos2)]

    of SpecularBRDF: hitDir - 2 * dot(hitNormal.Vec3f, hitDir) * hitNormal.Vec3f


proc newMaterial*(brdf = newDiffuseBRDF(), pigment = newUniformPigment(WHITE)): Material {.inline.} = (brdf: brdf, radiance: pigment)
