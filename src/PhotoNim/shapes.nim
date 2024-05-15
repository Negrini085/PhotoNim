from std/fenv import epsilon
from std/math import sgn, floor, sqrt, arccos, arctan2, PI
import std/options

import camera, geometry


type
    AABB* = tuple[min, max: Point3D]

    Shape* = object of RootObj
        transf*: Transformation
        aabb*: Option[AABB] = none(AABB)

    World* = object
        shapes*: seq[Shape]

    HitRecord* = object
        ray*: Ray
        t_hit*: float32
        world_pt*: Point3D
        surface_pt*: Point2D
        normal*: Normal


proc newWorld*(): World {.inline.} = World(shapes: @[])

proc fire_all_rays*(tracer: var ImageTracer, scenary: World, color_map: proc) = 
    ## Procedure to actually render an image: we will have to give as an input a function that will enable us to set the color of a pixel
    for row in 0..<tracer.image.height:
        for col in 0..<tracer.image.width:
            tracer.image.setPixel(row, col, color_map(tracer, tracer.fire_ray(row, col), scenary, row, col))


method fastIntersection*(shape: Shape, ray: Ray): bool {.base.} = quit "to overload"
method rayIntersection*(shape: Shape, ray: Ray): Option[HitRecord] {.base.} = quit "to overload"

type
    AABox* = object of Shape

    Sphere* = object of Shape
        center*: Point3D
        radius*: float32

    Triangle* = object of Shape
        vertices*: tuple[A, B, C: Point3D]

    Plane* = object of Shape


proc newAABox*(min = newPoint3D(0, 0, 0), max = newPoint3D(1, 1, 1), transf = Transformation.id): AABox {.inline.} = AABox(transf: transf, aabb: some(AABB((min, max))))
proc newSphere*(transf = Transformation.id): Sphere {.inline.} = Sphere(transf: transf)    
proc newPlane*(transf = Transformation.id): Plane {.inline.} = Plane(transf: transf)


proc uv*(S: typedesc[Shape], pt: Point3D): Point2D = 
    when S is Sphere:
        var u = arctan2(pt.y, pt.x) / (2 * PI)
        if u < 0.0: u += 1.0
        newPoint2D(u, arccos(pt.z) / PI)

    elif S is AABox:
        if   pt.x == 0: return newPoint2D((1 + pt.y) / 4, (1 + pt.z) / 3)
        elif pt.x == 1: return newPoint2D((3 + pt.x) / 4, (1 + pt.z) / 3)
        elif pt.y == 0: return newPoint2D((2 + pt.x) / 4, (1 + pt.z) / 3)
        elif pt.y == 1: return newPoint2D((1 - pt.x) / 4, (1 + pt.z) / 3)
        elif pt.z == 0: return newPoint2D((1 + pt.y) / 4, (1 - pt.x) / 3)
        elif pt.z == 1: return newPoint2D((1 + pt.y) / 4, (2 + pt.x) / 3)        



proc normal*(box: AABox; dir: Vec3f, t_hit: float32): Normal =
    let aabb = box.aabb.get
    if   t_hit == aabb.min.x or t_hit == aabb.max.x: result = newNormal(1, 0, 0)
    elif t_hit == aabb.min.y or t_hit == aabb.max.y: result = newNormal(0, 1, 0)
    elif t_hit == aabb.min.z or t_hit == aabb.max.z: result = newNormal(0, 0, 1)
    else: quit "Something went wrong in calculating the normal for an AABox."
    return sgn(-dot(result.Vec3f, dir)).float32 * result

proc normal*(sphere: Sphere, pt: Point3D, dir: Vec3f): Normal {.inline.} = sgn(-dot(pt.Vec3f, dir)).float32 * newNormal(pt.x, pt.y, pt.z)


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
        c = norm2(rayInv.origin.Vec3f) - 1.0

        delta_4 = b * b - a * c

    if delta_4 <= 0: return false

    let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
    (rayInv.tmin < t_l and t_l < rayInv.tmax) or (rayInv.tmin < t_r and t_r < rayInv.tmax) 

method fastIntersection*(plane: Plane, ray: Ray): bool = 
    let inv_ray = apply(plane.transf.inverse, ray)
    if abs(inv_ray.dir[2]) < epsilon(float32): return false

    let t = -inv_ray.origin.z / inv_ray.dir[2]
    if t < inv_ray.tmin or t > inv_ray.tmax: false
    else: true



method rayIntersection*(sphere: Sphere, ray: Ray): Option[HitRecord] =
    let 
        rayInv = apply(sphere.transf.inverse, ray)

        a = norm2(rayInv.dir)
        b = dot(rayInv.origin.Vec3f, rayInv.dir)
        c = norm2(rayInv.origin.Vec3f) - 1
        delta_4 = b * b - a * c

    if delta_4 < 0: return none(HitRecord)


    ## We have found the two possible solutions: we now want to chose only the closer one to the observer, that is the one with smaller t. 
    ## We want to consider only solution caracterized by positive time, because we are not interested in shapes located behind the observer.
    var t: float32
    let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
    if t_l > rayInv.tmin and t_l < rayInv.tmax: t = t_l
    elif t_r > rayInv.tmin and t_r < rayInv.tmax: t = t_r
    else: return none(HitRecord)
    
    let 
        intersection_pt = rayInv.at(t)
        world_pt = apply(sphere.transf, intersection_pt)
        surface_pt = Sphere.uv(intersection_pt)
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

    some(newHitRecord(ray, t, world_pt, surface_pt, normal))


method rayIntersection*(box: AABox, ray: Ray): Option[HitRecord] =
    let 
        inv_ray = apply(box.transf.inverse, ray)
        aabb = box.aabb.get
        (min, max) = (aabb.min - ray.origin, aabb.max - ray.origin)
        (tx_min, tx_max) = (min.x / ray.dir[0], max.x / ray.dir[0])
        (ty_min, ty_max) = (min.y / ray.dir[1], max.y / ray.dir[1])
   
    if tx_min > ty_max or ty_min > tx_max: return none(HitRecord)

    let (tz_min, tz_max) = (min.z / ray.dir[2], max.z / ray.dir[2])
    var
        t_hit_min = max(ty_min, tx_min)
        t_hit_max = min(ty_max, tx_max)
        
    if t_hit_min > tz_max or tz_min > t_hit_max: return none(HitRecord)
    
    t_hit_min = max(t_hit_min, tz_min)
    t_hit_max = min(t_hit_max, tz_max)

    proc `<=`(a, b: Point3D): bool {.inline.} = a.x <= b.x and a.y <= b.y and a.z <= b.z
    let t_hit = if inv_ray.origin <= aabb.max and aabb.min <= inv_ray.origin: t_hit_max else: t_hit_min
    
    if (t_hit < inv_ray.tmin) or (t_hit > inv_ray.tmax): return none(HitRecord)

    let 
        intersection_pt = inv_ray.at(t_hit)
        world_pt = apply(box.transf, intersection_pt)
        surface_pt = AABox.uv(intersection_pt)
        normal = box.normal(inv_ray.dir, t_hit)

    some(newHitRecord(ray, t_hit, world_pt, surface_pt, normal))




type 
    Mesh = object of Shape
        nodes: seq[Point3D]
        edges: seq[tuple[first, second: int]]

proc newMesh(nodes: seq[Point3D], edges: seq[tuple[first, second: int]]): Mesh {.inline.} = Mesh(nodes: nodes, edges: edges)
proc newTriangle*(a, b, c: Point3D): Mesh {.inline.} = newMesh(@[a, b, c], @[(0, 1), (1, 2), (2, 0)])