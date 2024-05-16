from std/fenv import epsilon 
from std/math import exp, pow 
import geometry, hdrimage


type Ray* = object
    origin*: Point3D
    dir*: Vec3f
    tmin*: float32
    tmax*: float32
    depth*: int

proc newRay*(origin: Point3D, direction: Vec3f): Ray {.inline} = Ray(origin: origin, dir: direction, tmin: epsilon(float32), tmax: Inf, depth: 0)  
proc at*(ray: Ray; time: float32): Point3D {.inline.} = ray.origin + ray.dir * time
proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline} = areClose(a.origin, b.origin, eps) and areClose(a.dir, b.dir, eps)

method apply*(transf: Transformation, ray: Ray): Ray {.base, inline.} =
    Ray(origin: apply(transf, ray.origin), dir: apply(transf, ray.dir), tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)

proc translate*(ray: Ray, vec: Vec3f): Ray {.inline.} = 
    Ray(origin: ray.origin + vec, dir: ray.dir, tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)


type
    CameraKind* = enum
        ckOrthogonal, ckPerspective

    Camera* = object of RootObj
        transf*: Transformation
        aspect_ratio*: float32

        case kind: CameraKind
        of ckOrthogonal: discard
        of ckPerspective: 
            distance: float32 

proc newOrthogonalCamera*(a: float32; transf = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckOrthogonal, transf: transf, aspect_ratio: a)

proc newPerspectiveCamera*(a, d: float32; transf = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckPerspective, transf: transf, aspect_ratio: a, distance: d)

proc fire_ray*(cam: Camera; pixel: Point2D): Ray {.inline.} = 
    case cam.kind
    of ckOrthogonal:
        apply(cam.transf, newRay(newPoint3D(-1, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1), eX))
    of ckPerspective:
        apply(cam.transf, newRay(newPoint3D(-cam.distance, 0, 0), newVec3(cam.distance, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1)))

    
type ImageTracer* = object
    image*: HdrImage
    camera*: Camera


proc newImageTracer*(im: HdrImage, cam: Camera): ImageTracer {.inline.} = ImageTracer(image: im, camera: cam)


proc fire_ray*(im_tr: ImageTracer; x, y: int, pixel = newPoint2D(0.5, 0.5)): Ray {.inline.} =
    im_tr.camera.fire_ray(newPoint2D((x.float32 + pixel.u) / im_tr.image.width.float32, 1 - (y.float32 + pixel.v) / im_tr.image.height.float32))

proc fire_all_rays*(im_tr: var ImageTracer) = 
    for x in 0..<im_tr.image.height:
        for y in 0..<im_tr.image.width:
            discard im_tr.fire_ray(x, y)
            let 
                r = (1 - exp(-float32(x + y)))
                g = y / im_tr.image.height
                b = pow((1 - x / im_tr.image.width), 2.5)
            im_tr.image.setPixel(x, y, newColor(r, g, b))
