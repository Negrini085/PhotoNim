from std/strformat import fmt
from std/strutils import split, parseInt, parseFloat
from std/streams import Stream, write, writeLine, readLine, readFloat32
from std/endians import littleEndian32, bigEndian32

from std/sequtils import apply, map
from std/math import sum, pow, log10
from std/fenv import epsilon

import geometry


type
    Color* {.borrow: `.`.} = distinct Vec3f

proc newColor*(r, g, b: float32): Color {.inline.} = Color([r, g, b])

proc r*(a: Color): float32 {.inline.} = a.Vec3f[0]
proc g*(a: Color): float32 {.inline.} = a.Vec3f[1]
proc b*(a: Color): float32 {.inline.} = a.Vec3f[2]

proc toVec*(a: Color): Vec3f {.inline.} = newVec3(a.r, a.g, a.b)

proc `$`*(a: Color): string {.inline.} = "<" & $a.r & " " & $a.g & " " & $a.b & ">"


proc `==`*(a, b: Color): bool {.borrow.}
proc areClose*(a, b: Color; epsilon: float32 = epsilon(float32)): bool {.borrow.}

proc `+`*(a, b: Color): Color {.borrow.}
proc `+=`*(a: var Color, b: Color) {.borrow.}

proc `-`*(a, b: Color): Color {.borrow.}
proc `-=`*(a: var Color, b: Color) {.borrow.}

proc `*`*(a: Color, b: float32): Color {.borrow.}
proc `*`*(a: float32, b: Color): Color {.borrow.}
proc `*=`*(a: var Color, b: float32) {.borrow.}

proc `/`*(a: Color, b: float32): Color {.borrow.}
proc `/=`*(a: var Color, b: float32) {.borrow.}



type
    HdrImage* = object
        ## `HdrImage` represents an HDR image as a sequence of `Color` associated with each pixel in (width, height)
        width*, height*: int
        pixels*: seq[Color]


proc newHdrImage*(width, height: int): HdrImage = 
    ## Create a (width, height) `HdrImage` black canvas.
    (result.width, result.height) = (width, height)
    result.pixels = newSeq[Color](width * height)


proc validPixel(img: HdrImage, x, y: int): bool {.inline.} =
    ## Check if pixel coordinates are valid in a `HdrImage`.
    (0 <= y and y < img.height) and (0 <= x and x < img.width)

proc pixelOffset(img: HdrImage, x, y: int): int {.inline.} =
    ## Calculate pixel position in a `HdrImage`.
    img.width * y + x


proc getPixel*(img: HdrImage, x, y: int): Color = 
    ## Access the `Color` of pixel (x, y) in a `HdrImage`.
    assert img.validPixel(x, y), fmt"Error! Index ({x}, {y}) out of bounds for a {img.width}x{img.height} HdrImage"
    img.pixels[img.pixelOffset(x, y)]

proc setPixel*(img: var HdrImage, x, y: int, color: Color) = 
    ## Set the `Color` of pixel (x, y) in a `HdrImage`.
    assert img.validPixel(x, y), fmt"Error! Index ({x}, {y}) out of bounds for a {img.width}x{img.height} HdrImage"
    img.pixels[img.pixelOffset(x, y)] = color


proc luminosity*(a: Color): float32 {.inline.} = 
    ## Return the color luminosity
    0.5 * (max(a.r, max(a.g, a.b)) + min(a.r, min(a.g, a.b)))

proc averageLuminosity*(img: HdrImage, eps: float32 = epsilon(float32)): float32 {.inline.} =
    ## Return the HdrImage avarage luminosity
    pow(10, sum(img.pixels.map(proc(pix: Color): float32 = log10(eps + pix.luminosity))) / img.pixels.len.float32)

proc normalizeImage*(img: var HdrImage, alpha: float32) =
    ## Normalizing pixel values
    let lum = img.averageLuminosity
    img.pixels.apply(proc(pix: Color): Color = pix * (alpha / lum))


proc clamp(x: float32): float32 {.inline.} = x / (1.0 + x)

proc clampImage*(img: var HdrImage) {.inline.} = 
    img.pixels.apply(proc(pix: Color): Color = newColor(clamp(pix.r), clamp(pix.g), clamp(pix.b)))



proc parseFloat*(stream: Stream, endianness: Endianness = littleEndian): float32 = 
    ## Reads a float from a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32 = stream.readFloat32
    if endianness == littleEndian: littleEndian32(addr result, addr tmp)
    else: bigEndian32(addr result, addr tmp)

proc writeFloat*(stream: Stream, value: float32, endianness: Endianness = littleEndian) = 
    ## Writes a float to a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32
    if endianness == littleEndian: littleEndian32(addr tmp, addr value)
    else: bigEndian32(addr tmp, addr value)
    stream.write(tmp)


proc readPFM*(stream: Stream): tuple[img: HdrImage, endian: Endianness] {.raises: [CatchableError].} =
    assert stream.readLine == "PF", "Invalid PFM magic specification: required 'PF'"
    let sizes = stream.readLine.split(" ")
    assert sizes.len == 2, "Invalid image size specification: required 'width height'."

    var width, height: int
    try:
        width = parseInt(sizes[0])
        height = parseInt(sizes[1])
    except:
        raise newException(CatchableError, "Invalid image size specification: required 'width height' as unsigned integers")
    
    try:
        let endianFloat = parseFloat(stream.readLine)
        if endianFloat == 1.0:
            result.endian = bigEndian
        elif endianFloat == -1.0:
            result.endian = littleEndian
        else:
            raise newException(CatchableError, "")
    except:
        raise newException(CatchableError, "Invalid endianness specification: required bigEndian ('1.0') or littleEndian ('-1.0')")

    result.img = newHdrImage(width, height)

    var r, g, b: float32
    for y in countdown(height - 1, 0):
        for x in 0..<width:
            r = parseFloat(stream, result.endian)
            g = parseFloat(stream, result.endian)
            b = parseFloat(stream, result.endian)
            result.img.setPixel(x, y, newColor(r, g, b))


proc writePFM*(stream: Stream, img: HdrImage, endian: Endianness = littleEndian) = 
    stream.writeLine("PF")
    stream.writeLine(img.width, " ", img.height)
    stream.writeLine(if endian == littleEndian: -1.0 else: 1.0)

    var c: Color
    for y in countdown(img.height - 1, 0):
        for x in 0..<img.width:
            c = img.getPixel(x, y)
            stream.writeFloat(c.r, endian)
            stream.writeFloat(c.g, endian)
            stream.writeFloat(c.b, endian)