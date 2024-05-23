import geometry, camera

import std/options
from std/fenv import epsilon
from std/math import sgn, floor, arccos, arctan2, PI, sqrt

type
    AABB* = tuple[min, max: Point3D]

    ShapeKind* = enum
        skAABox, skTriangle, skSphere, skPlane, skTriangularMesh, skCSGUnion, skCSGDiff, skCSGInt
    Shape* = object of RootObj
        transf*: Transformation
        aabb*: Option[AABB] = none(AABB)

        case kind*: ShapeKind 
        of skAABox: 
            min*, max*: Point3D

        of skTriangle: 
            vertices*: tuple[A, B, C: Point3D]

        of skTriangularMesh:
            nodes*: seq[Point3D]
            triang*: seq[Vec3[int32]]

        of skSphere:
            center*: Point3D
            radius*: float32

        of skPlane: discard

        of skCSGUnion, skCSGDiff, skCSGInt:
            shapes*: seq[Shape]


    World* = object
        shapes*: seq[Shape]


proc newWorld*(): World {.inline.} = World(shapes: @[])


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

proc newMesh*(nodes: seq[Point3D], triang: seq[Vec3[int32]], transf = Transformation.id): Shape {.inline.} = 
    Shape(
        kind: skTriangularMesh,
        transf: transf,
        aabb: some((min(nodes), max(nodes))),
        nodes: nodes,
        triang: triang
    )

proc newCSGUnion*(shapes: seq[Shape] = @[], transf = Transformation.id): Shape {.inline.} = 
    Shape(
        kind: skCSGUnion,
        shapes: shapes, 
        transf: transf
    )

proc newCSGDiff*(shapes: seq[Shape] = @[], transf = Transformation.id): Shape {.inline.} = 
    Shape(
        kind: skCSGDiff,
        shapes: shapes, 
        transf: transf
    )

proc newCSGInt*(shapes: seq[Shape] = @[], transf = Transformation.id): Shape {.inline.} = 
    Shape(
        kind: skCSGInt,
        shapes: shapes, 
        transf: transf
    )



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
            (x_ptA, x_BA, x_CA) = ((pt.x - shape.vertices.A.x), (shape.vertices.B.x - shape.vertices.A.x), (shape.vertices.C.x - shape.vertices.A.x))
            (y_ptA, y_BA, y_CA) = ((pt.y - shape.vertices.A.y), (shape.vertices.B.y - shape.vertices.A.y), (shape.vertices.C.y - shape.vertices.A.y))
            (u_num, u_den) = (x_ptA * y_CA - y_ptA * x_CA, xBA * y_CA - y_BA * x_CA)
            (v_num, v_den) = (x_ptA * y_BA - y_ptA * xBA, x_CA * y_BA - y_CA * xBA)
        return newPoint2D(u_num / u_den, v_num / v_den)

    of skTriangularMesh: discard
        
    of skSphere:
        var u = arctan2(pt.y, pt.x) / (2 * PI)
        if u < 0.0: u += 1.0
        return newPoint2D(u, arccos(pt.z) / PI)

    of skPlane: 
        return newPoint2D(pt.x - floor(pt.x), pt.y - floor(pt.y))

    of skCSGUnion: discard
    of skCSGDiff: discard
    of skCSGInt: discard



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
        
    of skTriangularMesh: discard

    of skSphere: 
        return sgn(-dot(pt.Vec3f, dir)).float32 * newNormal(pt.x, pt.y, pt.z)

    of skPlane: 
        return newNormal(0, 0, sgn(-dir[2]).float32)

    of skCSGUnion: discard
    of skCSGDiff: discard
    of skCSGInt: discard



proc in_shape*(shape: Shape; pt: Point3D): bool = 
    case shape.kind
    of skAABox:
        if (shape.min.x <= pt.x) and (pt.x <= shape.max.x) and 
        (shape.min.y <= pt.y) and (pt.y <= shape.max.y) and
        (shape.min.z <= pt.z) and (pt.z <= shape.max.z):
            return true
        return false 

    of skTriangle: discard
    of skTriangularMesh: discard

    of skSphere: 
        if (pow(pt.x - shape.center.x, 2) + pow(pt.y - shape.center.y, 2) + pow(pt.z - shape.center.z, 2)) <= pow(shape.radius, 2):
            return true
        return false

    of skPlane: discard

    of skCSGUnion: discard
    of skCSGDiff: discard
    of skCSGInt: discard



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
        return if t < inv_ray.tmin or t > inv_ray.tmax: false else: true
    
    of skCSGUnion:  
        if shape.shapes.len == 0: return false

        let inv_ray = apply(shape.transf.inverse, ray)

        for i in shape.shapes:
            if fastIntersection(i, inv_ray):
                return true
        
        return false

    of skCSGDiff: discard
    of skCSGInt: discard



type
    HitRecord* = object
        ray*: Ray
        t_hit*: float32
        world_pt*: Point3D
        surface_pt*: Point2D
        normal*: Normal


