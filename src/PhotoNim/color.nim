import common

type
    Color* = object
        ## A Color in RGB format
        r*, g*, b*: float32

proc newColor*(r, g, b: float32): Color {.inline.} = Color(r: r, g: g, b: b)



proc areClose*(x, y: Color): bool {.inline.} = 
    ## Check if two Color are the same up to numerical precision using areClose
    areClose(x.r, y.r) and areClose(x.g, y.g) and areClose(x.b, y.b)



proc multByScal*(color: Color, scalar: float32) : Color = 
    ## Multiplication by a scalar
    result.r = color.r * scalar
    result.g = color.g * scalar
    result.b = color.b * scalar

    return result



proc multCol*(col1, col2: Color) : Color = 
    ## Multiplication of two colors
    result.r = col1.r * col2.r
    result.g = col1.g * col2.g
    result.b = col1.b * col2.b
