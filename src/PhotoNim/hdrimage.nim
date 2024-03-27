import common
import std/[endians, strutils, sequtils, streams, math, fenv]
import nimPNG

## =================================================
## Color Type
## =================================================

type
    Color* {.borrow: `.`.} = distinct Vec3f

proc newColor*(r, g, b: float32): Color {.inline.} = 
    result.data = [r, g, b]

proc r*(a: Color): float32 {.inline.} = a.data[0]
proc g*(a: Color): float32 {.inline.} = a.data[1]
proc b*(a: Color): float32 {.inline.} = a.data[2]

proc toVec*(a: Color): Vec3f {.inline.} = newVec(a.r, a.g, a.b)

proc `$`*(a: Color): string {.inline.} = "<" & $a.r & " " & $a.g & " " & $a.b & ">"


## =================================================
## Color Borrowed Operators from Vec3f
## =================================================

proc `==`*(a, b: Color): bool {.borrow.}
proc `!=`*(a, b: Color): bool {.borrow.}
proc areClose*(a, b: Color): bool {.borrow.}

proc `+`*(a, b: Color): Color {.borrow.}
proc `+=`*(a: var Color, b: Color) {.borrow.}

proc `-`*(a, b: Color): Color {.borrow.}
proc `-=`*(a: var Color, b: Color) {.borrow.}

proc `*`*(a: Color, b: float32): Color {.borrow.}
proc `*`*(a: float32, b: Color): Color {.borrow.}
proc `*=`*(a: var Color, b: float32) {.borrow.}

proc `/`*(a: Color, b: float32): Color {.borrow.}
proc `/=`*(a: var Color, b: float32) {.borrow.}



## =================================================
## HdrImage Type
## =================================================

type
    HdrImage* = object
        ## `HdrImage` represents an HDR image as a sequence of `Color` associated with each pixel in (width, height)
        width*, height*: uint
        pixels*: seq[Color]


proc newHdrImage*(width, height: uint): HdrImage = 
    ## Create a (width, height) `HdrImage` black canvas.
    result.width = width
    result.height = height
    result.pixels = newSeq[Color](width * height)


proc validPixel(img: HdrImage, row, col: uint): bool {.inline.} =
    ## Check if pixel coordinates are valid in a `HdrImage`.
    (row < img.width) and (col < img.height)

proc pixelOffset(img: HdrImage, x, y: uint): uint {.inline.} =
    ## Calculate pixel position in a `HdrImage`.
    x + img.width * y


proc getPixel*(img: HdrImage, row, col: uint): Color = 
    ## Access the `Color` of pixel (row, col) in a `HdrImage`.
    assert img.validPixel(row, col)
    img.pixels[img.pixelOffset(row, col)]

proc setPixel*(img: var HdrImage, row, col: uint, color: Color) = 
    ## Set the `Color` of pixel (row, col) in a `HdrImage`.
    assert img.validPixel(row, col)
    img.pixels[img.pixelOffset(row, col)] = color


## =================================================
## HdrImage Functions
## =================================================

proc luminosity*(a: Color): float32 {.inline.} = 
    (max(a.r, max(a.g, a.b)) + min(a.r, min(a.g, a.b))) / 2

proc averageLuminosity*(img: var HdrImage, eps: float32 = epsilon(float32)): float32 {.inline.} =
    ## Procedure to determine HdrImage avarage luminosity
    pow(10, sum(img.pixels.map(proc(pix: Color): float32 = log10(eps + pix.luminosity))) / img.pixels.len.float32)

proc normalizeImage*(img: var HdrImage, scal: float32, lum: bool = true) =
    ## Normalizing pixel values
    var luminosity: float32 = 4.0
    if lum: luminosity = img.averageLuminosity
    img.pixels.apply(proc(pix: Color): Color = pix * (scal / luminosity))


proc clamp(x: float32): float32 {.inline.} = x / (1.0 + x)

proc clampImage*(img: var HdrImage) {.inline.} = 
    img.pixels.apply(proc(pix: Color): Color = newColor(clamp(pix.r), clamp(pix.g), clamp(pix.b)))



## =================================================
## Stream PFM files
## =================================================

proc parseFloat*(stream: Stream, endianness: Endianness = littleEndian): float32 = 
    ## Reads a float from a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32 = stream.readFloat32

    if endianness == bigEndian: 
        bigEndian32(addr result, addr tmp)
    else: 
        littleEndian32(addr result, addr tmp)

proc writeFloat*(stream: Stream, value: float32, endianness: Endianness = littleEndian) = 
    ## Writes a float to a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32

    if endianness == bigEndian:
        bigEndian32(addr tmp, addr value)
    else:
        littleEndian32(addr tmp, addr value)
    
    stream.write(tmp)


proc readPFM*(stream: Stream): HdrImage {.raises: [CatchableError].} =
    var
        width, height: uint
        endianness: Endianness

    if stream.readLine != "PF":
        raise newException(CatchableError, "Invalid PFM magic specification: required 'PF\n'")

    try:
        let sizes = stream.readLine.split(" ")
        width = parseUInt(sizes[0])
        height = parseUInt(sizes[1])
    except:
        raise newException(CatchableError, "Invalid image size specification: required 'width height\n' as unsigned integers")
    
    try:
        let endianFloat = parseFloat(stream.readLine)
        if endianFloat == 1.0:
            endianness = bigEndian
        elif endianFloat == -1.0:
            endianness = littleEndian
        else:
            raise newException(CatchableError, "")
    except:
        raise newException(CatchableError, "Invalid endianness specification: required bigEndian ('1.0\n') or littleEndian ('-1.0\n')")

    result = newHdrImage(width, height)

    var r, g, b: float32
    for y in countdown(result.height - 1, 0):
        for x in 0..<result.width:
            r = parseFloat(stream, endianness)
            g = parseFloat(stream, endianness)
            b = parseFloat(stream, endianness)
            result.setPixel(x, y, newColor(r, g, b))

proc writePFM*(stream: Stream, img: HdrImage, endianness: Endianness) = 
    stream.writeLine("PF")
    stream.writeLine(img.width, " ", img.height)
    stream.writeLine(if endianness == bigEndian: "1.0" else: "-1.0")

    var c: Color
    for y in countdown(img.height - 1, 0):
        for x in 0..<img.width:
            c = img.getPixel(x, y)
            writeFloat(stream, c.r, endianness)
            writeFloat(stream, c.g, endianness)
            writeFloat(stream, c.b, endianness)