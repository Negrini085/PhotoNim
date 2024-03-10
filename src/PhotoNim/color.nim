import common

type
    Color* = object
        ## A Color in RGB format
        r*, g*, b*: float32

proc newColor*(r, g, b: float32): Color {.inline.} = Color(r: r, g: g, b: b)



proc multByScalar*(color: Color, scalar: float32) : Color = 
    ## Multiplication by a scalar
    result.r = color.r * scalar
    result.g = color.g * scalar
    result.b = color.b * scalar

    return result



proc areClose*(x, y: Color): bool {.inline.} = 
    ## Check if two Color are the same up to numerical precision using areClose
    areClose(x.r, y.r) and areClose(x.g, y.g) and areClose(x.b, y.b)