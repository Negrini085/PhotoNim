import geometry, camera

from std/fenv import epsilon
from std/math import sgn, floor, sqrt, arccos, arctan2, PI
from std/sequtils import map

type 
    ShapeKind* = enum
        skAABox, skTriangle, skSphere, skPlane, skCylinder
        
    Shape* = object
        transform*: Transformation # this should be a ref or ptr

        material*: Material

        case kind*: ShapeKind 
        of skAABox: 
            aabb*: Interval[Point3D]

        of skTriangle: 
            vertices*: array[3, Point3D]            

        of skSphere:
            radius*: float32

        of skCylinder:
            R*, zMin*, zMax*, phiMax*: float32

        of skPlane: discard


proc newAABB*(points: openArray[Point3D]): Interval[Point3D] =
    if points.len == 1: return (points[0], points[0])

    let 
        x = points.map(proc(pt: Point3D): float32 = pt.x) 
        y = points.map(proc(pt: Point3D): float32 = pt.y)
        z = points.map(proc(pt: Point3D): float32 = pt.z)

    (newPoint3D(x.min, y.min, z.min), newPoint3D(x.max, y.max, z.max))


proc newAABox*(min = ORIGIN3D, max = newPoint3D(1, 1, 1), material = newMaterial(), transformation = IDENTITY): Shape {.inline.} =
    Shape(kind: skAABox, material: material, aabb: newInterval(min, max), transform: transformation)

proc newAABox*(aabb: Interval[Point3D], material = newMaterial(), transformation = IDENTITY): Shape {.inline.} =
    Shape(kind: skAABox, material: material, aabb: aabb, transform: transformation)

proc getAABox*(shape: Shape): Shape {.inline.} =
    case shape.kind
    of skAABox: return shape
    of skTriangle: 
        return newAABox(newAABB(shape.vertices), transformation = shape.transform)
    of skSphere: 
        return newAABox(newPoint3D(-shape.radius, -shape.radius, -shape.radius), newPoint3D(shape.radius, shape.radius, shape.radius), transformation = shape.transform)
    of skCylinder: 
        return newAABox(newPoint3D(-shape.R, -shape.R, shape.zMin), newPoint3D(shape.R, shape.R, shape.zMax), transformation = shape.transform)
    of skPlane: 
        return newAABox(newPoint3D(-Inf, -Inf, -Inf), newPoint3D(Inf, Inf, 0), transformation = shape.transform)


proc getVertices*(shape: Shape): seq[Point3D] = 
    case shape.kind
    of skTriangle:
        return shape.vertices[0..^1]
    of skAABox:
        return @[
            shape.aabb.min, shape.aabb.max,
            newPoint3D(shape.aabb.min.x, shape.aabb.min.y, shape.aabb.max.z),
            newPoint3D(shape.aabb.min.x, shape.aabb.max.y, shape.aabb.min.z),
            newPoint3D(shape.aabb.min.x, shape.aabb.max.y, shape.aabb.max.z),
            newPoint3D(shape.aabb.max.x, shape.aabb.min.y, shape.aabb.min.z),
            newPoint3D(shape.aabb.max.x, shape.aabb.min.y, shape.aabb.max.z),
            newPoint3D(shape.aabb.max.x, shape.aabb.max.y, shape.aabb.min.z),
        ]
    else: 
        return shape.getAABox.getVertices

proc getTransformedVertices*(shape: Shape): seq[Point3D] {.inline.} = shape.getVertices.map(proc(pt: Point3D): Point3D = apply(shape.transform, pt))
    

proc newSphere*(center: Point3D, radius: float32; material = newMaterial()): Shape {.inline.} =   
    Shape(
        kind: skSphere,
        transform: if center != ORIGIN3D: newTranslation(center.Vec3f) else: IDENTITY,
        material: material,
        radius: radius
    )

proc newUnitarySphere*(center: Point3D; material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skSphere, transform: if center != ORIGIN3D: newTranslation(center.Vec3f) else: IDENTITY, material: material, radius: 1.0)

