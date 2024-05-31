import geometry

from std/strformat import fmt
from std/fenv import epsilon 
from std/math import sum, pow, log10
from std/sequtils import apply, map


type Color* {.borrow: `.`.} = distinct Vec3f

proc newColor*(r, g, b: float32): Color {.inline.} = Color([r, g, b])

const 
    WHITE* = newColor(1, 1, 1)
    BLACK* = newColor(0, 0, 0)
    RED*   = newColor(1, 0, 0)
    GREEN* = newColor(0, 1, 0)
    BLUE*  = newColor(0, 0, 1)

proc r*(a: Color): float32 {.inline.} = a.Vec3f[0]
proc g*(a: Color): float32 {.inline.} = a.Vec3f[1]
proc b*(a: Color): float32 {.inline.} = a.Vec3f[2]

proc `==`*(a, b: Color): bool {.borrow.}
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

proc `*`*(a: Color, b: Color): Color {.inline.} = newColor(a.r*b.r, a.g*b.g, a.b*b.b)

proc luminosity*(a: Color): float32 {.inline.} = 0.5 * (max(a.r, max(a.g, a.b)) + min(a.r, min(a.g, a.b)))


type 
    PixelMap* = seq[Color]
    HDRImage* = object
        width*, height*: int
        pixels*: PixelMap

proc newPixelMap*(width, height: int): PixelMap {.inline.} = newSeq[Color](width * height)
proc newHDRImage*(width, height: int): HDRImage {.inline.} = 
    HDRImage(width: width, height: height, pixels: newPixelMap(width, height))

proc validPixel(img: HDRImage; x, y: int): bool {.inline.} = (0 <= y and y < img.height) and (0 <= x and x < img.width)
proc pixelOffset*(img: HDRImage; x, y: int): int {.inline.} = x + img.width * y

proc getPixel*(img: HDRImage; x, y: int): Color {.inline.} = 
    assert img.validPixel(x, y), fmt"Error! Index ({x}, {y}) out of bounds for a {img.width}x{img.height} HDRImage"
    img.pixels[img.pixelOffset(x, y)]

proc setPixel*(img: var HDRImage; x, y: int, color: Color) {.inline.} = 
    assert img.validPixel(x, y), fmt"Error! Index ({x}, {y}) out of bounds for a {img.width}x{img.height} HDRImage"
    img.pixels[img.pixelOffset(x, y)] = color

proc avLuminosity*(img: HDRImage; eps = epsilon(float32)): float32 {.inline.} =
    pow(10, sum(img.pixels.map(proc(pix: Color): float32 = log10(eps + pix.luminosity))) / img.pixels.len.float32)


proc clamp(x: float32): float32 {.inline.} = x / (1.0 + x)
proc clamp(x: Color): Color {.inline.} = newColor(clamp(x.r), clamp(x.g), clamp(x.b))

proc toneMap*(img: HDRImage; alpha, gamma, avLum: float32): HDRImage =
    result = newHDRImage(img.width, img.height) 
    let lum = if avLum == 0.0: img.avLuminosity else: avLum
    result.pixels = img.pixels.map(proc(pix: Color): Color = clamp(pix * (alpha / lum)))

proc applyToneMap*(img: var HDRImage; alpha, gamma, avLum: float32) =
    let lum = if avLum == 0.0: img.avLuminosity else: avLum
    img.pixels.apply(proc(pix: Color): Color = clamp(pix * (alpha / lum)))