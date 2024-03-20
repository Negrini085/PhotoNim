import common, color
import std/[endians, strutils, streams, math]
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


proc parseFloat*(stream: Stream, endianness: Endianness = littleEndian): float32 = 
    ## Reads a float from a stream accordingly to the given endianness (default is littleEndian)
    var appo: float32 = stream.readFloat32

    if endianness == bigEndian: 
        bigEndian32(addr result, addr appo)
    else: 
        littleEndian32(addr result, addr appo)


proc writeFloat*(stream: Stream, value: float32, endianness: Endianness = littleEndian) = 
    ## Writes a float according to endianness
    # endianness has littleEndian as default value because is more common
    var appo: float32

    if endianness == bigEndian:
        bigEndian32(addr appo, addr value)
    else:
        littleEndian32(addr appo, addr value)
    
    stream.write(appo)


proc parseEndian*(stream: Stream): Endianness = 
    ## Checks whether PFM file uses littleEndian or BigEndian

    var appo: float32

    try:
        appo = parseFloat(stream.readLine)
    except ValueError:
        raise newException(CatchableError, "Missing endianness specification: required bigEndian ('1.0\n') or littleEndian ('-1.0\n')")

    if areClose(appo, float32(1.0)):
        result = bigEndian
    elif appo == -1.0:
        result = littleEndian
    else:
        raise newException(CatchableError, "Invalid endianness value: the only possible values are '1.0' or '-1.0'")


proc parseDim*(stream: Stream): array[2, uint] = 
    ## Reads dimension of PFM image from PFM file
    
    var appo = stream.readLine().split(" ")
    
    try:
        result[0] = parseUInt(appo[0])
        result[1] = parseUInt(appo[1])

    except ValueError:
        echo "Error! Problems regarding type conversion"


proc parsePFM*(stream: Stream): HdrImage {.raises: [CatchableError].} =
    var
        dim: array[2, uint]
        endianness: Endianness

    if stream.readLine != "PM":
        raise newException(CatchableError, "Invalid PFM magic specification: required 'PM\n'")

    try:
        dim = stream.parseDim()
    except:
        raise newException(CatchableError, "Invalid image size specification: required 'width height\n' as unsigned integers")
    
    endianness = stream.parseEndian()
    result = newHdrImage(dim[0], dim[1])

    var r, g, b: float32
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
            writeFloat(stream, color.r, endianness)
            writeFloat(stream, color.g, endianness)
            writeFloat(stream, color.b, endianness)


proc averageLuminosity*(img: HdrImage, delta: float32 = 1e-10): float32 =
    ## Procedure to determine HdrImage avarage luminosity
    var sum: float32 = 0

    #Evaluating exponent
    for i in img.pixels:
        sum += log(delta + i.luminosity, 10)
    sum /= float32(img.width*img.height)

    result = pow(10, sum)