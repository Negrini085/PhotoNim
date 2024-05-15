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

proc newWorld*(): World {.inline.} = World(shapes: @[])

proc fire_all_rays*(tracer: var ImageTracer, scenary: World, color_map: proc) = 
    for y in 0..<tracer.image.height:
        for x in 0..<tracer.image.width:
            tracer.image.setPixel(x, y, color_map(tracer, tracer.fire_ray(x, y), scenary, x, y))


type
    AABox* = object of Shape

    Sphere* = object of Shape
        center*: Point3D
        radius*: float32

    Triangle* = object of Shape
        vertices*: tuple[A, B, C: Point3D]

    Plane* = object of Shape


proc newAABox*(min = newPoint3D(0, 0, 0), max = newPoint3D(1, 1, 1), transf = Transformation.id): AABox {.inline.} = AABox(transf: transf, aabb: some(AABB((min, max))))

proc newSphere*(center: Point3D, radius: float32): Sphere {.inline.} = 
    Sphere(
        transf: newTranslation(center.Vec3f) @ newScaling(radius), 
        center: center,
        radius: radius
    )

proc newUnitarySphere*(center: Point3D): Sphere {.inline.} = 
    Sphere(
        transf: newTranslation(center.Vec3f), 
        center: center,
        radius: 1.0
    )

proc newPlane*(transf = Transformation.id): Plane {.inline.} = Plane(transf: transf)
proc newTriangle*(a, b, c: Point3D): Triangle {.inline.} = Triangle(vertices: (a, b, c))


proc uv*[S: Shape](shape: S, pt: Point3D): Point2D = 
    when S is AABox:
        if   pt.x == 0: return newPoint2D((1 + pt.y) / 4, (1 + pt.z) / 3)
        elif pt.x == 1: return newPoint2D((3 + pt.x) / 4, (1 + pt.z) / 3)
        elif pt.y == 0: return newPoint2D((2 + pt.x) / 4, (1 + pt.z) / 3)
        elif pt.y == 1: return newPoint2D((1 - pt.x) / 4, (1 + pt.z) / 3)
        elif pt.z == 0: return newPoint2D((1 + pt.y) / 4, (1 - pt.x) / 3)
        elif pt.z == 1: return newPoint2D((1 + pt.y) / 4, (2 + pt.x) / 3)   

    elif S is Triangle:
        let 
            (A, B, C) = shape.verteces
            u_num = (pt.x - A.x)*(C.y - A.y) - (pt.y - A.y)*(C.x - A.x)
            u_den = (B.x - A.x)*(C.y - A.y) - (B.y - A.y)*(C.x - A.x)
            u = u_num / u_den
            v_num = (pt.x - A.x)*(B.y - A.y) - (pt.y - A.y)*(B.x - A.x)
            v_den = (C.x - A.x)*(B.y - A.y) - (C.y - A.y)*(B.x - A.x)
            v = v_num / v_den
        newPoint2D(u, v)
        
    elif S is Sphere:
        var u = arctan2(pt.y, pt.x) / (2 * PI)
        if u < 0.0: u += 1.0
        newPoint2D(u, arccos(pt.z) / PI)

    elif S is Plane: newPoint2D(pt.x - floor(pt.x), pt.y - floor(pt.y))


proc normal*[S: Shape](shape: S; pt: Point3D, dir: Vec3f): Normal = 
    when S is AABox:
        let aabb = shape.aabb.get
        if   pt.x == aabb.min.x or pt.x == aabb.max.x: result = newNormal(1, 0, 0)
        elif pt.y == aabb.min.y or pt.y == aabb.max.y: result = newNormal(0, 1, 0)
        elif pt.z == aabb.min.z or pt.z == aabb.max.z: result = newNormal(0, 0, 1)
        else: quit "Something went wrong in calculating the normal for an AABox."
        sgn(-dot(result.Vec3f, dir)).float32 * result

    elif S is Triangle:
        let 
            (A, B, C) = shape.verteces
        result = cross((B - A).Vec3f, (C - A).Vec3f).toNormal
        sgn(-dot(result.Vec3f, dir)).float32 * result
        
    elif S is Sphere: sgn(-dot(pt.Vec3f, dir)).float32 * newNormal(pt.x, pt.y, pt.z)
    elif S is Plane: newNormal(0, 0, sgn(-dir[2]).float32)


