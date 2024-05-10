from std/fenv import epsilon 
from std/math import exp, pow 
import geometry, hdrimage


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


proc newOrthogonalCamera*(a: float32; transf = Transformation.id): OrthogonalCamera {.inline.} = 
    OrthogonalCamera(aspect_ratio: a, transf: transf)

proc newPerspectiveCamera*(a, d: float32; transf = Transformation.id): PerspectiveCamera {.inline.} = 
    PerspectiveCamera(aspect_ratio: a, distance: d, transf: transf)

proc newRay*(start: Point3D, direction: Vec3f): Ray {.inline} = 
    Ray(start: start, dir: direction, tmin: 1e-5, tmax: Inf, depth: 0)  


#------------------------------------------#
#        Ray procedure and methods         #
#------------------------------------------#

proc at*(ray: Ray, time: float32): Point3D {.inline.} = ray.start + ray.dir * time

proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline} = 
    areClose(a.start, b.start, eps) and areClose(a.dir, b.dir, eps)


method apply*(transf: Transformation, ray: Ray): Ray {.base, inline.} =
    Ray(start: apply(transf, ray.start), dir: apply(transf, ray.dir), tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)

proc translate*(ray: Ray, vec: Vec3f): Ray {.inline.} = 
    Ray(start: ray.start + vec, dir: ray.dir, tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)



#--------------------------------------------#
#        Camera procedure and methods        #
#--------------------------------------------#

method fire_ray*(cam: Camera, pixel: Point2D): Ray {.base.} =
    quit "to overload"

method fire_ray*(cam: OrthogonalCamera, pixel: Point2D): Ray {.inline.} = 
    apply(cam.transf, newRay(newPoint3D(-1, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1), eX))

method fire_ray*(cam: PerspectiveCamera, pixel: Point2D): Ray {.inline.} = 
    apply(cam.transf, newRay(newPoint3D(-cam.distance, 0, 0), newVec3(cam.distance, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1)))

