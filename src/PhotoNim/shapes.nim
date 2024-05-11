from std/fenv import epsilon
from std/math import sgn, floor, sqrt, arccos, arctan2, PI
import std/options

import camera, geometry


type 
    AABB* = tuple[min, max: Point3D]

    Shape* = object of RootObj
        transf*: Transformation
        aabb*: Option[AABB]

    AABox* = object of Shape
    Sphere* = object of Shape
    Plane* = object of Shape


proc newAABox*(min = newPoint3D(0, 0, 0), max = newPoint3D(1, 1, 1), transf = Transformation.id): AABox {.inline.} = 
    AABox(transf: transf, aabb: some(AABB((min, max))))

proc newSphere*(transf = Transformation.id): Sphere {.inline.} = Sphere(transf: transf, aabb: none(AABB))    
proc newPlane*(transf = Transformation.id): Plane {.inline.} = Plane(transf: transf, aabb: none(AABB))


method fastIntersection*(shape: Shape, ray: Ray): bool {.base.} =
    quit "to overload"


method fastIntersection*(box: AABox, ray: Ray): bool =
    let 
        aabb = box.aabb.get
        (min, max) = (aabb.min - ray.origin, aabb.max - ray.origin)
        (tx_min, tx_max) = (min.x / ray.dir[0], max.x / ray.dir[0])
        (ty_min, ty_max) = (min.y / ray.dir[1], max.y / ray.dir[1])
   
    if tx_min > ty_max or ty_min > tx_max: return false

    let
        t_hit_min = if ty_min > tx_min: ty_min else: tx_min
        t_hit_max = if ty_max < tx_max: ty_max else: tx_max   
        (tz_min, tz_max) = (min.z / ray.dir[2], max.z / ray.dir[2])
        
    if t_hit_min > tz_max or tz_min > t_hit_max: false
    else: true


method fastIntersection*(sphere: Sphere, ray: Ray): bool = 
    let 
        rayInv = apply(sphere.transf.inverse(), ray)
        a = norm2(rayInv.dir)
        b = dot(rayInv.origin.Vec3f, rayInv.dir)
        c = norm2(rayInv.origin.Vec3f) - 1

        delta_4 = b * b - a * c

    if delta_4 <= 0: false
    else: 
        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        (rayInv.tmin < t_l and t_l < rayInv.tmax) or (rayInv.tmin < t_r and t_r < rayInv.tmax) 


method fastIntersection*(plane: Plane, ray: Ray): bool = 
    let inv_ray = apply(plane.transf.inverse, ray)
    if abs(inv_ray.dir[2]) < epsilon(float32): return false

    let t = -inv_ray.origin.z / inv_ray.dir[2]
    if t < inv_ray.tmin or t > inv_ray.tmax: false
    else: true



type HitRecord* = object
    ray*: Ray
    t*: float32
    world_pt*: Point3D
    map_pt*: Point2D
    normal*: Normal

proc newHitRecord*(ray: Ray, t: float32, hit_point: Point3D, uv: Point2D, normal: Normal): HitRecord {.inline.} =
    HitRecord(ray: ray, t: t, world_pt: hit_point, map_pt: uv, normal: normal)

proc areClose*(hit1, hit2: HitRecord): bool {.inline.} = 
    areClose(hit1.ray, hit2.ray) and areClose(hit1.t, hit2.t) and 
    areClose(hit1.world_pt, hit2.world_pt) and  areClose(hit1.map_pt, hit2.map_pt) and 
    areClose(hit1.normal, hit2.normal) 


method rayIntersection*(shape: Shape, ray: Ray): Option[HitRecord] {.base.} =
    quit "to overload"


proc spherePointToUV*(p: Point3D): Point2D = 
    var u = arctan2(p.y, p.x) / (2 * PI)
    if u < 0.0: u += 1.0
    newPoint2D(u, arccos(p.z) / PI)

proc sphereNormal*(p: Point3D, dir: Vec3f): Normal {.inline.} = 
    ## Procedure to compute normal on a surface point
    ## Considering that we are working with an unitary sphere, we can simply use the point coordinates in order to compute the normal. 
    ## We than just have to chose the direction: we will use the value of the dot product with ray direction as a decisive criterium.
    sgn(-dot(p.Vec3f, dir)).float32 * newNormal(p.x, p.y, p.z)