proc newTriangle*(a, b, c: Point3D; transformation = IDENTITY, material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skTriangle, transform: transformation, material: material, vertices: [a, b, c])

proc newTriangle*(vertices: array[3, Point3D]; transformation = IDENTITY, material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skTriangle, transform: transformation, material: material, vertices: vertices)

proc newPlane*(transformation = IDENTITY, material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skPlane, transform: transformation, material: material)

proc newCylinder*(r: float32 = 1.0, z_min: float32 = 0.0, z_max: float32 = 1.0, phi_max: float32 = 2.0 * PI; 
                    transformation = IDENTITY, material = newMaterial()): Shape {.inline.} =
    Shape(kind: skCylinder, transform: transformation, material: material, R: r, zMin: z_min, zMax: z_max, phiMax: phi_max)


proc getUV*(shape: Shape; pt: Point3D): Point2D = 
    case shape.kind
    of skAABox:
        if pt.x == shape.aabb.min.x: 
            return newPoint2D((pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.x == shape.aabb.max.x: 
            return newPoint2D((pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.y == shape.aabb.min.y: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.y == shape.aabb.max.y: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.z == shape.aabb.min.z: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y))
        elif pt.z == shape.aabb.max.z: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y))
        else:
            return newPoint2D(0, 0)

    of skTriangle:
        let 
            (x_ptA, x_BA, x_CA) = ((pt.x - shape.vertices[0].x), (shape.vertices[1].x - shape.vertices[0].x), (shape.vertices[2].x - shape.vertices[0].x))
            (y_ptA, y_BA, y_CA) = ((pt.y - shape.vertices[0].y), (shape.vertices[1].y - shape.vertices[0].y), (shape.vertices[2].y - shape.vertices[0].y))
            (u_num, u_den) = (x_ptA * y_CA - y_ptA * x_CA, xBA * y_CA - y_BA * x_CA)
            (v_num, v_den) = (x_ptA * y_BA - y_ptA * xBA, x_CA * y_BA - y_CA * xBA)
        return newPoint2D(u_num / u_den, v_num / v_den)
        
    of skSphere:
        var u = arctan2(pt.y, pt.x) / (2 * PI)
        if u < 0.0: u += 1.0
        return newPoint2D(u, arccos(pt.z) / PI)

    of skCylinder:
        var phi = arctan2(pt.y, pt.x)
        if phi < 0.0: phi += 2.0 * PI
        return newPoint2D(phi / shape.phiMax, (pt.z - shape.zMin) / (shape.zMax - shape.zMin))

    of skPlane: 
        return newPoint2D(pt.x - floor(pt.x), pt.y - floor(pt.y))


proc getNormal*(shape: Shape; pt: Point3D, dir: Vec3f): Normal = 
    case shape.kind
    of skAABox:
        if   areClose(pt.x, shape.aabb.min.x, 1e-6) or areClose(pt.x, shape.aabb.max.x, 1e-6): result = newNormal(1, 0, 0)
        elif areClose(pt.y, shape.aabb.min.y, 1e-6) or areClose(pt.y, shape.aabb.max.y, 1e-6): result = newNormal(0, 1, 0)
        elif areClose(pt.z, shape.aabb.min.z, 1e-6) or areClose(pt.z, shape.aabb.max.z, 1e-6): result = newNormal(0, 0, 1)
        else: quit "Something went wrong in calculating the normal for an AABox."
        return sgn(-dot(result.Vec3f, dir)).float32 * result

    of skTriangle:
        let cross = cross((shape.vertices[1] - shape.vertices[0]).Vec3f, (shape.vertices[2] - shape.vertices[0]).Vec3f)
        return sgn(-dot(cross, dir)).float32 * cross.toNormal
        
    of skSphere: 
        return sgn(-dot(pt.Vec3f, dir)).float32 * newNormal(pt.x, pt.y, pt.z)

    of skCylinder:
        return newNormal(pt.x, pt.y, 0.0)

    of skPlane: 
        return newNormal(0, 0, sgn(-dir[2]).float32)


