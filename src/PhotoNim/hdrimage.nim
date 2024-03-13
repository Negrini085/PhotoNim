import color
import std/[endians, strutils]
import system/exceptions


type
    HdrImage* = object
        ## `HdrImage` represents an HDR image as a sequence of `Color` associated with each pixel in (width, height)
        width*, height*: int
        image*: seq[Color]


proc newHdrImage*(width, height: int, bgColor: Color = Black): HdrImage = 
    ## Create a black (width, height) `HdrImage` canvas
    ## ToDo: 
    ##  - Fill image with bgColor
    result.width = width
    result.height = height
    result.image = newSeq[Color](width * height)


proc valid_coord(img: HdrImage, row, col: int): bool {.inline.} =
    ## Check if pixel coordinates are valid in a `HdrImage`
    (row >= 0) and (row < img.width) and (col >= 0) and (col < img.height)


proc pixel_offset(img: HdrImage, row, col: int): int {.inline.} =
    ## Calculate pixel position in a `HdrImage`
    row * img.width + col


proc get_pixel*(img: HdrImage, row, col: int) : Color = 
    ## Access the `Color` of pixel (row, col) in a `HdrImage`
    assert img.valid_coord(row, col)
    img.image[img.pixel_offset(row, col)]

proc get_pixel*(img: var HdrImage, row, col: int) : var Color = 
    ## Access the `Color` of pixel (row, col) in a `HdrImage`
    assert img.valid_coord(row, col)
    img.image[img.pixel_offset(row, col)]


proc set_pixel*(img: var HdrImage, row, col: int, color: Color) = 
    ## Set the `Color` of pixel (row, col) in a `HdrImage`
    assert img.valid_coord(row, col)
    img.image[img.pixel_offset(row, col)] = color


proc parseImgSize*(line: string): tuple[width, height: int] {.raises: [IOError, ValueError].} =
    let sizes = line.split(" ")
    if sizes.len != 2:
        raise newException(IOError, "Invalid image size specification")

    try:
        result = (sizes[0].parseInt, sizes[1].parseInt)
    except ValueError:
        raise newException(IOError, "Missing image size specification")

    if (result.width < 0) or (result.height < 0):
        raise newException(ValueError, "Invalid image size specification: sizes must be positive")


proc parseEndianness*(line: string): Endianness {.raises: [IOError].} =
    var value: float
    try:
        value = line.parseFloat
    except ValueError:
        raise newException(IOError, "Missing endianness specification")

    if value == 1.0:
        return bigEndian
    elif value == -1.0:
        return littleEndian
    else:
        raise newException(IOError, "Invalid endianness specification")