proc fastIntersection*[S: Shape](shape: S, ray: Ray): bool =
    when S is AABox:
        let 
            aabb = shape.aabb.get
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

    elif S is Sphere: 
        let inv_ray = apply(shape.transf.inverse, ray)
        let (a, b, c) = (norm2(inv_ray.dir), dot(inv_ray.origin.Vec3f, inv_ray.dir), norm2(inv_ray.origin.Vec3f) - 1.0)
        let delta_4 = b * b - a * c
        if delta_4 <= 0: return false

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        (inv_ray.tmin < t_l and t_l < inv_ray.tmax) or (inv_ray.tmin < t_r and t_r < inv_ray.tmax) 

    elif S is Plane:
        let inv_ray = apply(shape.transf.inverse, ray)
        if abs(inv_ray.dir[2]) < epsilon(float32): return false

        let t = -inv_ray.origin.z / inv_ray.dir[2]
        if t < inv_ray.tmin or t > inv_ray.tmax: false
        else: true


type
    HitRecord* = object
        ray*: Ray
        t_hit*: float32
        world_pt*: Point3D
        surface_pt*: Point2D
        normal*: Normal

proc rayIntersection*[S: Shape](shape: S, ray: Ray): Option[HitRecord] =
    let inv_ray = apply(shape.transf.inverse, ray)
    var t_hit: float32

    when S is AABox:
        let 
            aabb = shape.aabb.get
            (min, max) = (aabb.min - inv_ray.origin, aabb.max - inv_ray.origin)

        var
            (tx_min, tx_max) = (min.x / inv_ray.dir[0], max.x / inv_ray.dir[0])
            (ty_min, ty_max) = (min.y / inv_ray.dir[1], max.y / inv_ray.dir[1])

        if tx_min > tx_max: swap(tx_min, tx_max)
        if ty_min > ty_max: swap(ty_min, ty_max)
    
        if tx_min > ty_max or ty_min > tx_max: return none(HitRecord)

        var (tz_min, tz_max) = (min.z / inv_ray.dir[2], max.z / inv_ray.dir[2])
        if tz_min > tz_max: swap(tz_min, tz_max)

        var (t_hit_min, t_hit_max) = (max(ty_min, tx_min), min(ty_max, tx_max))
        if t_hit_min > tz_max or tz_min > t_hit_max: return none(HitRecord)
        
        (t_hit_min, t_hit_max) = (max(t_hit_min, tz_min), min(t_hit_max, tz_max))

        proc `<=`(a, b: Point3D): bool {.inline.} = a.x <= b.x and a.y <= b.y and a.z <= b.z
        t_hit = (if inv_ray.origin <= aabb.max and aabb.min <= inv_ray.origin: t_hit_max else: t_hit_min)
        
        if (t_hit < inv_ray.tmin) or (t_hit > inv_ray.tmax): return none(HitRecord)

    elif S is Sphere:
        let (a, b, c) = (norm2(inv_ray.dir), dot(inv_ray.origin.Vec3f, inv_ray.dir), norm2(inv_ray.origin.Vec3f) - 1)
        let delta_4 = b * b - a * c
        if delta_4 < 0: return none(HitRecord)

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        if t_l > inv_ray.tmin and t_l < inv_ray.tmax: t_hit = t_l
        elif t_r > inv_ray.tmin and t_r < inv_ray.tmax: t_hit = t_r
        else: return none(HitRecord)

    elif S is Plane:
        if abs(inv_ray.dir[2]) < epsilon(float32): return none(HitRecord)
        t_hit = -inv_ray.origin.z / inv_ray.dir[2]
        if t_hit < inv_ray.tmin or t_hit > inv_ray.tmax: return none(HitRecord)


    let
        hit_pt = inv_ray.at(t_hit)
        normal = shape.normal(hit_pt, inv_ray.dir) 
    
    some(HitRecord(ray: ray, t_hit: t_hit, world_pt: apply(shape.transf, hit_pt), surface_pt: shape.uv(hit_pt), normal: apply(shape.transf, normal).normalize))


type 
    Mesh = object of Shape
        nodes: seq[Point3D]
        edges: seq[tuple[first, second: int]]

proc newMesh(nodes: seq[Point3D], edges: seq[tuple[first, second: int]]): Mesh {.inline.} = Mesh(nodes: nodes, edges: edges)
