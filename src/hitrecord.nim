import geometry, shapes, bvh, camera

import std/options
from std/math import sqrt, arctan2, PI
from std/fenv import epsilon


type
    HitRecord* = object
        ray*: Ray
        t*: float32
        shape*: ShapeKind # mainly for debug
        material*: Material

        world_pt*: Point3D
        surface_pt*: Point2D
        normal*: Normal


proc allHitTimes*(shape: Shape, ray: Ray): Option[seq[float32]] =
    let inv_ray = if shape.transform.kind != tkIdentity: ray.transform(shape.transform.inverse) else: ray

    case shape.kind
    of skTriangle: discard

    of skAABox: discard

    of skSphere:
        let (a, b, c) = (norm2(inv_ray.dir), dot(inv_ray.origin.Vec3f, inv_ray.dir), norm2(inv_ray.origin.Vec3f) - 1)
        let delta_4 = b * b - a * c
        if delta_4 < 0: return none(seq[float32])

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        if t_l > ray.tspan.min and t_l < ray.tspan.max and t_r > ray.tspan.min and t_r < ray.tspan.max: return some(@[t_l, t_r])
        elif t_l > ray.tspan.min and t_l < ray.tspan.max: return some(@[t_l])
        elif t_r > ray.tspan.min and t_r < ray.tspan.max: return some(@[t_r])
        
        return none(seq[float32])

    of skPlane:
        if abs(inv_ray.dir[2]) < epsilon(float32): return none(seq[float32])
        let t_hit = -inv_ray.origin.z / inv_ray.dir[2]
        if t_hit < ray.tspan.min or t_hit > ray.tspan.max: return none(seq[float32])

        return some(@[t_hit, Inf])

    of skCylinder: discard


