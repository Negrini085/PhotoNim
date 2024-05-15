from std/fenv import epsilon 
from std/math import exp, pow 
import geometry, hdrimage


type
    Camera* = object of RootObj
        aspect_ratio*, distance*: float32
        transf*: Transformation 

    OrthogonalCamera* = object of Camera
    PerspectiveCamera* = object of Camera

    Ray* = object
        origin*: Point3D
        dir*: Vec3f
        tmin*: float32
        tmax*: float32
        depth*: int
    
    ImageTracer* = object
        image*: HdrImage
        camera*: Camera


proc newOrthogonalCamera*(a: float32; transf = Transformation.id): OrthogonalCamera {.inline.} = 
    OrthogonalCamera(aspect_ratio: a, transf: transf, distance: Inf)

proc newPerspectiveCamera*(a, d: float32; transf = Transformation.id): PerspectiveCamera {.inline.} = 
    PerspectiveCamera(aspect_ratio: a, transf: transf, distance: d)

proc newRay*(origin: Point3D, direction: Vec3f): Ray {.inline} = 
    Ray(origin: origin, dir: direction, tmin: epsilon(float32), tmax: Inf, depth: 0)  

proc newImageTracer*(im: HdrImage, cam: Camera): ImageTracer {.inline.} = 
    ImageTracer(image: im, camera: cam)

#------------------------------------------#
#        Ray procedure and methods         #
#------------------------------------------#

proc at*(ray: Ray, time: float32): Point3D {.inline.} = ray.origin + ray.dir * time

proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline} = 
    areClose(a.origin, b.origin, eps) and areClose(a.dir, b.dir, eps)


method apply*(transf: Transformation, ray: Ray): Ray {.base, inline.} =
    Ray(origin: apply(transf, ray.origin), dir: apply(transf, ray.dir), tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)

proc translate*(ray: Ray, vec: Vec3f): Ray {.inline.} = 
    Ray(origin: ray.origin + vec, dir: ray.dir, tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)



#--------------------------------------------#
#        Camera procedure and methods        #
#--------------------------------------------#

method fire_ray*(cam: Camera, pixel: Point2D): Ray {.base.} =
    quit "to overload"

method fire_ray*(cam: OrthogonalCamera, pixel: Point2D): Ray {.inline.} = 
    apply(cam.transf, newRay(newPoint3D(-1, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1), eX))

method fire_ray*(cam: PerspectiveCamera, pixel: Point2D): Ray {.inline.} = 
    apply(cam.transf, newRay(newPoint3D(-cam.distance, 0, 0), newVec3(cam.distance, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1)))



#--------------------------------------------------#
#        Image Tracer procedure and methods        #
#--------------------------------------------------#

proc fire_ray*(im_tr: ImageTracer, row, col: int, pixel = newPoint2D(0.5, 0.5)): Ray =
    let (u, v) = ((col.float32 + pixel.u) / im_tr.image.width.float32, 1 - (row.float32 + pixel.v) / im_tr.image.height.float32)
    im_tr.camera.fire_ray(newPoint2D(u, v))

proc fire_all_rays*(im_tr: var ImageTracer) = 
    for row in 0..<im_tr.image.height:
        for col in 0..<im_tr.image.width:
            discard im_tr.fire_ray(row, col)
            let 
                    col1 = (1 - exp(-float32(col + row)))
                    col2 = row/im_tr.image.height
                    col3 = pow((1 - col/im_tr.image.width), 2.5)
            im_tr.image.setPixel(row, col, newColor(col1, col2, col3))
