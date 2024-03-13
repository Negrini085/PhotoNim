import color

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