proc fastIntersection*(shape: Shape, ray: Ray): bool =
    case shape.kind
    of skAABox:
        let inv_ray = ray.transform(shape.transform.inverse)
        let (min, max) = (shape.aabb.min - inv_ray.origin, shape.aabb.max - inv_ray.origin)
        let
            txspan = newInterval(min.x / inv_ray.dir[0], max.x / inv_ray.dir[0])
            tyspan = newInterval(min.y / inv_ray.dir[1], max.y / inv_ray.dir[1])

        if txspan.min > tyspan.max or tyspan.min > txspan.max: return false

        let tzspan = newInterval(min.z / inv_ray.dir[2], max.z / inv_ray.dir[2])
        
        var hitspan = newInterval(max(txspan.min, tyspan.min), min(txspan.max, tyspan.max))
        if hitspan.min > tzspan.max or tzspan.min > hitspan.max: return false

        return true

    of skTriangle: 
        let 
            inv_ray = ray.transform(shape.transform.inverse)
            mat = [
                [shape.vertices[1].x - shape.vertices[0].x, shape.vertices[2].x - shape.vertices[0].x, -inv_ray.dir[0]], 
                [shape.vertices[1].y - shape.vertices[0].y, shape.vertices[2].y - shape.vertices[0].y, -inv_ray.dir[1]], 
                [shape.vertices[1].z - shape.vertices[0].z, shape.vertices[2].z - shape.vertices[0].z, -inv_ray.dir[2]]
            ]
            vec = [inv_ray.origin.x - shape.vertices[0].x, inv_ray.origin.y - shape.vertices[0].y, inv_ray.origin.z - shape.vertices[0].z]
        
        var solution: Vec3f
        try: solution = solve(mat, vec) except ValueError: return false

        let t_hit = solution[2]
        if not inv_ray.tspan.contains(t_hit): return false

        let (u, v) = (solution[0], solution[1])
        if u < 0.0 or v < 0.0 or u + v > 1.0: return false

        return true

    of skSphere: 
        let 
            inv_ray = ray.transform(shape.transform.inverse)
            (a, b, c) = (norm2(inv_ray.dir), dot(inv_ray.origin.Vec3f, inv_ray.dir), norm2(inv_ray.origin.Vec3f) - shape.radius * shape.radius)
            delta_4 = b * b - a * c

        if delta_4 < 0: return false

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        return inv_ray.tspan.contains(t_l) or inv_ray.tspan.contains(t_r)

    of skPlane:
        let inv_ray = ray.transform(shape.transform.inverse)
        if abs(inv_ray.dir[2]) < epsilon(float32): return false
        if inv_ray.tspan.contains(-inv_ray.origin.z / inv_ray.dir[2]): return true
                    
    of skCylinder: 
        let
            inv_ray = ray.transform(shape.transform.inverse)
            a = inv_ray.dir[0] * inv_ray.dir[0] + inv_ray.dir[1] * inv_ray.dir[1]
            b = 2 * (inv_ray.dir[0] * inv_ray.origin.x + inv_ray.dir[1] * inv_ray.origin.y)
            c = inv_ray.origin.x * inv_ray.origin.x + inv_ray.origin.y * inv_ray.origin.y - shape.R * shape.R
            delta = b * b - 4.0 * a * c

        if delta < 0.0: return false

        var tspan = newInterval((-b - sqrt(delta)) / (2 * a), (-b + sqrt(delta)) / (2 * a))

        if tspan.min > inv_ray.tspan.max or tspan.max < inv_ray.tspan.min: return false

        var t_hit = tspan.min
        if t_hit < inv_ray.tspan.min:
            if tspan.max > inv_ray.tspan.max: return false
            t_hit = tspan.max

        var hit_pt = inv_ray.at(t_hit)
        var phi = arctan2(hit_pt.y, hit_pt.x)
        if phi < 0.0: phi += 2.0 * PI

        if hit_pt.z < shape.zMin or hit_pt.z > shape.zMax or phi > shape.phiMax:
            if t_hit == tspan.max: return false
            t_hit = tspan.max
            if t_hit > inv_ray.tspan.max: return false
            
            hit_pt = inv_ray.at(t_hit)
            phi = arctan2(hit_pt.y, hit_pt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hit_pt.z < shape.zMin or hit_pt.z > shape.zMax or phi > shape.phiMax: return false

        return true
    
    
proc rayIntersection*(shape: Shape, ray: Ray): Option[HitRecord] =
    var 
        t_hit: float32
        hit_pt: Point3D
        normal: Normal

    let inv_ray = ray.transform(shape.transform.inverse) 

    case shape.kind
    of skAABox:
        let (min, max) = (shape.aabb.min - inv_ray.origin, shape.aabb.max - inv_ray.origin)
        let
            txspan = newInterval(min.x / inv_ray.dir[0], max.x / inv_ray.dir[0])
            tyspan = newInterval(min.y / inv_ray.dir[1], max.y / inv_ray.dir[1])

        if txspan.min > tyspan.max or tyspan.min > txspan.max: return none HitRecord

        let tzspan = newInterval(min.z / inv_ray.dir[2], max.z / inv_ray.dir[2])
        
        var (t_hit_min, t_hit_max) = (max(txspan.min, tyspan.min), min(txspan.max, tyspan.max))
        if t_hit_min > tzspan.max or tzspan.min > t_hit_max: return none HitRecord

        if tzspan.min > t_hit_min: t_hit_min = tzspan.min
        if tzspan.max < t_hit_max: t_hit_max = tzspan.max
                
        t_hit = (if shape.aabb.contains(inv_ray.origin): t_hit_max else: t_hit_min)
        if not inv_ray.tspan.contains(t_hit): return none HitRecord

    of skTriangle:
        let 
            mat = [
                [shape.vertices[1].x - shape.vertices[0].x, shape.vertices[2].x - shape.vertices[0].x, -inv_ray.dir[0]], 
                [shape.vertices[1].y - shape.vertices[0].y, shape.vertices[2].y - shape.vertices[0].y, -inv_ray.dir[1]], 
                [shape.vertices[1].z - shape.vertices[0].z, shape.vertices[2].z - shape.vertices[0].z, -inv_ray.dir[2]]
            ]
            vec = [inv_ray.origin.x - shape.vertices[0].x, inv_ray.origin.y - shape.vertices[0].y, inv_ray.origin.z - shape.vertices[0].z]

        var solution: Vec3f
        try: solution = solve(mat, vec)
        except ValueError: return none HitRecord

        t_hit = solution[2]
        if not inv_ray.tspan.contains(t_hit): return none HitRecord

        let (u, v) = (solution[0], solution[1])
        if u < 0.0 or v < 0.0 or u + v > 1.0: return none HitRecord

        hit_pt = inv_ray.at(t_hit)
        return some HitRecord(
            ray: ray, 
            t: t_hit, 
            shape: shape.kind,
            material: shape.material,
            world_pt: hit_pt, 
            surface_pt: newPoint2D(u, v), 
            normal: shape.normal(hit_pt, inv_ray.dir)
        )

    of skSphere:
        let (a, b, c) = (norm2(inv_ray.dir), dot(inv_ray.origin.Vec3f, inv_ray.dir), norm2(inv_ray.origin.Vec3f) - shape.radius * shape.radius)
        let delta_4 = b * b - a * c
        if delta_4 < 0: return none HitRecord

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        if ray.tspan.contains(t_l): t_hit = t_l
        elif ray.tspan.contains(t_r): t_hit = t_r
        else: return none HitRecord

    of skPlane:
        if abs(inv_ray.dir[2]) < epsilon(float32): return none HitRecord
        t_hit = -inv_ray.origin.z / inv_ray.dir[2]
        if not ray.tspan.contains(t_hit): return none HitRecord

    of skCylinder:
        if not fastIntersection(shape.getAABox, ray): return none HitRecord

        let
            a = inv_ray.dir[0] * inv_ray.dir[0] + inv_ray.dir[1] * inv_ray.dir[1]
            b = 2 * (inv_ray.dir[0] * inv_ray.origin.x + inv_ray.dir[1] * inv_ray.origin.y)
            c = inv_ray.origin.x * inv_ray.origin.x + inv_ray.origin.y * inv_ray.origin.y - shape.R * shape.R
            delta = b * b - 4.0 * a * c

        if delta < 0.0: return none HitRecord

        var tspan = newInterval((-b - sqrt(delta)) / (2 * a), (-b + sqrt(delta)) / (2 * a))

        if tspan.min > inv_ray.tspan.max or tspan.max < inv_ray.tspan.min: return none HitRecord

        t_hit = tspan.min
        if t_hit < inv_ray.tspan.min:
            if tspan.max > inv_ray.tspan.max: return none HitRecord
            t_hit = tspan.max

        hit_pt = inv_ray.at(t_hit)
        var phi = arctan2(hit_pt.y, hit_pt.x)
        if phi < 0.0: phi += 2.0 * PI

        if hit_pt.z < shape.zMin or hit_pt.z > shape.zMax or phi > shape.phiMax:
            if t_hit == tspan.max: return none HitRecord
            t_hit = tspan.max
            if t_hit > inv_ray.tspan.max: return none HitRecord
            
            hit_pt = inv_ray.at(t_hit)
            phi = arctan2(hit_pt.y, hit_pt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hit_pt.z < shape.zMin or hit_pt.z > shape.zMax or phi > shape.phiMax: return none HitRecord

        return some HitRecord(
            ray: ray,
            t: t_hit, 
            shape: shape.kind,
            material: shape.material,
            world_pt: apply(shape.transform, hit_pt),
            surface_pt: shape.uv(hit_pt), 
            normal: apply(shape.transform, shape.normal(hit_pt, newVec3f(0, 0, 0)))
        )
    

    hit_pt = inv_ray.at(t_hit)

    some HitRecord(
        ray: ray,
        t: t_hit,
        shape: shape.kind,
        material: shape.material,
        world_pt: apply(shape.transform, hit_pt),
        surface_pt: shape.uv(hit_pt),
        normal: apply(shape.transform, shape.normal(hit_pt, ray.dir))
    )


proc fastIntersection*(node: SceneNode, ray: Ray): bool =
    if not fastIntersection(newAABox(node.aabb), ray): return false
    if node.isLeaf:
        for shape in node.shapes:
            if fastIntersection(shape, ray): return true
        return false

    if (node.left != nil and fastIntersection(node.left, ray)) or (node.right != nil and fastIntersection(node.right, ray)): return true