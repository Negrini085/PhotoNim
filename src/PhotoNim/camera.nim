import transformations
import std/math
import geometry
import common

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
    ## Procedure to translate a ray
    result = ray; result.start = result.start + vec;