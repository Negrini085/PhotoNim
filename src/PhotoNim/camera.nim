import transformation
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

proc newRay*(p0: Point, direction: Vec3f): Ray {.inline} = 
    ## Procedure to create a new light ray
    result.start = p0; result.dir = direction; result.tmin = 0.0; result.tmax = Inf; result.depth = 0