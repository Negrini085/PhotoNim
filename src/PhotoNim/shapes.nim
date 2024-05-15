from std/fenv import epsilon
from std/math import sgn, floor, sqrt, arccos, arctan2, PI
import std/options

import camera, geometry


type HitRecord* = object
    ray*: Ray
    t_hit*: float32
    world_pt*: Point3D
    surface_pt*: Point2D
    normal*: Normal

proc newHitRecord*(ray: Ray, t: float32, hit_point: Point3D, uv: Point2D, normal: Normal): HitRecord {.inline.} =
    HitRecord(ray: ray, t_hit: t, world_pt: hit_point, surface_pt: uv, normal: normal)

proc areClose*(a, b: HitRecord): bool {.inline.} = 
    areClose(a.ray, b.ray) and areClose(a.t_hit, b.t_hit) and 
    areClose(a.world_pt, b.world_pt) and areClose(a.surface_pt, b.surface_pt) and 
    areClose(a.normal, b.normal) 


type
    AABB* = tuple[min, max: Point3D]

    Shape* = object of RootObj
        transf*: Transformation
        aabb*: Option[AABB] = none(AABB)

method uv(shape: Shape, pt: Point3D): Point2D {.base.} = quit "to overload"
method fastIntersection*(shape: Shape, ray: Ray): bool {.base.} = quit "to overload"
method rayIntersection*(shape: Shape, ray: Ray): Option[HitRecord] {.base.} = quit "to overload"


type
    AABox* = object of Shape
    Sphere* = object of Shape
    Plane* = object of Shape

proc newAABox*(min = newPoint3D(0, 0, 0), max = newPoint3D(1, 1, 1), transf = Transformation.id): AABox {.inline.} = AABox(transf: transf, aabb: some(AABB((min, max))))
proc newSphere*(transf = Transformation.id): Sphere {.inline.} = Sphere(transf: transf)    
proc newPlane*(transf = Transformation.id): Plane {.inline.} = Plane(transf: transf)


method uv*(box: AABox, pt: Point3D): Point2D =
    if   pt.x == 0: return newPoint2D((1 + pt.y) / 4, (1 + pt.z) / 3)
    elif pt.x == 1: return newPoint2D((3 + pt.x) / 4, (1 + pt.z) / 3)
    elif pt.y == 0: return newPoint2D((2 + pt.x) / 4, (1 + pt.z) / 3)
    elif pt.y == 1: return newPoint2D((1 - pt.x) / 4, (1 + pt.z) / 3)
    elif pt.z == 0: return newPoint2D((1 + pt.y) / 4, (1 - pt.x) / 3)
    elif pt.z == 1: return newPoint2D((1 + pt.y) / 4, (2 + pt.x) / 3)

method uv*(sphere: Sphere, pt: Point3D): Point2D = 
    var u = arctan2(pt.y, pt.x) / (2 * PI)
    if u < 0.0: u += 1.0
    newPoint2D(u, arccos(pt.z) / PI)


proc boxNormal*(box: AABox; dir: Vec3f, t_hit: float32): Normal =
    let aabb = box.aabb.get
    let sgn = sgn(-dot(result.Vec3f, dir)).float32
    if   t_hit == aabb.min.x or t_hit == aabb.max.x: return sgn * newNormal(1, 0, 0)
    elif t_hit == aabb.min.y or t_hit == aabb.max.y: return sgn * newNormal(0, 1, 0)
    elif t_hit == aabb.min.z or t_hit == aabb.max.z: return sgn * newNormal(0, 0, 1)

proc sphereNormal*(pt: Point3D, dir: Vec3f): Normal {.inline.} = sgn(-dot(pt.Vec3f, dir)).float32 * newNormal(pt.x, pt.y, pt.z)


method fastIntersection*(box: AABox, ray: Ray): bool =
    let 
        aabb = box.aabb.get
        (min, max) = (aabb.min - ray.origin, aabb.max - ray.origin)
        (tx_min, tx_max) = (min.x / ray.dir[0], max.x / ray.dir[0])
        (ty_min, ty_max) = (min.y / ray.dir[1], max.y / ray.dir[1])
   
    if tx_min > ty_max or ty_min > tx_max: return false

    let
        t_hit_min = max(ty_min, tx_min)
        t_hit_max = min(ty_max, tx_max)
        (tz_min, tz_max) = (min.z / ray.dir[2], max.z / ray.dir[2])
        
    if t_hit_min > tz_max or tz_min > t_hit_max: false
    else: true

method fastIntersection*(sphere: Sphere, ray: Ray): bool = 
    let 
        rayInv = apply(sphere.transf.inverse, ray)
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
        surface_pt = sphere.uv(intersection_pt)
        normal = apply(sphere.transf, sphere.normal(intersection_pt, rayInv.dir))

    some(newHitRecord(ray, t, world_pt, surface_pt, normal))


method rayIntersection*(plane: Plane, ray: Ray): Option[HitRecord] =
    let inv_ray = apply(plane.transf.inverse, ray)
    if abs(inv_ray.dir[2]) < epsilon(float32): return none(HitRecord)

    let t = -inv_ray.origin.z / inv_ray.dir[2]
    if t < inv_ray.tmin or t > inv_ray.tmax: return none(HitRecord)

    let 
        intersection_pt = inv_ray.at(t)
        world_pt = apply(plane.transf, intersection_pt)
        surface_pt = newPoint2D(intersection_pt.x - floor(intersection_pt.x), intersection_pt.y - floor(intersection_pt.y))
        normal = apply(plane.transf, newNormal(0, 0, sgn(-inv_ray.dir[2]).toFloat))

    some(newHitRecord(ray, t, world_pt, map_pt, normal))


type World* = object
    shapes*: seq[Shape]

proc newWorld*(): World {.inline.} = World(shapes: @[])

proc fire_all_rays*(tracer: var ImageTracer, scenary: World, color_map: proc) = 
    ## Procedure to actually render an image: we will have to give as an input a function that will enable us to set the color of a pixel
    for row in 0..<tracer.image.height:
        for col in 0..<tracer.image.width:
            tracer.image.setPixel(row, col, color_map(tracer, tracer.fire_ray(row, col), scenary, row, col))
