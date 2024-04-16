import color

from std/streams import Stream, write, writeLine, readLine, readFloat32
from std/endians import littleEndian32, bigEndian32
from std/strutils import split, parseInt, parseFloat
from std/strformat import fmt
from std/sequtils import apply, map
from std/math import sum, pow, log10
from std/fenv import epsilon


## =================================================
## HdrImage Type
## =================================================

type
    HdrImage* = object
        ## `HdrImage` represents an HDR image as a sequence of `Color` associated with each pixel in (width, height)
        width*, height*: int
        pixels*: seq[Color]


proc newHdrImage*(width, height: int): HdrImage = 
    ## Create a (width, height) `HdrImage` black canvas.
    (result.width, result.height) = (width, height)
    result.pixels = newSeq[Color](width * height)


proc validPixel(img: HdrImage, row, col: int): bool {.inline.} =
    ## Check if pixel coordinates are valid in a `HdrImage`.
    (0 <= row and row < img.width) and (0 <= col and col < img.height)

proc pixelOffset(img: HdrImage, x, y: int): int {.inline.} =
    ## Calculate pixel position in a `HdrImage`.
    x + img.width * y


proc getPixel*(img: HdrImage, row, col: int): Color = 
    ## Access the `Color` of pixel (row, col) in a `HdrImage`.
    assert img.validPixel(row, col), fmt"Error! Index ({row}, {col}) out of bounds for a {img.width}x{img.height} HdrImage"
    img.pixels[img.pixelOffset(row, col)]

proc setPixel*(img: var HdrImage, row, col: int, color: Color) = 
    ## Set the `Color` of pixel (row, col) in a `HdrImage`.
    assert img.validPixel(row, col), fmt"Error! Index ({row}, {col}) out of bounds for a {img.width}x{img.height} HdrImage"
    img.pixels[img.pixelOffset(row, col)] = color


## =================================================
## HdrImage Functions
## =================================================

proc averageLuminosity*(img: HdrImage, eps: float32 = epsilon(float32)): float32 {.inline.} =
    ## Return the HdrImage avarage luminosity
    pow(10, sum(img.pixels.map(proc(pix: Color): float32 = log10(eps + pix.luminosity))) / img.pixels.len.float32)

proc normalizeImage*(img: var HdrImage, scal: float32, lum: bool = true) =
    ## Normalizing pixel values
    var luminosity: float32 = 1.0
    if lum: luminosity = img.averageLuminosity
    img.pixels.apply(proc(pix: Color): Color = pix * (scal / luminosity))


proc clamp(x: float32): float32 {.inline.} = x / (1.0 + x)

proc clampImage*(img: var HdrImage) {.inline.} = 
    img.pixels.apply(proc(pix: Color): Color = newColor(clamp(pix.r), clamp(pix.g), clamp(pix.b)))



## =================================================
## Stream Float
## =================================================

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


## =================================================
## PFM HdrImage Type
## =================================================

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
        let endianFloat = stream.readLine.parseFloat
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