from std/fenv import epsilon 

import geometry
import hdrimage


type
    Camera* = object of RootObj
        aspect_ratio*: float32
        transf*: Transformation 

    OrthogonalCamera* = object of Camera
    PerspectiveCamera* = object of Camera
        distance*: float32

    Ray* = object
        start*: Point3D
        dir*: Vec3f
        tmin*: float32
        tmax*: float32
        depth*: int


proc newCamera*(a: float32; transf = Transformation.id): OrthogonalCamera {.inline.} = 
    OrthogonalCamera(aspect_ratio: a, transf: transf)

proc newCamera*(a, d: float32; transf = Transformation.id): PerspectiveCamera {.inline.} = 
    PerspectiveCamera(aspect_ratio: a, distance: d, transf: transf)


proc newRay*(start: Point3D, direction: Vec3f): Ray {.inline} = 
    Ray(start: start, dir: direction, tmin: 1e-5, tmax: Inf, depth: 0)  

proc translateRay*(ray: Ray, vec: Vec3f): Ray {.inline.} = 
    Ray(start: ray.start + vec, dir: ray.dir, tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)

proc transformRay*(transf: Transformation, ray: Ray): Ray {.inline.} =
    Ray(start: apply(transf, ray.start), dir: apply(transf, ray.dir), tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)

proc at*(ray: Ray, time: float32): Point3D {.inline.} = ray.start + ray.dir * time

proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline} = 
    areClose(a.start, b.start, eps) and areClose(a.dir, b.dir, eps)


method fire_ray*(cam: Camera, pix_pt: Point2D): Ray {.base.} =
    quit "to overload"

method fire_ray*(cam: OrthogonalCamera, pix_pt: Point2D): Ray {.inline.} = 
    let origin = newPoint3D(-1, (1 - 2 * pix_pt.u) * cam.aspect_ratio, 2 * pix_pt.v - 1)
    transformRay(cam.transf, newRay(origin, eX))

method fire_ray*(cam: PerspectiveCamera, pix_pt: Point2D): Ray {.inline.} = 
    let origin = newPoint3D(-cam.distance, 0, 0)
    let dir = newVec3(cam.distance, (1 - 2 * pix_pt.u) * cam.aspect_ratio, 2 * pix_pt.v - 1)
    transformRay(cam.transf, newRay(origin, dir))



type ImageTracer* = object
    image*: HdrImage
    camera*: Camera

proc newImageTracer*(im: HdrImage, cam: Camera): ImageTracer {.inline.} = ImageTracer(image: im, camera: cam)

proc fire_ray*(im_tr: ImageTracer, col, row: int, pix_pt: Point2D = newPoint2D(0.5, 0.5)): Ray =
    let u = (col.toFloat + pix_pt.u) / im_tr.image.width.toFloat
    let v = 1 - (row.toFloat + pix_pt.v) / im_tr.image.height.toFloat
    
    im_tr.camera.fire_ray(newPoint2D(u, v))

proc fire_all_rays*(im_tr: var ImageTracer) = 
    for i in 0..<im_tr.image.height:
        for j in 0..<im_tr.image.width:
            discard im_tr.fire_ray(i, j)
            let pixColor = i * j / (im_tr.image.width * im_tr.image.height)
            im_tr.image.setPixel(i, j, newColor(pixColor, pixColor, pixColor))
