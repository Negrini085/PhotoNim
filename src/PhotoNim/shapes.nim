import common, transformations, camera, geometry

type HitRecord* = object
    world_point*: Point3D
    normal*: Normal
    uv*: Vec2f
    t*: float32
    ray*: Ray


proc newHitRecord*(hit_point: Point3D, norm: Normal, uv: Vec2f, t: float32, ray: Ray): HitRecord {.inline.} =
    ## Procedure to create a new HitRecord object
    result.world_point = hit_point; result.normal = norm; result.uv = uv; result.t = t; result.ray = ray;

