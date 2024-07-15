import geometry, scene

from std/fenv import epsilon
from std/math import pow, sqrt, arctan2, PI


type Ray* = ref object
    origin*: Point3D
    dir*: Vec3
    tSpan*: Interval[float32]
    depth*: int


proc newRay*(origin: Point3D, direction: Vec3, depth: int = 0): Ray {.inline.} = 
    Ray(origin: origin, dir: direction, tSpan: (float32 1.0, float32 Inf), depth: depth)  

proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline.} = 
    areClose(a.origin, b.origin, eps) and areClose(a.dir, b.dir, eps)


proc at*(ray: Ray; time: float32): Point3D {.inline.} = ray.origin + ray.dir * time

proc transform*(ray: Ray; transformation: Transformation): Ray {.inline.} =
    case transformation.kind: 
    of tkIdentity: ray
    of tkTranslation: 
        Ray(
            origin: apply(transformation, ray.origin), 
            dir: ray.dir, 
            tSpan: ray.tSpan, depth: ray.depth
        )
    else: 
        Ray(
            origin: apply(transformation, ray.origin), 
            dir: apply(transformation, ray.dir), 
            tSpan: ray.tSpan, depth: ray.depth
        )


proc getBoxHit*(worldRay: Ray; aabb: Interval[Point3D]): float32 {.inline.} =
    let
        (min, max) = (aabb.min - worldRay.origin, aabb.max - worldRay.origin)
        txSpan = newInterval(min[0] / worldRay.dir[0], max[0] / worldRay.dir[0])
        tySpan = newInterval(min[1] / worldRay.dir[1], max[1] / worldRay.dir[1])

    if txSpan.min > tySpan.max or tySpan.min > txSpan.max: return Inf

    let tzSpan = newInterval(min[2] / worldRay.dir[2], max[2] / worldRay.dir[2])
    
    var hitSpan = newInterval(max(txSpan.min, tySpan.min), min(txSpan.max, tySpan.max))
    if hitSpan.min > tzSpan.max or tzSpan.min > hitSpan.max: return Inf

    if tzSpan.min > hitSpan.min: hitSpan.min = tzSpan.min
    if tzSpan.max < hitSpan.max: hitSpan.max = tzSpan.max
                
    result = if aabb.contains(worldRay.origin): hitSpan.max else: hitSpan.min
    if not worldRay.tspan.contains(result): return Inf


proc getShapeHit*(worldInvRay: Ray; shape: Shape): float32 =
    case shape.kind
    of skAABox:
        let
            (min, max) = (shape.aabb.min - worldInvRay.origin, shape.aabb.max - worldInvRay.origin)
            txSpan = newInterval(min[0] / worldInvRay.dir[0], max[0] / worldInvRay.dir[0])
            tySpan = newInterval(min[1] / worldInvRay.dir[1], max[1] / worldInvRay.dir[1])

        if txSpan.min > tySpan.max or tySpan.min > txSpan.max: return Inf

        let tzSpan = newInterval(min[2] / worldInvRay.dir[2], max[2] / worldInvRay.dir[2])
        
        var hitSpan = newInterval(max(txSpan.min, tySpan.min), min(txSpan.max, tySpan.max))
        if hitSpan.min > tzSpan.max or tzSpan.min > hitSpan.max: return Inf

        if tzSpan.min > hitSpan.min: hitSpan.min = tzSpan.min
        if tzSpan.max < hitSpan.max: hitSpan.max = tzSpan.max

        result = if shape.aabb.contains(worldInvRay.origin): hitSpan.max else: hitSpan.min
        if not worldInvRay.tspan.contains(result): return Inf

    of skTriangle:
        let 
            mat = [
                [shape.vertices[1].x - shape.vertices[0].x, shape.vertices[2].x - shape.vertices[0].x, -worldInvRay.dir[0]], 
                [shape.vertices[1].y - shape.vertices[0].y, shape.vertices[2].y - shape.vertices[0].y, -worldInvRay.dir[1]], 
                [shape.vertices[1].z - shape.vertices[0].z, shape.vertices[2].z - shape.vertices[0].z, -worldInvRay.dir[2]]
            ]
            vec = [worldInvRay.origin.x - shape.vertices[0].x, worldInvRay.origin.y - shape.vertices[0].y, worldInvRay.origin.z - shape.vertices[0].z]

        let sol = try: solve(mat, vec) except ValueError: return Inf
        if not worldInvRay.tspan.contains(sol[2]): return Inf
        if sol[0] < 0.0 or sol[1] < 0.0 or sol[0] + sol[1] > 1.0: return Inf

        result = sol[2]

    of skSphere:
        let 
            (a, b, c) = (norm2(worldInvRay.dir), dot(worldInvRay.origin.Vec3, worldInvRay.dir), norm2(worldInvRay.origin.Vec3) - shape.radius * shape.radius)
            delta_4 = b * b - a * c
        
        if delta_4 < 0: return Inf

        let (t_l, t_r) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        
        result = 
            if worldInvRay.tspan.contains(t_l): t_l 
            elif worldInvRay.tspan.contains(t_r): t_r 
            else: Inf

    of skPlane:
        if abs(worldInvRay.dir[2]) < epsilon(float32): return Inf
        result = -worldInvRay.origin.z / worldInvRay.dir[2]
        if not worldInvRay.tspan.contains(result): return Inf

    of skCylinder:
        let
            a = worldInvRay.dir[0] * worldInvRay.dir[0] + worldInvRay.dir[1] * worldInvRay.dir[1]
            b = 2 * (worldInvRay.dir[0] * worldInvRay.origin.x + worldInvRay.dir[1] * worldInvRay.origin.y)
            c = worldInvRay.origin.x * worldInvRay.origin.x + worldInvRay.origin.y * worldInvRay.origin.y - shape.R * shape.R
            delta = b * b - 4.0 * a * c

        if delta < 0.0: return Inf

        var tspan = newInterval((-b - sqrt(delta)) / (2 * a), (-b + sqrt(delta)) / (2 * a))
        if tspan.min > worldInvRay.tspan.max or tspan.max < worldInvRay.tspan.min: return Inf

        result = tspan.min
        if result < worldInvRay.tspan.min:
            if tspan.max > worldInvRay.tspan.max: return Inf
            result = tspan.max

        var 
            hitPt = worldInvRay.at(result)
            phi = arctan2(hitPt.y, hitPt.x)
        if phi < 0.0: phi += 2.0 * PI

        if hitPt.z < shape.zSpan.min or hitPt.z > shape.zSpan.max or phi > shape.phiMax:
            if result == tspan.max: return Inf
            result = tspan.max
            if result > worldInvRay.tspan.max: return Inf
            
            hitPt = worldInvRay.at(result)
            phi = arctan2(hitPt.y, hitPt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hitPt.z < shape.zSpan.min or hitPt.z > shape.zSpan.max or phi > shape.phiMax: return Inf