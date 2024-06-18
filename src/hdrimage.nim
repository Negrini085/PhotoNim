import geometry

from std/math import sum, pow, log10
from std/fenv import epsilon 
from std/sequtils import applyIt, mapIt
from std/strutils import split, parseFloat, parseInt
from std/streams import Stream, FileStream, newFileStream, close, write, writeLine, readLine, readFloat32
from std/endians import littleEndian32, bigEndian32
from nimPNG import savePNG24
from std/strformat import fmt


type 
    Color* {.borrow: `.`.} = distinct Vec3f

    HDRImage* = object
        width*, height*: int
        pixels*: seq[Color]

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


proc newHDRImage*(width, height: int): HDRImage {.inline.} = 
    HDRImage(width: width, height: height, pixels: newSeq[Color](width * height))

proc validPixel(img: HDRImage; x, y: int): bool {.inline.} = (0 <= y and y < img.height) and (0 <= x and x < img.width)
proc pixelOffset*(img: HDRImage; x, y: int): int {.inline.} = x + img.width * y

proc getPixel*(img: HDRImage; x, y: int): Color {.inline.} = 
    assert img.validPixel(x, y), fmt"Error! Index ({x}, {y}) out of bounds for a {img.width}x{img.height} HDRImage"
    img.pixels[img.pixelOffset(x, y)]

proc setPixel*(img: var HDRImage; x, y: int, color: Color) {.inline.} = 
    assert img.validPixel(x, y), fmt"Error! Index ({x}, {y}) out of bounds for a {img.width}x{img.height} HDRImage"
    img.pixels[img.pixelOffset(x, y)] = color

proc avLuminosity*(img: HDRImage; eps = epsilon(float32)): float32 {.inline.} =
    pow(10, sum(img.pixels.mapIt(log10(eps + it.luminosity))) / img.pixels.len.float32)


proc clamp(x: float32): float32 {.inline.} = x / (1.0 + x)
proc clamp(x: Color): Color {.inline.} = newColor(clamp(x.r), clamp(x.g), clamp(x.b))

proc toneMap*(img: HDRImage; alpha, gamma, avLum: float32): HDRImage =
    result = newHDRImage(img.width, img.height) 
    let lum = if avLum == 0.0: img.avLuminosity else: avLum
    result.pixels = img.pixels.mapIt(clamp(it * (alpha / lum)))

proc applyToneMap*(img: var HDRImage; alpha, gamma, avLum: float32) =
    let lum = if avLum == 0.0: img.avLuminosity else: avLum
    img.pixels.applyIt(clamp(it * (alpha / lum)))


proc readFloat(stream: Stream, endianness: Endianness = littleEndian): float32 = 
    ## Reads a float from a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32 = stream.readFloat32
    if endianness == littleEndian: littleEndian32(addr result, addr tmp)
    else: bigEndian32(addr result, addr tmp)

proc writeFloat(stream: Stream, value: float32, endianness: Endianness = littleEndian) = 
    ## Writes a float to a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32
    if endianness == littleEndian: littleEndian32(addr tmp, addr value)
    else: bigEndian32(addr tmp, addr value)
    stream.write(tmp)


proc readPFM*(stream: FileStream): tuple[img: HDRImage, endian: Endianness] {.raises: [CatchableError].} =
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

    result.img = newHDRImage(width, height)

    var r, g, b: float32
    for y in countdown(height - 1, 0):
        for x in 0..<width:
            r = readFloat(stream, result.endian)
            g = readFloat(stream, result.endian)
            b = readFloat(stream, result.endian)
            result.img.setPixel(x, y, newColor(r, g, b))


proc savePFM*(img: HDRImage; pfmOut: string, endian: Endianness = littleEndian) = 
    
    var stream = newFileStream(pfmOut, fmWrite) 
    if stream.isNil: quit ""

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

    stream.close


proc savePNG*(img: HDRImage; pngOut: string, alpha, gamma: float32, avLum: float32 = 0.0) = 
    let 
        toneMappedImg = img.toneMap(alpha, gamma, avLum)
        gFactor = 1 / gamma

    var 
        i: int
        pixelsString = newString(3 * img.pixels.len)
    
    for y in 0..<img.height:
        for x in 0..<img.width:
            let pix = toneMappedImg.getPixel(x, y)
            pixelsString[i] = (255 * pow(pix.r, gFactor)).char; i += 1
            pixelsString[i] = (255 * pow(pix.g, gFactor)).char; i += 1
            pixelsString[i] = (255 * pow(pix.b, gFactor)).char; i += 1

    discard savePNG24(pngOut, pixelsString, img.width, img.height)