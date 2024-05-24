import geometry, shapes, camera

import std/options
from std/math import sqrt
from std/fenv import epsilon


type
    HitRecord* = object
        ray*: Ray
        t*: float32
        shape*: ShapeKind
        material*: Material

        world_pt*: Point3D
        surface_pt*: Point2D
        normal*: Normal


#---------------------------------------------------------#
#      allHitTimes --> procedure to get all hit times     #
#---------------------------------------------------------#
proc allHitTimes*(shape: Shape, ray: Ray): Option[seq[float32]] =
    var t_hit: float32
    let inv_ray = ray.transform(shape.transf.inverse)

    case shape.kind
    of skTriangle: discard

    of skTriangularMesh: discard            

    of skAABox: discard

    of skSphere:
        let (a, b, c) = (norm2(inv_ray.dir), dot(inv_ray.origin.Vec3f, inv_ray.dir), norm2(inv_ray.origin.Vec3f) - 1)
        let delta_4 = b * b - a * c
        if delta_4 < 0: return none(seq[float32])

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        if t_l > ray.tmin and t_l < ray.tmax and t_r > ray.tmin and t_r < ray.tmax: 
            return some(@[t_l, t_r])
        elif t_l > ray.tmin and t_l < ray.tmax:
            return some(@[t_l])
        elif t_r > ray.tmin and t_r < ray.tmax:
            return some(@[t_r])
        return none(seq[float32])

    of skPlane:
        if abs(inv_ray.dir[2]) < epsilon(float32): return none(seq[float32])
        t_hit = -inv_ray.origin.z / inv_ray.dir[2]
        if t_hit < ray.tmin or t_hit > ray.tmax: return none(seq[float32])

        return some(@[t_hit, Inf])



#--------------------------------------------------------------------------------------#
#      fastIntersection -->  procedure to check wether there is intersection or not    #
#--------------------------------------------------------------------------------------#
proc fastIntersection*(shape: Shape, ray: Ray): bool =
    case shape.kind
    of skAABox:
        let 
            (min, max) = (shape.min - ray.origin, shape.max - ray.origin)
            (tx_min, tx_max) = (min.x / ray.dir[0], max.x / ray.dir[0])
            (ty_min, ty_max) = (min.y / ray.dir[1], max.y / ray.dir[1])
    
        if tx_min > ty_max or ty_min > tx_max: return false

        let
            t_hit_min = max(ty_min, tx_min)
            t_hit_max = min(ty_max, tx_max)
            (tz_min, tz_max) = (min.z / ray.dir[2], max.z / ray.dir[2])
            
        return if t_hit_min > tz_max or tz_min > t_hit_max: false else: true

    of skTriangularMesh: discard
    
    of skTriangle: 
        let 
            (A, B, C) = shape.vertices
            mat = [
                [B.x - A.x, C.x - A.x, -ray.dir[0]], 
                [B.y - A.y, C.y - A.y, -ray.dir[1]], 
                [B.z - A.z, C.z - A.z, -ray.dir[2]]
            ]
            vec = [ray.origin.x - A.x, ray.origin.y - A.y, ray.origin.z - A.z]
        
        var solution: Vec3f
        try:
            solution = solve(mat, vec)
        except ValueError:
            return false

        var t_hit = solution[2]
        if ray.tmin > t_hit or t_hit > ray.tmax: return false

        let (u, v) = (solution[0], solution[1])
        if u < 0.0 or v < 0.0 or u + v > 1.0: return false

        return true

    of skSphere: 
        let 
            inv_ray = ray.transform(shape.transf.inverse)
            (a, b, c) = (norm2(inv_ray.dir), dot(inv_ray.origin.Vec3f, inv_ray.dir), norm2(inv_ray.origin.Vec3f) - 1.0)
            delta_4 = b * b - a * c

        if delta_4 < 0: return false

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        return (inv_ray.tmin < t_l and t_l < inv_ray.tmax) or (inv_ray.tmin < t_r and t_r < inv_ray.tmax) 

    of skPlane:
        let inv_ray = ray.transform(shape.transf.inverse)
        if abs(inv_ray.dir[2]) < epsilon(float32): return false

        let t = -inv_ray.origin.z / inv_ray.dir[2]
        return (if t < inv_ray.tmin or t > inv_ray.tmax: false else: true)



#--------------------------------------------------------------------------------------#
#      fastIntersection -->  procedure to check wether there is intersection or not    #
#                            with all shapes of world                                  #
#--------------------------------------------------------------------------------------#
proc fastIntersection*(world: World, ray: Ray): bool =
    # Procedure to check fast intersection with all shapes making a world
    for i in world.shapes:
        if fastIntersection(i, ray): return true

    return false 



#--------------------------------------------------------------------#
#     rayIntersection --> procedure to get closest hit to observer   #
#--------------------------------------------------------------------#
proc rayIntersection*(shape: Shape, ray: Ray): Option[HitRecord] =
    var 
        t_hit: float32
        hit_pt: Point3D
        normal: Normal

    let inv_ray = ray.transform(shape.transf.inverse)

    case shape.kind
    of skTriangle:
        let 
            (A, B, C) = shape.vertices
            mat = [
                [B.x - A.x, C.x - A.x, -ray.dir[0]], 
                [B.y - A.y, C.y - A.y, -ray.dir[1]], 
                [B.z - A.z, C.z - A.z, -ray.dir[2]]
            ]
            vec = [ray.origin.x - A.x, ray.origin.y - A.y, ray.origin.z - A.z]
        
        var solution: Vec3f
        try:
            solution = solve(mat, vec)
        except ValueError:
            return none(HitRecord)

        t_hit = solution[2]
        if ray.tmin > t_hit or t_hit > ray.tmax: return none(HitRecord)

        let (u, v) = (solution[0], solution[1])
        if u < 0.0 or v < 0.0 or u + v > 1.0: return none(HitRecord)

        hit_pt = ray.at(t_hit)
        return some(
            HitRecord(
                ray: ray, 
                t: t_hit, 
                shape: shape.kind,
                material: shape.material,
                world_pt: hit_pt, 
                surface_pt: newPoint2D(u, v), 
                normal: shape.normal(hit_pt, ray.dir)
            )
        )

    of skTriangularMesh: discard            

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
        if t_l > ray.tmin and t_l < ray.tmax: t_hit = t_l
        elif t_r > ray.tmin and t_r < ray.tmax: t_hit = t_r
        else: return none(HitRecord)

    of skPlane:
        if abs(inv_ray.dir[2]) < epsilon(float32): return none(HitRecord)
        t_hit = -inv_ray.origin.z / inv_ray.dir[2]
        if t_hit < ray.tmin or t_hit > ray.tmax: return none(HitRecord)
    
    hit_pt = inv_ray.at(t_hit)

    some(
        HitRecord(
            ray: ray,
            t: t_hit,
            shape: shape.kind,
            material: shape.material,
            world_pt: apply(shape.transf, hit_pt),
            surface_pt: shape.uv(hit_pt),
            normal: apply(shape.transf, shape.normal(hit_pt, ray.dir))
        )
    )



#------------------------------------------------------------------------------------#
#     rayIntersection --> procedure to get closest hit to observer in world shapes   #
#------------------------------------------------------------------------------------#
proc rayIntersection*(world: World, ray: Ray): Option[HitRecord] =
    var 
        appo: Option[HitRecord]
        hit: Option[HitRecord] = none(HitRecord)

    for i in world.shapes:
        appo = rayIntersection(i, ray)

        if appo.isNone:
            continue

        if hit.isNone or (appo.get.t < hit.get.t):
            hit = appo
        
    return hit


