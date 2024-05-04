import geometry
import hdrimage

const eX*: Vec3f = newVec3[float32](1, 0, 0)

#--------------------------------------#
#        Ray type implementation       # 
#--------------------------------------#
type
    Ray* = object
        start*: Point3D
        dir*: Vec3f
        tmin*: float32
        tmax*: float32
        depth*: int

proc newRay*(p0: Point3D, direction: Vec3f): Ray {.inline} = 
    ## Procedure to create a new light ray
    Ray(start: p0, dir: direction, tmin: 1e-5, tmax: Inf, depth: 0)

proc at*(ray: Ray, time: float32): Point3D =
    ## Procedure to determine position at a certain time t
    result = ray.start + ray.dir * time

proc areClose*(ray1, ray2: Ray): bool {.inline} =
    ## Procedure to check wether rays are close or not
    result = areClose(ray1.start, ray2.start) and areClose(ray1.dir, ray2.dir)

proc translateRay*(ray: Ray, vec: Vec3f): Ray =
    ## Procedure to translate a ray: vector defining translation is given
    result = ray; result.start = result.start + vec;

proc transformRay*(T: Transformation, ray: Ray): Ray =
    ## Procedure to translate a ray: translation transformation is given as an input
    result.start = apply(T, ray.start); result.dir = apply(T, ray.dir)
    result.tmin = ray.tmin; result.tmax = ray.tmax; result.depth = ray.depth



#-----------------------------------------#
#        Camera type implementation       #
#-----------------------------------------#

type
    Camera* = object of RootObj
        aspect_ratio*: float32
        T*: Transformation 

method fire_ray*(cam: Camera, u,v: float32): Ray {.base.} =
    ## Base fire ray method



#-----------------------------------------#
#           Orthogonal Camera             #
#-----------------------------------------#

type OrthogonalCamera* = object of Camera

proc newCamera*(a: float32, T = Transformation.id): OrthogonalCamera {.inline.} = 
    ## Orthogonal Camera type constructor
    OrthogonalCamera(aspect_ratio: a, T: T)

method fire_ray*(cam: OrthogonalCamera, u,v: float32): Ray {.inline.} = 
    ## Method to fire a ray with an orthogonal camera
    result = transformRay(cam.T, newRay(newPoint3D(-1, (1 - 2 * u) * cam.aspect_ratio, 2 * v - 1), eX))



#------------------------------------------#
#           Perspective Camera             #
#---------------------------------------.--#

type PerspectiveCamera* = object of Camera
    distance*:float32

proc newCamera*(a, d: float32, T = Transformation.id): PerspectiveCamera {.inline.} = 
    ## Perspective Camera type constructor
    PerspectiveCamera(aspect_ratio: a, distance: d, T: T)

method fire_ray*(cam: PerspectiveCamera, u,v: float32): Ray {.inline.} = 
    ## Method to fire a ray with an perspective camera
    result = transformRay(cam.T, newRay(newPoint3D(-cam.distance, 0, 0), newVec3[float32](cam.distance, (1 - 2*u)*cam.aspect_ratio, 2*v - 1)))





#-------------------------------------#
#         Image Tracere type          #
#-------------------------------------#
type ImageTracer* = object
    image*: HdrImage
    camera*: Camera

proc newImageTracer*(im: HdrImage, cam: Camera): ImageTracer {.inline.} = 
    ## ImageTracer constructor
    ImageTracer(image: im, camera: cam)

proc fire_ray*(im_tr: ImageTracer, col, row: int, u_pixel: float32 = 0.5, v_pixel: float32 = 0.5): Ray =
    ## Procedure to fire a ray to a specific pixel
    var
        u: float32 = (float32(col) + u_pixel)/float32(im_tr.image.width)
        v: float32 = 1 - (float32(row) + v_pixel)/float32(im_tr.image.height)
    
    result = im_tr.camera.fire_ray(u, v)

proc fire_all_rays*(im_tr: var ImageTracer) = 
    ## Procedure to fire all ray needed to create image
    var appo: Ray
    for i in 0..<im_tr.image.height:
        for j in 0..<im_tr.image.width:
            appo = im_tr.fire_ray(i, j)
            im_tr.image.setPixel(i, j, newColor(i*j/(im_tr.image.width * im_tr.image.height), i*j/(im_tr.image.width * im_tr.image.height), i*j/(im_tr.image.width * im_tr.image.height)))
