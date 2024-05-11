from std/fenv import epsilon
from std/math import sgn, floor, sqrt, arccos, arctan2, PI
import std/options

import camera, geometry


type 
    Shape* = object of RootObj
        transf*: Transformation

    Sphere* = object of Shape
    Plane* = object of Shape

    HitRecord* = object
        ray*: Ray
        t*: float32
        world_point*: Point3D
        map_pt*: Point2D
        normal*: Normal

    World* = object
        shapes*: seq[Shape]


proc newSphere*(transf: Transformation): Sphere {.inline.} = result.transf = transf
    
proc newPlane*(transf: Transformation): Plane {.inline.} = result.transf = transf

proc newHitRecord*(ray: Ray, t: float32, hit_point: Point3D, uv: Point2D, norm: Normal): HitRecord {.inline.} =
    HitRecord(ray: ray, t: t, world_point: hit_point, map_pt: uv, normal: norm)

proc areClose*(hit1, hit2: HitRecord): bool {.inline.} = 
    areClose(hit1.ray, hit2.ray) and areClose(hit1.t, hit2.t) and 
    areClose(hit1.world_point, hit2.world_point) and  areClose(hit1.map_pt, hit2.map_pt) and 
    areClose(hit1.normal, hit2.normal) 

proc newWorld*(): World {.inline.} = World(shapes: @[])


method rayIntersection*(shape: Shape, ray: Ray): Option[HitRecord] {.base.} =
    quit "to overload"

method fastIntersection*(shape: Shape, ray: Ray): bool {.base.} =
    quit "to overload"


proc normalOnSphere*(p: Point3D, dir: Vec3f): Normal {.inline.} = 
    ## Procedure to compute normal on a surface point
    ## Considering that we are working with an unitary sphere, we can simply use the point coordinates in order to compute the normal. 
    ## We than just have to chose the direction: we will use the value of the dot product with ray direction as a decisive criterium.
    - sgn(dot(p.Vec3f, dir)).float32 * newNormal(p.x, p.y, p.z)


proc sphere_uv*(p: Point3D): Point2D = 
    ## Procedure to compute (u, v) coordinates of the hitpoint
    var u = arctan2(p.y, p.x) / (2 * PI)
    if u < 0.0: u += 1.0

    newPoint2D(u, arccos(p.z) / PI)


method rayIntersection*(sphere: Sphere, ray: Ray): Option[HitRecord] =
    ## Method to detect a ray - sphere intersection
    ## Here we create a sphere centered in (0, 0, 0) and having unitary ray.
    ## We can obtain every kind of sphere and even ellipsoids using specific transformations

    # First off, we have to apply the inverse transformation on the choosen ray: that's because we want to
    # treat the shape in its local reference system where the defining relation is easier to write and solve.
    let 
        rayInv = apply(sphere.transf.inverse(), ray)

        a = norm2(rayInv.dir)
        b = dot(rayInv.start.Vec3f, rayInv.dir)
        c = norm2(rayInv.start.Vec3f) - 1
        delta_4 = b * b - a * c

    if delta_4 < 0: return none(HitRecord)

    let 
        sqrt = sqrt(delta_4)
        t_l = (-b - sqrt) / a
        t_r = (-b + sqrt) / a

    ## We have found the two possible solutions: we now want to chose only the closer one to the observer, that is the one with smaller t. 
    ## We want to consider only solution caracterized by positive time, because we are not interested in shapes located behind the observer.
    var t: float32
    if t_l > rayInv.tmin and t_l < rayInv.tmax:
        t = t_l
    elif t_r > rayInv.tmin and t_r < rayInv.tmax:
        t = t_r
    else:
        return none(HitRecord)
    
    let 
        intersection_pt = rayInv.at(t)
        world_pt = apply(sphere.transf, intersection_pt)
        map_pt = sphere_uv(intersection_pt)
        normal = apply(sphere.transf, normalOnSphere(intersection_pt, rayInv.dir))

    some(newHitRecord(ray, t, world_pt, map_pt, normal))


method fastIntersection*(sphere: Sphere, ray: Ray): bool = 
    let 
        rayInv = apply(sphere.transf.inverse(), ray)
        a = norm2(rayInv.dir)
        b = dot(rayInv.start.Vec3f, rayInv.dir)
        c = norm2(rayInv.start.Vec3f) - 1

        delta_4 = b * b - a * c

    if delta_4 <= 0: false
    else: 
        let t = (-b + sqrt(delta_4)) / a
        (rayInv.tmin < t and t < rayInv.tmax) or (rayInv.tmin < -t and -t < rayInv.tmax) 


method rayIntersection*(plane: Plane, ray: Ray): Option[HitRecord] =
    ## Method to detect a ray - plane intersection

    let inv_ray = apply(plane.transf.inverse(), ray)
    if abs(inv_ray.dir[2]) < epsilon(float32): return none(HitRecord)

    let t = -inv_ray.start.z / inv_ray.dir[2]
    if t < inv_ray.tmin or t > inv_ray.tmax: return none(HitRecord)

    let 
        intersection_pt = inv_ray.at(t)
        world_pt = apply(plane.transf, intersection_pt)
        map_pt = newPoint2D(intersection_pt.x - floor(intersection_pt.x), intersection_pt.y - floor(intersection_pt.y))
        normal = apply(plane.transf, newNormal(0, 0, sgn(-inv_ray.dir[2]).toFloat))

    some(newHitRecord(ray, t, world_pt, map_pt, normal))


method fastIntersection*(plane: Plane, ray: Ray): bool = 
    ## Method that simply states wether there is a intersection or not

    let inv_ray = apply(plane.transf.inverse, ray)
    if abs(inv_ray.dir[2]) < epsilon(float32): return false

    let t = -inv_ray.start.z / inv_ray.dir[2]
    if t < inv_ray.tmin or t > inv_ray.tmax: return false
    
    return true

proc add*(scenary: var World, shape: Shape) {.inline} = scenary.shapes.add(shape)
    ## Procedure to add a shape to a sequence of shapes

proc get*(scenary: World, ind: int): Shape {.inline.} = scenary.shapes[ind]
    ## Procedure to get a shape which is a part of the scenary

proc fire_all_rays*(im_tr: var ImageTracer, pix_col: proc, scenary: World) = 
    # Procedure to actually render an image: we will have to give as an input
    # a function that will enable us to set the color of a pixel
    for y in 0..<im_tr.image.height:
        for x in 0..<im_tr.image.width:
            im_tr.image.setPixel(x, y, pix_col(im_tr, im_tr.fire_ray(x, y), scenary, x, y))