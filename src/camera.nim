from std/strformat import fmt
from std/fenv import epsilon 
from std/math import sum, pow, exp, log10, floor, arccos, degToRad, PI
from std/sequtils import apply, map

import geometry


type Color* {.borrow: `.`.} = distinct Vec3f

proc newColor*(r, g, b: float32): Color {.inline.} = Color([r, g, b])

const 
    WHITE* = newColor(1, 1, 1)
    BLACK* = newColor(0, 0, 0) 

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


proc clamp(x: float32): float32 {.inline.} = x / (1.0 + x)

proc toneMapping*(img: var HdrImage; alpha, gamma, avLum: float32) = 
    let lum = if avLum == 0.0: img.averageLuminosity else: avLum
    img.pixels.apply(proc(pix: Color): Color = pix * (alpha / lum))
    img.pixels.apply(proc(pix: Color): Color = newColor(clamp(pix.r), clamp(pix.g), clamp(pix.b)))


type Ray* = object
    origin*: Point3D
    dir*: Vec3f
    tmin*: float32
    tmax*: float32
    depth*: int

proc newRay*(origin: Point3D, direction: Vec3f): Ray {.inline} = 
    Ray(origin: origin, dir: direction, tmin: epsilon(float32), tmax: Inf, depth: 0) 

proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline} = 
    areClose(a.origin, b.origin, eps) and areClose(a.dir, b.dir, eps)

proc at*(ray: Ray; time: float32): Point3D {.inline.} = ray.origin + ray.dir * time

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

proc newOrthogonalCamera*(a: float32, transf = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckOrthogonal, transf: transf, aspect_ratio: a)

proc newPerspectiveCamera*(a, d: float32, transf = Transformation.id): Camera {.inline.} = 
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

proc fire_ray*(im_tr: ImageTracer; x, y: int, pixel = newPoint2D(0.5, 0.5)): Ray {.inline.} =
    im_tr.camera.fire_ray(newPoint2D((x.float32 + pixel.u) / im_tr.image.width.float32, 1 - (y.float32 + pixel.v) / im_tr.image.height.float32))

proc fire_all_rays*(im_tr: var ImageTracer) = 
    echo "hello there"
    for x in 0..<im_tr.image.height:
        for y in 0..<im_tr.image.width:
            # discard im_tr.fire_ray(x, y)
            let 
                r = (1 - exp(-float32(x + y)))
                g = y / im_tr.image.height
                b = pow((1 - x / im_tr.image.width), 2.5)
            im_tr.image.setPixel(x, y, newColor(r, g, b))


type
    PigmentKind* = enum
        pkUniform, pkTexture, pkCheckered

    Pigment* = object of RootObj
        case kind*: PigmentKind
        of pkUniform: 
            color*: Color

        of pkTexture: 
            texture*: HdrImage

        of pkCheckered:
            color1*: Color
            color2*: Color
            nsteps*: int

proc newUniformPigment*(color: Color): Pigment {.inline.} = Pigment(kind: pkUniform, color: color)
proc newTexturePigment*(texture: HdrImage): Pigment {.inline.} = Pigment(kind: pkTexture, texture: texture)
proc newCheckeredPigment*(color1, color2: Color, nsteps: int): Pigment {.inline.} = 
    Pigment(kind: pkCheckered, color1: color1, color2: color2, nsteps: nsteps)

proc getColor*(pigment: Pigment; uv: Point2D): Color =
    case pigment.kind: 
    of pkUniform: 
        return pigment.color

    of pkTexture: 
        var (col, row) = (floor(uv.u * pigment.texture.width.float32).int, floor(uv.v * pigment.texture.height.float32).int)
        if col >= pigment.texture.width: col = pigment.texture.width - 1
        if row >= pigment.texture.height: row = pigment.texture.height - 1

        return pigment.texture.getPixel(col, row)

    of pkCheckered:
        let (col, row) = (floor(uv.u * pigment.nsteps.float32).int, floor(uv.v * pigment.nsteps.float32).int)
        return (if (col mod 2) == (row mod 2): pigment.color1 else: pigment.color2)


type 
    BRDFKind* = enum 
        DiffuseBRDF, SpecularBRDF

    BRDF* = object of RootObj
        pigment*: Pigment

        case kind*: BRDFKind
        of DiffuseBRDF:
            reflectance*: float32
        of SpecularBRDF:
            threshold_angle: float32


proc newDiffuseBRDF*(pigment = newUniformPigment(WHITE), reflectance = 1.0): BRDF {.inline.} =
    BRDF(kind: DiffuseBRDF, pigment: pigment, reflectance: reflectance)

proc newSpecularBRDF*(pigment = newUniformPigment(WHITE), angle = 180.0): BRDF {.inline.} =
    BRDF(kind: SpecularBRDF, pigment: pigment, threshold_angle: (0.1 * degToRad(angle)).float32) 


proc eval*(brdf: BRDF; normal: Normal, in_dir, out_dir: Vec3f, uv: Point2D): Color {.inline.} =
    case brdf.kind: 
    of DiffuseBRDF: 
        return brdf.pigment.getColor(uv) * (brdf.reflectance / PI)

    of SpecularBRDF: 
        return 
            if abs(arccos(dot(normal.Vec3f, in_dir)) - arccos(dot(normal.Vec3f, out_dir))) < brdf.threshold_angle: brdf.pigment.getColor(uv)
            else: newColor(0.0, 0.0, 0.0)


type Material* = object
    brdf*: BRDF
    radiance*: Pigment

proc newMaterial*(brdf = newDiffuseBRDF(), pigment = newUniformPigment(BLACK)): Material {.inline.} = Material(brdf: brdf, radiance: pigment) 