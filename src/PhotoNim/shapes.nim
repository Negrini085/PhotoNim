from std/fenv import epsilon
from std/math import sgn, floor, sqrt, arccos, arctan2, PI
import std/options

import camera, geometry


type
    AABB* = tuple[min, max: Point3D]

    ShapeKind* = enum
        skAABox, skTriangle, skSphere, skPlane

    Shape* = object of RootObj
        transf*: Transformation
        aabb*: Option[AABB] = none(AABB)

        case kind*: ShapeKind 
        of skAABox: 
            min, max: Point3D

        of skTriangle: 
            vertices*: tuple[A, B, C: Point3D]

        of skSphere:
            center*: Point3D
            radius*: float32

        of skPlane: discard


    World* = object
        shapes*: seq[Shape]


proc newWorld*(): World {.inline.} = World(shapes: @[])

proc fire_all_rays*(tracer: var ImageTracer; scenary: World, color_map: proc) = 
    for y in 0..<tracer.image.height:
        for x in 0..<tracer.image.width:
            tracer.image.setPixel(x, y, color_map(tracer, tracer.fire_ray(x, y), scenary, x, y))


proc newAABox*(min = newPoint3D(0, 0, 0), max = newPoint3D(1, 1, 1), transf = Transformation.id): Shape {.inline.} =
    Shape(
        kind: skAABox, 
        transf: transf, 
        aabb: some(AABB((min, max))), 
        min: min, max: max
    )

proc newSphere*(center: Point3D, radius: float32): Shape {.inline.} = 
    Shape(
        kind: skSphere,
        transf: newTranslation(center.Vec3f) @ newScaling(radius), 
        center: center, radius: radius
    )

proc newUnitarySphere*(center: Point3D): Shape {.inline.} = 
    Shape(
        kind: skSphere,
        transf: newTranslation(center.Vec3f), 
        center: center, radius: 1.0
    )

proc newTriangle*(a, b, c: Point3D): Shape {.inline.} = 
    Shape(
        kind: skTriangle, 
        transf: Transformation.id,
        vertices: (a, b, c)
    )

proc newPlane*(transf = Transformation.id): Shape {.inline.} = 
    Shape(kind: skPlane, transf: transf)



proc uv*(shape: Shape; pt: Point3D): Point2D = 
    case shape.kind
    of skAABox:
        if   pt.x == 0: return newPoint2D((1 + pt.y) / 4, (1 + pt.z) / 3)
        elif pt.x == 1: return newPoint2D((3 + pt.x) / 4, (1 + pt.z) / 3)
        elif pt.y == 0: return newPoint2D((2 + pt.x) / 4, (1 + pt.z) / 3)
        elif pt.y == 1: return newPoint2D((1 - pt.x) / 4, (1 + pt.z) / 3)
        elif pt.z == 0: return newPoint2D((1 + pt.y) / 4, (1 - pt.x) / 3)
        elif pt.z == 1: return newPoint2D((1 + pt.y) / 4, (2 + pt.x) / 3)   

    of skTriangle:
        let 
            (A, B, C) = shape.vertices
            u_num = (pt.x - A.x)*(C.y - A.y) - (pt.y - A.y)*(C.x - A.x)
            u_den = (B.x - A.x)*(C.y - A.y) - (B.y - A.y)*(C.x - A.x)
            u = u_num / u_den
            v_num = (pt.x - A.x)*(B.y - A.y) - (pt.y - A.y)*(B.x - A.x)
            v_den = (C.x - A.x)*(B.y - A.y) - (C.y - A.y)*(B.x - A.x)
            v = v_num / v_den
        return newPoint2D(u, v)
        
    of skSphere:
        var u = arctan2(pt.y, pt.x) / (2 * PI)
        if u < 0.0: u += 1.0
        return newPoint2D(u, arccos(pt.z) / PI)

    of skPlane: 
        return newPoint2D(pt.x - floor(pt.x), pt.y - floor(pt.y))


