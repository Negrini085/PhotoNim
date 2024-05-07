from std/fenv import epsilon 

import geometry
import hdrimage

const eX*: Vec3f = newVec3[float32](1, 0, 0)

type
    Ray* = object
        start*: Point3D
        dir*: Vec3f
        tmin*: float32
        tmax*: float32
        depth*: int

proc newRay*(p0: Point3D, direction: Vec3f): Ray {.inline} = Ray(start: p0, dir: direction, tmin: 1e-5, tmax: Inf, depth: 0)

proc at*(ray: Ray, time: float32): Point3D {.inline.} = ray.start + ray.dir * time

proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline} = areClose(a.start, b.start, eps) and areClose(a.dir, b.dir, eps)
    

proc translateRay*(ray: Ray, vec: Vec3f): Ray =
    ## Procedure to translate a ray: vector defining translation is given
    result = ray; result.start = result.start + vec;

proc transformRay*(transf: Transformation, ray: Ray): Ray =
    ## Procedure to translate a ray: translation transformation is given as an input
    result.start = apply(transf, ray.start); result.dir = apply(transf, ray.dir)
    result.tmin = ray.tmin; result.tmax = ray.tmax; result.depth = ray.depth



type
    Camera* = object of RootObj
        aspect_ratio*: float32
        transf*: Transformation 

    OrthogonalCamera* = object of Camera
    PerspectiveCamera* = object of Camera
        distance*: float32

proc newCamera*(a: float32, transf = Transformation.id): OrthogonalCamera {.inline.} = OrthogonalCamera(aspect_ratio: a, transf: transf)
proc newCamera*(a, d: float32, transf = Transformation.id): PerspectiveCamera {.inline.} = PerspectiveCamera(aspect_ratio: a, distance: d, transf: transf)


method fire_ray*(cam: Camera, u,v: float32): Ray {.base.} =
    quit "to overload"

method fire_ray*(cam: OrthogonalCamera, u,v: float32): Ray {.inline.} = 
    let origin = newPoint3D(-1, (1 - 2 * u) * cam.aspect_ratio, 2 * v - 1)
    transformRay(cam.transf, newRay(origin, eX))

method fire_ray*(cam: PerspectiveCamera, u,v: float32): Ray {.inline.} = 
    let origin = newPoint3D(-cam.distance, 0, 0)
    let dir = newVec3(cam.distance, (1 - 2 * u) * cam.aspect_ratio, 2 * v - 1)
    transformRay(cam.transf, newRay(origin, dir))



type ImageTracer* = object
    image*: HdrImage
    camera*: Camera

proc newImageTracer*(im: HdrImage, cam: Camera): ImageTracer {.inline.} = ImageTracer(image: im, camera: cam)

proc fire_ray*(im_tr: ImageTracer, col, row: int, u_pixel: float32 = 0.5, v_pixel: float32 = 0.5): Ray =
    ## Procedure to fire a ray to a specific pixel
    var
        u: float32 = (float32(col) + u_pixel)/float32(im_tr.image.width)
        v: float32 = 1 - (float32(row) + v_pixel)/float32(im_tr.image.height)
    
    im_tr.camera.fire_ray(u, v)

proc fire_all_rays*(im_tr: var ImageTracer) = 
    ## Procedure to fire all ray needed to create image
    for i in 0..<im_tr.image.height:
        for j in 0..<im_tr.image.width:
            discard im_tr.fire_ray(i, j)
            let pixColor = i * j / (im_tr.image.width * im_tr.image.height)
            im_tr.image.setPixel(i, j, newColor(pixColor, pixColor, pixColor))
