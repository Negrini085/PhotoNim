import geometry, hdrimage

from std/fenv import epsilon 
from std/math import floor, cos, sin, arccos, degToRad, PI

type
    CameraKind* = enum
        ckOrthogonal, ckPerspective

    Camera* = object
        rs*: ReferenceSystem
        aspectRatio*: float32

        case kind*: CameraKind
        of ckOrthogonal: discard
        of ckPerspective: 
            distance*: float32 

    Ray* = ref object
        origin*: Point3D
        dir*: Vec3f
        tSpan*: Interval[float32]
        depth*: int


#     case renderer.camera.kind
#     of ckOrthogonal: newReferenceSystem(apply(renderer.camera.transform, newPoint3D(-1, 0, 0)), renderer.camera.transform.mat.toMat3)
#     of ckPerspective: newReferenceSystem(apply(renderer.camera.transform, newPoint3D(-renderer.camera.distance, 0, 0)), renderer.camera.transform.mat.toMat3)
# )

proc newOrthogonalCamera*(a: float32, transformation = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckOrthogonal, aspectRatio: a)

proc newPerspectiveCamera*(a, d: float32, transformation = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckPerspective, aspectRatio: a, distance: d)

proc newRay*(origin: Point3D, direction: Vec3f): Ray {.inline.} = 
    Ray(origin: origin, dir: direction, tSpan: (epsilon(float32), Inf.float32), depth: 0)  

proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline.} = 
    areClose(a.origin, b.origin, eps) and areClose(a.dir, b.dir, eps)

proc transform*(ray: Ray; transf: Transformation): Ray {.inline.} =
    case transf.kind: 
    of tkIdentity: return ray
    of tkTranslation, tkScaling: 
        return Ray(origin: apply(transf, ray.origin), dir: ray.dir, tSpan: ray.tSpan, depth: ray.depth)
    of tkGeneric, tkRotation, tkComposition:
        return Ray(origin: apply(transf, ray.origin), dir: apply(transf, ray.dir), tSpan: ray.tSpan, depth: ray.depth)

proc at*(ray: Ray; time: float32): Point3D {.inline.} = ray.origin + ray.dir * time


proc fireRay*(cam: Camera; pixel: Point2D): Ray {.inline.} = 
    case cam.kind
    of ckOrthogonal:
        result = newRay(newPoint3D(-1, (1 - 2 * pixel.u) * cam.aspectRatio, 2 * pixel.v - 1), eX)
    of ckPerspective:
        result = newRay(newPoint3D(-cam.distance, 0, 0), newVec3(cam.distance, (1 - 2 * pixel.u) * cam.aspectRatio, 2 * pixel.v - 1))
    
    # here we must change something. 
    # Since we generate a subScene viewed from the camera point after its transformation, 
    # each ray should be casted from the origin of that ref system. 
    # result = result.transform(cam.transform)


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
            grid*: tuple[color1, color2: Color, nsteps: int]

proc newUniformPigment*(color: Color): Pigment {.inline.} = Pigment(kind: pkUniform, color: color)
proc newTexturePigment*(texture: HDRImage): Pigment {.inline.} = Pigment(kind: pkTexture, texture: addr texture)
proc newCheckeredPigment*(color1, color2: Color, nsteps: int): Pigment {.inline.} = Pigment(kind: pkCheckered, grid: (color1, color2, nsteps))

proc getColor*(pigment: Pigment; uv: Point2D): Color =
    case pigment.kind: 
    of pkUniform: 
        return pigment.color

    of pkTexture: 
        var (col, row) = (floor(uv.u * pigment.texture.width.float32).int, floor(uv.v * pigment.texture.height.float32).int)
        if col >= pigment.texture.width: col = pigment.texture.width - 1
        if row >= pigment.texture.height: row = pigment.texture.height - 1

        return pigment.texture[].getPixel(col, row)

    of pkCheckered:
        let (col, row) = (floor(uv.u * pigment.grid.nsteps.float32).int, floor(uv.v * pigment.grid.nsteps.float32).int)
        return (if (col mod 2) == (row mod 2): pigment.grid.color1 else: pigment.grid.color2)


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
        if abs(arccos(dot(normal.Vec3f, in_dir)) - arccos(dot(normal.Vec3f, out_dir))) < brdf.threshold_angle: 
            return brdf.pigment.getColor(uv)
        else: return BLACK