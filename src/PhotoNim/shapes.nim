import common, transformations, camera, geometry


#-------------------------------#
#        Hit Record Type        #
#-------------------------------#
type HitRecord* = object
    world_point*: Point3D
    normal*: Normal
    uv*: Vec2f
    t*: float32
    ray*: Ray


proc newHitRecord*(hit_point: Point3D, norm: Normal, uv: Vec2f, t: float32, ray: Ray): HitRecord {.inline.} =
    ## Procedure to create a new HitRecord object
    result.world_point = hit_point; result.normal = norm; result.uv = uv; result.t = t; result.ray = ray;

proc areClose*(hit1, hit2: HitRecord): bool {.inline.} = 
    ## Procedure to test wether two HitRecord are close or not
    return areClose(hit1.world_point, hit2.world_point) and areClose(hit1.normal, hit2.normal) and areClose(hit1.uv, hit2.uv) and areClose(hit1.t, hit2.t) and areClose(hit1.ray, hit2.ray)



#------------------------------#
#         Shape types          #
#------------------------------#
type Shape* = object of RootObj
    T*: Transformation

method intersectionRay(shape: Shape, ray: Ray): HitRecord {.base} =
    ## Base procedure to compute ray intersection with a generic shape
    quit "to overload"
    

type
    Sphere* = object of Shape
    Plane* = object of Shape

proc newSphere*(T: Transformation): Sphere {.inline.} = 
    ## Sphere object constructor
    result.T = T
