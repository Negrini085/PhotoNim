import common, transformations, camera, geometry
import std/[math, options]

#-------------------------------#
#        Hit Record Type        #
#-------------------------------#
type HitRecord* = object
    world_point*: Point3D
    normal*: Normal
    uv*: Vec2f
    t*: float32
    ray*: Ray


proc newHitRecord*(hit_point: Point3D, norm: Normal, uv: Vec2f, t: float32, ray: Ray): HitRecord {.inline.} =
    ## Procedure to create a new HitRecord object
    result.world_point = hit_point; result.normal = norm; result.uv = uv; result.t = t; result.ray = ray;

proc areClose*(hit1, hit2: HitRecord): bool {.inline.} = 
    ## Procedure to test wether two HitRecord are close or not
    return areClose(hit1.world_point, hit2.world_point) and areClose(hit1.normal, hit2.normal) and areClose(hit1.uv, hit2.uv) and areClose(hit1.t, hit2.t) and areClose(hit1.ray, hit2.ray)



#------------------------------#
#         Shape types          #
#------------------------------#
type Shape* = object of RootObj
    T*: Transformation

method intersectionRay(shape: Shape, ray: Ray): Option[HitRecord] {.base} =
    ## Base procedure to compute ray intersection with a generic shape
    quit "to overload"

type
    Sphere* = object of Shape
    Plane* = object of Shape


#-------------------------------------------#
#        Sphere methods and procedure       #
#-------------------------------------------#
proc newSphere*(T: Transformation): Sphere {.inline.} = 
    ## Sphere object constructor
    result.T = T

proc sphereNorm*(p: Point3D, dir: Vec3f): Normal = 
    ## Procedure to compute normal on a surface point
    # Considering that we are working with an unitary sphere, we can simply use the point coordinates in order to 
    # compute the normal. We than just have to chose the direction: we will use the value of the dot product with ray direction
    # as a decisive criterium.
    result = newNormal(p.x, p.y, p.z)
    if dot2(toVec3(result), dir) > 0:
        result = -result

proc sphere_uv*(p: Point3D): Vec2f = 
    ## Procedure to compute (u, v) coordinates of the hitpoint
    result[0] = arctan2(p.x, p.y)/(2 * PI)
    if result[0] < 0: result[0] += 1
    result[1] = arccos(p.z)/PI