#------------------------------------------------#
#            Procedure to get all hits           #
#------------------------------------------------#
proc allRayIntersections*(shape: Shape, ray: Ray): Option[seq[HitRecord]] =

    let inv_ray = apply(shape.transf.inverse, ray)

    case shape.kind

    of skTriangle: discard
    of skTriangularMesh: discard            
    of skAABox: discard

    of skSphere:
        let (a, b, c) = (norm2(inv_ray.dir), dot(inv_ray.origin.Vec3f, inv_ray.dir), norm2(inv_ray.origin.Vec3f) - 1)
        let delta_4 = b * b - a * c
        if delta_4 < 0: return none(seq[HitRecord])

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        if t_l > ray.tmin and t_l < ray.tmax and t_r > ray.tmin and t_r < ray.tmax: 
            return some(@[ 
                HitRecord(ray: ray, t_hit: t_l, surface_pt: shape.uv(inv_ray.at(t_l)), world_pt: apply(shape.transf, inv_ray.at(t_l)), normal: apply(shape.transf, shape.normal(inv_ray.at(t_l), inv_ray.dir))),
                HitRecord(ray: ray, t_hit: t_r, surface_pt: shape.uv(inv_ray.at(t_r)), world_pt: apply(shape.transf, inv_ray.at(t_r)), normal: apply(shape.transf, shape.normal(inv_ray.at(t_r), inv_ray.dir)))
                ])
        elif t_l > ray.tmin and t_l < ray.tmax:
            return some(@[
                HitRecord(ray: ray, t_hit: t_l, surface_pt: shape.uv(inv_ray.at(t_l)), world_pt: apply(shape.transf, inv_ray.at(t_l)), normal: apply(shape.transf, shape.normal(inv_ray.at(t_l), inv_ray.dir)))
                ])
        elif t_r > ray.tmin and t_r < ray.tmax:
            return some(@[
                HitRecord(ray: ray, t_hit: t_l, surface_pt: shape.uv(inv_ray.at(t_l)), world_pt: apply(shape.transf, inv_ray.at(t_l)), normal: apply(shape.transf, shape.normal(inv_ray.at(t_l), inv_ray.dir)))
                ])
        else: return none(seq[HitRecord])

    of skPlane: discard
    of skCSGUnion: discard
    of skCSGDiff: discard       
    of skCSGInt: discard


#------------------------------------------------#
#           Procedure to get closer hit          #
#------------------------------------------------#
proc rayIntersection*(shape: Shape, ray: Ray): Option[HitRecord] =
    var 
        t_hit: float32
        hit_pt: Point3D
        surf_pt: Point2D
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
        surf_pt = newPoint2D(u, v)
        normal = shape.normal(hit_pt, ray.dir)

        return some(HitRecord(ray: ray, t_hit: t_hit, world_pt: hit_pt, surface_pt: surf_pt, normal: normal))

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

    of skCSGUnion:
        if shape.shapes.len == 0: return none(HitRecord)

        var 
            tmin: float32
            appo: HitRecord
            hits: seq[HitRecord]

        # I feel like you could be doing it without using hits sequence
        for i in shape.shapes:
            if fastIntersection(i, inv_ray):
                hits.add(rayIntersection(i, inv_ray).get)
        
        if hits.len == 0: return none(HitRecord)

        #Choosing closer hit
        tmin = hits[0].t_hit
        appo = hits[0]

        for i in hits:
            if i.t_hit < tmin:
                tmin = i.t_hit
                appo = i
        
        discard hits
        return some(appo)

    of skCSGDiff: 
        if shape.shapes.len == 0: return none(HitRecord)

        var
            tmin, tmax: float32
            appo: HitRecord
            hits: Option[seq[HitRecord]]
            cand, in_hit: seq[HitRecord]

        # Checking if there is intersection with first shape
        if fastIntersection(shape.shapes[0], inv_ray):
            for i in shape.shapes:
                if fastIntersection(i, inv_ray):
                    
                    # Computing all ray intersections with i-th shape
                    hits = allRayIntersections(i, ray)
                    if hits.isSome:
                        for i in hits.get:
                            # Checking which point are in first shape
                            if in_shape(shape.shapes[0], i.world_pt):
                                in_hit.add(i)

                        if in_hit.len != 0:

                            #Checking which candidate is good
                            tmin = in_hit[0].t_hit
                            appo = in_hit[0]

                            #Checking which is first
                            for i in in_hit:
                                if i.t_hit < tmin:
                                    tmin = i.t_hit
                                    appo = i
                            
                            in_hit = @[]
                            hits = none(seq[Hitrecord])

                            # Adding new HitRecord candidate
                            cand.add(appo)
            
            if cand.len != 0:
                tmax = cand[0].t_hit
                appo = cand[0]

                for i in cand:
                    if i.t_hit > tmax:
                        tmax = i.t_hit
                        appo = i
                
                return some(appo)
            
        return none(HitRecord)



    of skCSGInt: discard

    hit_pt = inv_ray.at(t_hit)
    surf_pt = shape.uv(hit_pt)
    normal = shape.normal(hit_pt, ray.dir)

    some(HitRecord(ray: ray, t_hit: t_hit, surface_pt: surf_pt, world_pt: apply(shape.transf, hit_pt), normal: apply(shape.transf, normal)))