method rayIntersection*(sphere: Sphere, ray: Ray): Option[HitRecord] =
    ## Method to detect a ray - sphere intersection
    ## Here we create a sphere centered in (0, 0, 0) and having unitary ray.
    ## We can obtain every kind of sphere and even ellipsoids using specific transformations

    # First off, we have to apply the inverse transformation on the choosen ray: that's because we want to
    # treat the shape in its local reference system where the defining relation is easier to write and solve.
    let 
        rayInv = apply(sphere.transf.inverse, ray)

        a = norm2(rayInv.dir)
        b = dot(rayInv.origin.Vec3f, rayInv.dir)
        c = norm2(rayInv.origin.Vec3f) - 1
        delta_4 = b * b - a * c

    if delta_4 < 0: return none(HitRecord)

    let 
        t_l = (-b - sqrt(delta_4)) / a
        t_r = (-b + sqrt(delta_4)) / a

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
        map_pt = spherePointToUV(intersection_pt)
        normal = apply(sphere.transf, sphereNormal(intersection_pt, rayInv.dir))

    some(newHitRecord(ray, t, world_pt, map_pt, normal))


method rayIntersection*(plane: Plane, ray: Ray): Option[HitRecord] =
    let inv_ray = apply(plane.transf.inverse(), ray)
    if abs(inv_ray.dir[2]) < epsilon(float32): return none(HitRecord)

    let t = -inv_ray.origin.z / inv_ray.dir[2]
    if t < inv_ray.tmin or t > inv_ray.tmax: return none(HitRecord)

    let 
        intersection_pt = inv_ray.at(t)
        world_pt = apply(plane.transf, intersection_pt)
        map_pt = newPoint2D(intersection_pt.x - floor(intersection_pt.x), intersection_pt.y - floor(intersection_pt.y))
        normal = apply(plane.transf, newNormal(0, 0, sgn(-inv_ray.dir[2]).toFloat))

    some(newHitRecord(ray, t, world_pt, map_pt, normal))


proc AABoxPointToUV*(point: Point3D): Point2D =
    if point.x == 0:   return newPoint2D((1 + point.y) / 4, (1 + point.z) / 3)
    elif point.x == 1: return newPoint2D((3 + point.x) / 4, (1 + point.z) / 3)
    elif point.y == 0: return newPoint2D((2 + point.x) / 4, (1 + point.z) / 3)
    elif point.y == 1: return newPoint2D((1 - point.x) / 4, (1 + point.z) / 3)
    elif point.z == 0: return newPoint2D((1 + point.y) / 4, (1 - point.x) / 3)
    elif point.z == 1: return newPoint2D((1 + point.y) / 4, (2 + point.x) / 3)

proc boxNormal*(box: AABox; dir: Vec3f, t_hit: float32): Normal =
    ## Check in which face of the cube there is the intersection and calculate the normal knowing pmin and pmax.
    let sgn = sgn(-dot(result.Vec3f, dir)).float32
    let aabb = box.aabb.get
    if   t_hit == aabb.min.x or t_hit == aabb.max.x: return sgn * newNormal(1, 0, 0)
    elif t_hit == aabb.min.y or t_hit == aabb.max.y: return sgn * newNormal(0, 1, 0)
    elif t_hit == aabb.min.z or t_hit == aabb.max.z: return sgn * newNormal(0, 0, 1)


# method rayIntersection*(box: AABox, ray: Ray): Option[HitRecord] =
#     let 
#         pmin = box.min - ray.origin
#         pmax = box.max - ray.origin

#     var
#         tx_min = pmin.x / ray.dir[0]
#         ty_min = pmin.y / ray.dir[1]
#         tz_min = pmin.z / ray.dir[2]

#         tx_max = pmax.x / ray.dir[0]
#         ty_max = pmax.y / ray.dir[1]
#         tz_max = pmax.z / ray.dir[2]

#     if tx_min > tx_max: swap(tx_min, tx_max)
#     if ty_min > ty_max: swap(ty_min, ty_max)
#     if tz_min > tz_max: swap(tz_min, tz_max)

#     var 
#         t_hit_min = tx_min
#         t_hit_max = tx_max

#     if tx_min > ty_max or ty_min > tx_max: return none((float,float))

#     if ty_min > tx_min: t_hit_min = ty_min
#     if ty_max < tx_max: t_hit_max = ty_max

#     if t_hit_min > tz_max or tz_min > t_hit_max: return none((float,float))

#     if tz_min > t_hit_min: t_hit_min = tz_min
#     if tz_max < t_hit_max: t_hit_max = tz_max

#     some((t_hit_min, t_hit_max))



type World* = object
    shapes*: seq[Shape]

proc newWorld*(): World {.inline.} = World(shapes: @[])

proc fire_all_rays*(im_tr: var ImageTracer, color_map: proc, scenary: World) = 
    ## Procedure to actually render an image: we will have to give as an input a function that will enable us to set the color of a pixel
    for row in 0..<im_tr.image.height:
        for col in 0..<im_tr.image.width:
            im_tr.image.setPixel(row, col, color_map(im_tr, im_tr.fire_ray(row, col), scenary, row, col))