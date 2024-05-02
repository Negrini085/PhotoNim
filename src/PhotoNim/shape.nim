import common, transformations, camera, geometry

type HitRecord* = object
    world_point*: Point3D
    surf_point*: Vec2f
    normal*: Normal
    t*: float32
    ray*: Ray
    

    