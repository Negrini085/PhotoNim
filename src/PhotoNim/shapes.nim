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
    result[0] = arctan2(p.y, p.x)/(2 * PI)
    if result[0] < 0: result[0] += 1
    result[1] = arccos(p.z)/PI


method intersectionRay(sphere: Sphere, ray: Ray): Option[HitRecord] =
    ## Method to detect a ray - sphere intersection
    # Here we create a sphere centered in (0, 0, 0) and having unitary ray.
    # We can obtain every kind of sphere and even ellipsoids using specific transformations

    var
        origin = newPoint3D(0, 0, 0)
        t1, t2, t, delta_4: float32
        radius: float32 = 1
        a, b, c: float32
        rayInv: Ray

    # First off, we have to apply the inverse transformation on the choosen ray: that's because we want to
    # treat the shape in its local reference system where the defining relation is easier to write and solve.
    rayInv = transformRay(sphere.T.inverse(), ray)

    # Working in the local reference system of the sphere, we now compute the possible soluzion of the equation 
    # describing the intersection event: if a parameter delta is bigger than zero we have two solutions. On the other hand, 
    # if delta is zero or negative, we won't purse a deeper analysis of the fenomenon and we will return null.
    a = rayInv.dir.norm2()
    b = dot2(toVec3(rayInv.start), rayInv.dir)
    c = toVec3(rayInv.start).norm2() - 1

    delta_4 = pow(b, 2) - a * c
    if delta_4 < 0: return none(HitRecord)

    t1 = - (b + sqrt(delta_4))/a
    t2 =  (-b + sqrt(delta_4))/a

    # We have found the two possible solutions: we now want to chose only the closer one to the observer, that is 
    # the one with smaller t. We want to consider only solution caracterized by positive time, because we are not
    # interested in shapes located behind the observer.
    if t1 > rayInv.tmin and t1 < rayInv.tmax:
        t = t1
    elif t2 > rayInv.tmin and t2 < rayInv.tmax:
        t = t2
    else:
        return none(HitRecord)

    return some(newHitRecord(apply(sphere.T, rayInv.at(t)),apply(sphere.T, sphereNorm(rayInv.at(t), rayInv.dir)), sphere_uv(rayInv.at(t)), t, ray))
   
