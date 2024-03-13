import common

#-----------------------------------------------#
#                  Color type                   #
#-----------------------------------------------#  

type 
    Color* = object
        ## `Color` represents a color in RGB format
        r*, g*, b*: float32

proc newColor*(r, g, b: float32): Color {.inline.} = 
    ## Create a new RGB `Color`
    Color(r: r, g: g, b: b)


proc areClose*(x, y: Color): bool {.inline.} = 
    ## Check if two `Color`s are the same up to numerical precision using `areClose`
    areClose(x.r, y.r) and areClose(x.g, y.g) and areClose(x.b, y.b)


proc `+`*(col1: Color, col2: Color): Color =
    ## Sum of two RGB `Color`s
    result.r = col1.r + col2.r
    result.g = col1.g + col2.g
    result.b = col1.b + col2.b


proc `*`*(col: Color, scal: float32): Color = 
    ## Multiply a `Color` by a scalar
    result.r = col.r * scal
    result.g = col.g * scal
    result.b = col.b * scal

proc `*`*(scal: float32, col: Color): Color {.inline.} = col * scal


proc `*`*(col1, col2: Color): Color = 
    ## Multiply two RGB `Color`s element wise
    result.r = col1.r * col2.r
    result.g = col1.g * col2.g
    result.b = col1.b * col2.b


const Black* = newColor(0, 0, 0)
const White* = newColor(255, 255, 255)


#-----------------------------------------------#
#                HdrImage type                  #
#-----------------------------------------------#  

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