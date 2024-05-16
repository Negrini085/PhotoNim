from std/strformat import fmt
from std/fenv import epsilon 
from std/math import sum, pow, exp, log10
from std/sequtils import apply, map

import geometry


type Color* {.borrow: `.`.} = distinct Vec3f

proc newColor*(r, g, b: float32): Color {.inline.} = Color([r, g, b])

proc r*(a: Color): float32 {.inline.} = a.Vec3f[0]
proc g*(a: Color): float32 {.inline.} = a.Vec3f[1]
proc b*(a: Color): float32 {.inline.} = a.Vec3f[2]

proc areClose*(a, b: Color; epsilon = epsilon(float32)): bool {.borrow.}

proc `+`*(a, b: Color): Color {.borrow.}
proc `+=`*(a: var Color, b: Color) {.borrow.}
proc `-`*(a, b: Color): Color {.borrow.}
proc `-=`*(a: var Color, b: Color) {.borrow.}

proc `*`*(a: Color, b: float32): Color {.borrow.}
proc `*`*(a: float32, b: Color): Color {.borrow.}
proc `*=`*(a: var Color, b: float32) {.borrow.}
proc `/`*(a: Color, b: float32): Color {.borrow.}
proc `/=`*(a: var Color, b: float32) {.borrow.}

proc luminosity*(a: Color): float32 {.inline.} = 0.5 * (max(a.r, max(a.g, a.b)) + min(a.r, min(a.g, a.b)))


type HdrImage* = object
    width*, height*: int
    pixels*: seq[Color]

proc newHdrImage*(width, height: int): HdrImage = 
    (result.width, result.height) = (width, height)
    result.pixels = newSeq[Color](width * height)

proc validPixel(img: HdrImage; x, y: int): bool {.inline.} = (0 <= y and y < img.height) and (0 <= x and x < img.width)
proc pixelOffset(img: HdrImage; x, y: int): int {.inline.} = x + img.width * y

proc getPixel*(img: HdrImage; x, y: int): Color {.inline.} = 
    assert img.validPixel(x, y), fmt"Error! Index ({x}, {y}) out of bounds for a {img.width}x{img.height} HdrImage"
    img.pixels[img.pixelOffset(x, y)]

proc setPixel*(img: var HdrImage; x, y: int, color: Color) {.inline.} = 
    assert img.validPixel(x, y), fmt"Error! Index ({x}, {y}) out of bounds for a {img.width}x{img.height} HdrImage"
    img.pixels[img.pixelOffset(x, y)] = color

proc averageLuminosity*(img: HdrImage; eps = epsilon(float32)): float32 {.inline.} =
    pow(10, sum(img.pixels.map(proc(pix: Color): float32 = log10(eps + pix.luminosity))) / img.pixels.len.float32)

proc toneMapping*(img: var HdrImage; alpha, gamma: float32) = 
    let lum = img.averageLuminosity
    img.pixels.apply(proc(pix: Color): Color = pix * (alpha / lum))

    proc clamp(x: float32): float32 {.inline.} = x / (1.0 + x)
    img.pixels.apply(proc(pix: Color): Color = newColor(clamp(pix.r), clamp(pix.g), clamp(pix.b)))


type Ray* = object
    origin*: Point3D
    dir*: Vec3f
    tmin*: float32
    tmax*: float32
    depth*: int

proc newRay*(origin: Point3D, direction: Vec3f): Ray {.inline} = Ray(origin: origin, dir: direction, tmin: epsilon(float32), tmax: Inf, depth: 0)  
proc at*(ray: Ray; time: float32): Point3D {.inline.} = ray.origin + ray.dir * time
proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline} = areClose(a.origin, b.origin, eps) and areClose(a.dir, b.dir, eps)

method apply*(transf: Transformation, ray: Ray): Ray {.base, inline.} =
    Ray(origin: apply(transf, ray.origin), dir: apply(transf, ray.dir), tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)

proc translate*(ray: Ray, vec: Vec3f): Ray {.inline.} = 
    Ray(origin: ray.origin + vec, dir: ray.dir, tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)


type
    CameraKind* = enum
        ckOrthogonal, ckPerspective

    Camera* = object of RootObj
        transf*: Transformation
        aspect_ratio*: float32

        case kind: CameraKind
        of ckOrthogonal: discard
        of ckPerspective: 
            distance: float32 

proc newOrthogonalCamera*(a: float32; transf = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckOrthogonal, transf: transf, aspect_ratio: a)

proc newPerspectiveCamera*(a, d: float32; transf = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckPerspective, transf: transf, aspect_ratio: a, distance: d)

proc fire_ray*(cam: Camera; pixel: Point2D): Ray {.inline.} = 
    case cam.kind
    of ckOrthogonal:
        apply(cam.transf, newRay(newPoint3D(-1, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1), eX))
    of ckPerspective:
        apply(cam.transf, newRay(newPoint3D(-cam.distance, 0, 0), newVec3(cam.distance, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1)))

    
type ImageTracer* = object
    image*: HdrImage
    camera*: Camera


proc newImageTracer*(im: HdrImage, cam: Camera): ImageTracer {.inline.} = ImageTracer(image: im, camera: cam)


proc fire_ray*(im_tr: ImageTracer; x, y: int, pixel = newPoint2D(0.5, 0.5)): Ray {.inline.} =
    im_tr.camera.fire_ray(newPoint2D((x.float32 + pixel.u) / im_tr.image.width.float32, 1 - (y.float32 + pixel.v) / im_tr.image.height.float32))

proc fire_all_rays*(im_tr: var ImageTracer) = 
    for x in 0..<im_tr.image.height:
        for y in 0..<im_tr.image.width:
            discard im_tr.fire_ray(x, y)
            let 
                r = (1 - exp(-float32(x + y)))
                g = y / im_tr.image.height
                b = pow((1 - x / im_tr.image.width), 2.5)
            im_tr.image.setPixel(x, y, newColor(r, g, b))