proc normal*(shape: Shape; pt: Point3D, dir: Vec3f): Normal = 
    case shape.kind
    of skAABox:
        let aabb = shape.aabb.get
        if   pt.x == aabb.min.x or pt.x == aabb.max.x: result = newNormal(1, 0, 0)
        elif pt.y == aabb.min.y or pt.y == aabb.max.y: result = newNormal(0, 1, 0)
        elif pt.z == aabb.min.z or pt.z == aabb.max.z: result = newNormal(0, 0, 1)
        else: quit "Something went wrong in calculating the normal for an AABox."
        return sgn(-dot(result.Vec3f, dir)).float32 * result

    of skTriangle:
        let 
            (A, B, C) = shape.vertices
            cross = cross((B - A).Vec3f, (C - A).Vec3f)
        return sgn(-dot(cross, dir)).float32 * cross.toNormal
        
    of skSphere: 
        return sgn(-dot(pt.Vec3f, dir)).float32 * newNormal(pt.x, pt.y, pt.z)

    of skPlane: 
        return newNormal(0, 0, sgn(-dir[2]).float32)


proc fastIntersection*(shape: Shape, ray: Ray): bool =
    case shape.kind
    of skAABox:
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

    of skSphere: 
        let 
            inv_ray = apply(shape.transf.inverse, ray)
            (a, b, c) = (norm2(inv_ray.dir), dot(inv_ray.origin.Vec3f, inv_ray.dir), norm2(inv_ray.origin.Vec3f) - 1.0)
            delta_4 = b * b - a * c

        if delta_4 < 0: return false

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        (inv_ray.tmin < t_l and t_l < inv_ray.tmax) or (inv_ray.tmin < t_r and t_r < inv_ray.tmax) 

    of skPlane:
        let inv_ray = apply(shape.transf.inverse, ray)
        if abs(inv_ray.dir[2]) < epsilon(float32): return false

        let t = -inv_ray.origin.z / inv_ray.dir[2]
        if t < inv_ray.tmin or t > inv_ray.tmax: false
        else: true

    of skTriangle:
        false


type
    HitRecord* = object
        ray*: Ray
        t_hit*: float32
        world_pt*: Point3D
        surface_pt*: Point2D
        normal*: Normal

proc rayIntersection*(shape: Shape, ray: Ray): Option[HitRecord] =
    let inv_ray = apply(shape.transf.inverse, ray)
    var t_hit: float32

    case shape.kind
    of skTriangle:
        discard
        # let 
        #     (A, B, C) = triangle.vertices
        #     min = [ray.origin.x - A.x, ray.origin.y - A.y, ray.origin.z - A.z]
        #     max = [
        #         [B.x-A.x, C.x-A.x, -ray.dir[0]], 
        #         [B.y-A.y, C.y-A.y, -ray.dir[1]], 
        #         [B.z-A.z, C.z-A.z, -ray.dir[2]]
        #     ]
            
        #     w = solve(min.T, max.T)

        # t_hit = w[2])

        # if ray.tmin > t_hit or t_hit > ray.tmax: return none(HitRecord)
        # if u < 0.0 or v < 0.0 or u > 1 or v > 1: return none(HitRecord)

        # let
        #     surf_pt = newPoint(w[0], w[1])
        #     hit_pt = ray.at(t_hit)
        # return some(HitRecord(ray: ray, t_hit: t_hit, world_pt: hit_pt, surface_pt: newPoint2D(u, v), normal: triangle.normal(hit_pt, ray.dir)))


    of skAABox:
        let 
            (min, max) = (shape.min - inv_ray.origin, shape.max - inv_ray.origin)
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
        t_hit = (if inv_ray.origin <= shape.max and shape.min <= inv_ray.origin: t_hit_max else: t_hit_min)
        
        if (t_hit < inv_ray.tmin) or (t_hit > inv_ray.tmax): return none(HitRecord)

    of skSphere:
        let (a, b, c) = (norm2(inv_ray.dir), dot(inv_ray.origin.Vec3f, inv_ray.dir), norm2(inv_ray.origin.Vec3f) - 1)
        let delta_4 = b * b - a * c
        if delta_4 < 0: return none(HitRecord)

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        if t_l > inv_ray.tmin and t_l < inv_ray.tmax: t_hit = t_l
        elif t_r > inv_ray.tmin and t_r < inv_ray.tmax: t_hit = t_r
        else: return none(HitRecord)

    of skPlane:
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