proc intersect*(ray: Ray; shape: Shape): bool =
    case shape.kind
    of skAABox:
        let invRay = ray.transform(shape.transform.inverse)
        let (min, max) = (shape.aabb.min - invRay.origin, shape.aabb.max - invRay.origin)
        let
            txspan = newInterval(min.x / invRay.dir[0], max.x / invRay.dir[0])
            tyspan = newInterval(min.y / invRay.dir[1], max.y / invRay.dir[1])

        if txspan.min > tyspan.max or tyspan.min > txspan.max: return false

        let tzspan = newInterval(min.z / invRay.dir[2], max.z / invRay.dir[2])
        
        var hitspan = newInterval(max(txspan.min, tyspan.min), min(txspan.max, tyspan.max))
        if hitspan.min > tzspan.max or tzspan.min > hitspan.max: return false

        return true

    of skTriangle: 
        let 
            invRay = ray.transform(shape.transform.inverse)
            mat = [
                [shape.vertices[1].x - shape.vertices[0].x, shape.vertices[2].x - shape.vertices[0].x, -invRay.dir[0]], 
                [shape.vertices[1].y - shape.vertices[0].y, shape.vertices[2].y - shape.vertices[0].y, -invRay.dir[1]], 
                [shape.vertices[1].z - shape.vertices[0].z, shape.vertices[2].z - shape.vertices[0].z, -invRay.dir[2]]
            ]
            vec = [invRay.origin.x - shape.vertices[0].x, invRay.origin.y - shape.vertices[0].y, invRay.origin.z - shape.vertices[0].z]
        
        let solution = try: solve(mat, vec) except ValueError: return false

        if not invRay.tspan.contains(solution[2]): return false
        if solution[0] < 0.0 or solution[1] < 0.0 or solution[0] + solution[1] > 1.0: return false

        return true

    of skSphere: 
        let 
            invRay = ray.transform(shape.transform.inverse)
            (a, b, c) = (norm2(invRay.dir), dot(invRay.origin.Vec3f, invRay.dir), norm2(invRay.origin.Vec3f) - shape.radius * shape.radius)
            delta_4 = b * b - a * c

        if delta_4 < 0: return false
        return invRay.tspan.contains((-b - sqrt(delta_4)) / a) or invRay.tspan.contains((-b + sqrt(delta_4)) / a)

    of skPlane:
        let invRay = ray.transform(shape.transform.inverse)
        if abs(invRay.dir[2]) < epsilon(float32): return false
        if invRay.tspan.contains(-invRay.origin.z / invRay.dir[2]): return true
                    
    of skCylinder: 
        let
            invRay = ray.transform(shape.transform.inverse)
            a = invRay.dir[0] * invRay.dir[0] + invRay.dir[1] * invRay.dir[1]
            b = 2 * (invRay.dir[0] * invRay.origin.x + invRay.dir[1] * invRay.origin.y)
            c = invRay.origin.x * invRay.origin.x + invRay.origin.y * invRay.origin.y - shape.R * shape.R
            delta = b * b - 4.0 * a * c

        if delta < 0.0: return false

        var tspan = newInterval((-b - sqrt(delta)) / (2 * a), (-b + sqrt(delta)) / (2 * a))

        if tspan.min > invRay.tspan.max or tspan.max < invRay.tspan.min: return false

        var t_hit = tspan.min
        if t_hit < invRay.tspan.min:
            if tspan.max > invRay.tspan.max: return false
            t_hit = tspan.max

        var hitPt = invRay.at(t_hit)
        var phi = arctan2(hitPt.y, hitPt.x)
        if phi < 0.0: phi += 2.0 * PI

        if hitPt.z < shape.zMin or hitPt.z > shape.zMax or phi > shape.phiMax:
            if t_hit == tspan.max: return false
            t_hit = tspan.max
            if t_hit > invRay.tspan.max: return false
            
            hitPt = invRay.at(t_hit)
            phi = arctan2(hitPt.y, hitPt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hitPt.z < shape.zMin or hitPt.z > shape.zMax or phi > shape.phiMax: return false

        return true