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

proc toneMapping*(img: var HdrImage; alpha, gamma, avLum: float32) = 
    let lum = if avLum == 0.0: img.averageLuminosity else: avLum
    img.pixels.apply(proc(pix: Color): Color = pix * (alpha / lum))

    proc clamp(x: float32): float32 {.inline.} = x / (1.0 + x)
    img.pixels.apply(proc(pix: Color): Color = newColor(clamp(pix.r), clamp(pix.g), clamp(pix.b)))


type Ray* = object
    origin*: Point3D
    dir*: Vec3f
    tmin*: float32
    tmax*: float32
    depth*: int

proc newRay*(origin: Point3D, direction: Vec3f): Ray {.inline.} = 
    Ray(origin: origin, dir: direction, tmin: epsilon(float32), tmax: Inf, depth: 0)  

proc at*(ray: Ray; time: float32): Point3D {.inline.} = ray.origin + ray.dir * time

proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline.} = 
    areClose(a.origin, b.origin, eps) and areClose(a.dir, b.dir, eps)

proc transform*(ray: Ray; transf: Transformation): Ray {.inline.} =
    case transf.kind: 
    of tkIdentity: return ray
    of tkTranslation, tkScaling: 
        return Ray(origin: apply(transf, ray.origin), dir: ray.dir, tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)
    of tkGeneric, tkRotation, tkComposition:
        return Ray(origin: apply(transf, ray.origin), dir: apply(transf, ray.dir), tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)


type
    CameraKind* = enum
        ckOrthogonal, ckPerspective

    Camera* = object
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
    var ray: Ray
    case cam.kind
    of ckOrthogonal:
        ray = newRay(newPoint3D(-1, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1), eX)
    of ckPerspective:
        ray = newRay(newPoint3D(-cam.distance, 0, 0), newVec3(cam.distance, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1))

    ray.transform(cam.transf)