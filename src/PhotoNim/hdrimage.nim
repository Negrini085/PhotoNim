import color
import std/[endians, strutils, streams]
import system/exceptions


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


proc fillHdrImage*(img: var HdrImage, color: Color) =
    ## Fills with a background color
    for i in 0..<img.width * img.height:
        img.pixels[i] = color


proc validPixel(img: HdrImage, row, col: uint): bool {.inline.} =
    ## Check if pixel coordinates are valid in a `HdrImage`.
    (row < img.width) and (col < img.height)


proc pixelOffset(img: HdrImage, row, col: uint): uint {.inline.} =
    ## Calculate pixel position in a `HdrImage`.
    row * img.width + col


proc getPixel*(img: HdrImage, row, col: uint): Color = 
    ## Access the `Color` of pixel (row, col) in a `HdrImage`.
    assert img.validPixel(row, col)
    img.pixels[img.pixelOffset(row, col)]

proc getPixel*(img: var HdrImage, row, col: uint): var Color = 
    ## Access the `Color` of pixel (row, col) in a `HdrImage`.
    assert img.validPixel(row, col)
    img.pixels[img.pixelOffset(row, col)]


proc setPixel*(img: var HdrImage, row, col: uint, color: Color) = 
    ## Set the `Color` of pixel (row, col) in a `HdrImage`.
    assert img.validPixel(row, col)
    img.pixels[img.pixelOffset(row, col)] = color


proc parseFloat(stream: Stream, endianness: Endianness = littleEndian): float32 = 
    ## Reads a float from a stream and stores it according to endianness
    # endianness has littleEndian as default value because is more common

    var appo: float32 = stream.readFloat32

    if endianness == bigEndian:
        bigEndian32(addr result, addr appo)
    
    else:
        littleEndian32(addr result, addr appo)


proc writeFloat(stream: Stream, endianness: Endianness = littleEndian, value: float32): void = 
    ## Writes a float according to endianness
    # endianness has littleEndian as default value because is more common

    var appo: float32

    if endianness == bigEndian:
        bigEndian32(addr appo, addr value)
    
    else:
        littleEndian32(addr appo, addr value)
    
    stream.write(appo)


proc parsePFM*(stream: Stream): HdrImage {.raises: [CatchableError].} =
    var
        width, height: uint
        endianVal: float32
        endianness: Endianness

    if stream.readLine != "PM":
        raise newException(CatchableError, "Invalid PFM magic specification: required 'PM\n'")

    try:
        width = stream.readUint32
        height = stream.readUint32
    except:
        raise newException(CatchableError, "Invalid image size specification: required 'width height\n' as unsigned integers")
    
    try:
        endianVal = stream.readFloat32
    except ValueError:
        raise newException(CatchableError, "Missing endianness specification: required bigEndian ('1.0\n') or littleEndian ('-1.0\n')")

    if endianVal == 1.0:
        endianness = bigEndian
    elif endianVal == -1.0:
        endianness = littleEndian
    else:
        raise newException(CatchableError, "Invalid endianness value: the only possible values are '1.0' or '-1.0'")

    result = newHdrImage(width, height)

    var
        r, g, b: float32
    for y in countdown(result.height - 1, 0):
        for x in 0..<result.width:
            r = parseFloat(stream, endianness)
            g = parseFloat(stream, endianness)
            b = parseFloat(stream, endianness)
            result.setPixel(x, y, newColor(r, g, b))


proc writePFM*(img: HdrImage, stream: Stream, endianness: Endianness) = 
    stream.writeLine("PM\n", img.width, " ", img.height)
    stream.writeLine(if endianness == bigEndian: "1.0" else: "-1.0")

    for y in countdown(img.height - 1, 0):
        for x in 0..<img.width:
            let color = img.getPixel(x, y)
            writeFloat(stream, endianness, color.r)
            writeFloat(stream, endianness, color.g)
            writeFloat(stream, endianness, color.b)