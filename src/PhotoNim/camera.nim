import transformations
import std/math
import geometry
import common

#--------------------------------------#
#        Ray type implementation       # 
#--------------------------------------#
type
    Ray* = object
        start*: Point3D
        dir*: Vec3f
        tmin*: float32
        tmax*: float32
        depth*: int

proc newRay*(p0: Point3D, direction: Vec3f): Ray {.inline} = 
    ## Procedure to create a new light ray
    result.start = p0; result.dir = direction; result.tmin = 0.0; result.tmax = Inf; result.depth = 0

proc at*(ray: Ray, time: float32): Point3D =
    ## Procedure to determine position at a certain time t
    result = ray.start + ray.dir * time

proc areClose*(ray1, ray2: Ray): bool {.inline} =
    ## Procedure to check wether rays are close or not
    result = areClose(ray1.start, ray2.start) and areClose(ray1.dir, ray2.dir)

proc translateRay*(ray: Ray, vec: Vec3f): Ray =
    ## Procedure to translate a ray: vector defining translation is given
    result = ray; result.start = result.start + vec;

proc translateRay*(T: Translation, ray: Ray): Ray =
    ## Procedure to translate a ray: translation transformation is given as an input
    result.start = toPoint3D(apply(T, toVec4(ray.start))); result.dir = ray.dir
    result.tmin = ray.tmin; result.tmax = ray.tmax; result.depth = ray.depth

proc rotateRay*(T: Rotation, ray: Ray): Ray =
    ## Procedure to rotate a ray: we are considering a rotation around an axis such that ray.start is a part of the axis
    result.start = ray.start; result.dir = toVec3(apply(T, toVec4(ray.dir)))
    result.tmin = ray.tmin; result.tmax = ray.tmax; result.depth = ray.depth



#-----------------------------------------#
#        Camera type implementation       #
#-----------------------------------------#

type
    Camera* = object of RootObj
        aspect_ratio*: float32
        T*: Transformation 

method fire_ray*(cam: Camera, u,v: float32): Ray {.base.} =
    ## Base fire ray method

#-----------------------------------------#
#           Orthogonal Camera             #
#-----------------------------------------#

type OrthogonalCamera = object of Camera

proc newCamera*(a: float32, T: Transformation): OrthogonalCamera {.inline.} = 
    ## Orthogonal Camera type constructor
    result.aspect_ratio = a; result.T = T