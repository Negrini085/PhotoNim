import geometry, scene

from std/fenv import epsilon
from std/math import pow, sqrt, arctan2, PI


type Ray* = object
    ## `Ray` is an object that enables us to interact with a `Scene` and its `ObjectHandler`s
    ## in order to extract some information to render the desired `HDRImage` from a specific `Camera`.
    ## 
    ## It is possible to create an instance of `Ray` only in two distinct situations:
    ## - for every pixel of the `HDRImage` a squared number of `Ray`s, determined by the anti-aliasing strategy in use, 
    ##   are "fired" from the `Camera` to the `Scene`.
    ## - when an `ObjectHandler` in `Scene` is hit by a `Ray`, if the `Ray.depth` is lower than some fixed upper bound, 
    ##   then another `Ray` is "scattered" from the intersection point in a random direction based on the `Material` of the hit. 

    origin*: Point3D ## The point from where the ray is fired.
    dir*: Vec3 ## The direction where the ray is pointing.
    depth*: int ## How many rays have been fired before the current.


proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline.} = 
    ## Check wheter two `Ray`s have close origins and directions.
    areClose(a.origin, b.origin, eps) and areClose(a.dir, b.dir, eps)


proc at*(ray: Ray; time: float32): Point3D {.inline.} = 
    ## Get the `Point3D` at a certain distance from the `Ray.origin` in the `Ray.direction`.
    ray.origin + ray.dir * time

proc transform*(ray: Ray; transformation: Transformation): Ray {.inline.} =
    ## Get a new `Ray` by apply some `Transformation` to the current `Ray.origin` and `Ray.dir`.
    
    case transformation.kind: 
    of tkIdentity: ray
    of tkTranslation: Ray(origin: apply(transformation, ray.origin), dir: ray.dir, depth: ray.depth)
    else: Ray(origin: apply(transformation, ray.origin), dir: apply(transformation, ray.dir), depth: ray.depth)


proc getBoxHit*(worldRay: Ray; aabb: AABB): float32 {.inline.} =
    ## Get the distance of the intersection between a `Ray` and `AABB` both created in the global reference system.
    ## If there is not any intersection, then the procudere returns `Inf`.

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
    if result < 1e-5: return Inf


proc getShapeHit*(localInvRay: Ray; shape: Shape): float32 =
    ## Get the distance of the intersection between a `Ray` and `Shape`.  
    ## If there is not any intersection, then the procudere returns `Inf`.
    ## 
    ## Keep in mind that a `Ray` fired in the `Scene` global reference system must be trasformed and inverted into the local reference system of the `Shape`.
    ## Because the distance is an invariant, even if the procedure works in the local reference system of the `Shape`,
    ## the result of it can still be confronted against any results from a global intersection.

    case shape.kind
    of skAABox:
        let
            (min, max) = (shape.aabb.min - localInvRay.origin, shape.aabb.max - localInvRay.origin)
            txSpan = newInterval(min[0] / localInvRay.dir[0], max[0] / localInvRay.dir[0])
            tySpan = newInterval(min[1] / localInvRay.dir[1], max[1] / localInvRay.dir[1])

        if txSpan.min > tySpan.max or tySpan.min > txSpan.max: return Inf

        let tzSpan = newInterval(min[2] / localInvRay.dir[2], max[2] / localInvRay.dir[2])
        
        var hitSpan = newInterval(max(txSpan.min, tySpan.min), min(txSpan.max, tySpan.max))
        if hitSpan.min > tzSpan.max or tzSpan.min > hitSpan.max: return Inf

        if tzSpan.min > hitSpan.min: hitSpan.min = tzSpan.min
        if tzSpan.max < hitSpan.max: hitSpan.max = tzSpan.max

        result = if shape.aabb.contains(localInvRay.origin): hitSpan.max else: hitSpan.min
        if result < 1e-5: return Inf

    of skTriangle:
        let 
            mat = [
                [shape.vertices[1].x - shape.vertices[0].x, shape.vertices[2].x - shape.vertices[0].x, -localInvRay.dir[0]], 
                [shape.vertices[1].y - shape.vertices[0].y, shape.vertices[2].y - shape.vertices[0].y, -localInvRay.dir[1]], 
                [shape.vertices[1].z - shape.vertices[0].z, shape.vertices[2].z - shape.vertices[0].z, -localInvRay.dir[2]]
            ]
            vec = [localInvRay.origin.x - shape.vertices[0].x, localInvRay.origin.y - shape.vertices[0].y, localInvRay.origin.z - shape.vertices[0].z]

        let sol = try: solve(mat, vec) except ValueError: return Inf
        if sol[0] < 0.0 or sol[1] < 0.0 or sol[0] + sol[1] > 1.0 or sol[2] < 1e-5: return Inf
        result = sol[2]

    of skSphere:
        let 
            (a, b, c) = (norm2(localInvRay.dir), dot(localInvRay.origin.Vec3, localInvRay.dir), norm2(localInvRay.origin.Vec3) - shape.radius * shape.radius)
            delta_4 = b * b - a * c
        
        if delta_4 < 0: return Inf
        let (tL, tR) = ((-b - sqrt(delta_4)) / a, (-b + sqrt(delta_4)) / a)
        result = if tL > 1e-5: tL elif tR > 1e-5: tR else: Inf

    of skPlane:
        if abs(localInvRay.dir[2]) < epsilon(float32): return Inf
        result = -localInvRay.origin.z / localInvRay.dir[2]
        if result < 1e-5: return Inf

    of skCylinder:
        let
            a = localInvRay.dir[0] * localInvRay.dir[0] + localInvRay.dir[1] * localInvRay.dir[1]
            b = 2 * (localInvRay.dir[0] * localInvRay.origin.x + localInvRay.dir[1] * localInvRay.origin.y)
            c = localInvRay.origin.x * localInvRay.origin.x + localInvRay.origin.y * localInvRay.origin.y - shape.R * shape.R
            delta = b * b - 4.0 * a * c

        if delta < 0.0: return Inf

        var tspan = newInterval((-b - sqrt(delta)) / (2 * a), (-b + sqrt(delta)) / (2 * a))
        if tspan.min >= Inf or tspan.max < 1e-5: return Inf

        result = tspan.min
        if result < 1e-5:
            if tspan.max >= Inf: return Inf
            result = tspan.max

        var 
            hitPt = localInvRay.at(result)
            phi = arctan2(hitPt.y, hitPt.x)
        if phi < 0.0: phi += 2.0 * PI

        if hitPt.z < shape.zSpan.min or hitPt.z > shape.zSpan.max or phi > shape.phiMax:
            if result == tspan.max: return Inf
            result = tspan.max
            if result >= Inf: return Inf
            
            hitPt = localInvRay.at(result)
            phi = arctan2(hitPt.y, hitPt.x)
            if phi < 0.0: phi += 2.0 * PI
            if hitPt.z < shape.zSpan.min or hitPt.z > shape.zSpan.max or phi > shape.phiMax: return Inf

    of skEllipsoid:
        return localInvRay
            .transform(newScaling(1/shape.axis.a, 1/shape.axis.b, 1/shape.axis.c))
            .getShapeHit(Shape(kind: skSphere, radius: 1))