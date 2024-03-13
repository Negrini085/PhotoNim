import common



#-----------------------------------------------#
#                  Color type                   #
#-----------------------------------------------#  

type 
    Color* = object
        ## A Color in RGB format
        r*, g*, b*: float32

proc newColor*(r, g, b: float32): Color {.inline.} = Color(r: r, g: g, b: b)



proc areClose*(x, y: Color): bool {.inline.} = 
    ## Check if two Color are the same up to numerical precision using areClose
    areClose(x.r, y.r) and areClose(x.g, y.g) and areClose(x.b, y.b)



proc sumCol*(col1: Color, col2: Color): Color =
    ## Sum of two colors 
    result.r = col1.r + col2.r
    result.g = col1.g + col2.g
    result.b = col1.b + col2.b



proc multByScal*(col: Color, scal: float32): Color = 
    ## Multiplication by a scalar
    result.r = col.r * scal
    result.g = col.g * scal
    result.b = col.b * scal



proc multCol*(col1, col2: Color): Color = 
    ## Multiplication of two colors
    result.r = col1.r * col2.r
    result.g = col1.g * col2.g
    result.b = col1.b * col2.b





#-----------------------------------------------#
#                HdrImage type                  #
#-----------------------------------------------#  

type
    HdrImage* = object
        ## An HDR image
        width*, height*: int
        image*: seq[Color]



proc newHdrImage*(width, height: int): HdrImage = 
    ## Contructor which creates a one dimensional array of colors, whose dimension is width * height
    result.width = width
    result.height = height
    
    ## Every pixel is initialized as black (pixel.r = 0.0, pixel.g = 0.0, pixel.b = 0.0)
    for i in 0..<width*height:
        result.image.add(newColor(0.0, 0.0, 0.0))



proc valid_coord*(img: HdrImage, row, col: int): bool =
    ## Checks if given coordinates are valid or not
    return (row >= 0) and (row < img.width) and (col >= 0) and (col < img.height)



proc pixel_offset*(img: HdrImage, row, col: int): int =
    ## Calculate pixel position in HdrImage.image = seq[Color]
    return row*img.width + col



