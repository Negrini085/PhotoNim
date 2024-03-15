import common

type 
    Color* = object
        ## `Color` represents a color in RGB format.
        r*, g*, b*: float32

proc newColor*(r, g, b: float32): Color {.inline.} = Color(r: r, g: g, b: b) ## \
    ## Create a new RGB `Color`.
    
    
proc areClose*(x, y: Color): bool {.inline.} = areClose(x.r, y.r) and areClose(x.g, y.g) and areClose(x.b, y.b) ## \
    ## Check if two `Color`s are the same up to numerical precision using `areClose`.


proc `+`*(col1: Color, col2: Color): Color =
    ## Sum of two RGB `Color`s.
    result.r = col1.r + col2.r
    result.g = col1.g + col2.g
    result.b = col1.b + col2.b


proc `*`*(col: Color, scal: float32): Color = 
    ## Multiply a `Color` by a scalar.
    result.r = col.r * scal
    result.g = col.g * scal
    result.b = col.b * scal

proc `*`*(scal: float32, col: Color): Color {.inline.} = col * scal ## \
    ## Multiply a scalar by a `Color`.


proc `*`*(col1, col2: Color): Color = 
    ## Multiply two RGB `Color`s element wise
    result.r = col1.r * col2.r
    result.g = col1.g * col2.g
    result.b = col1.b * col2.b


const 
    Black* = newColor(0, 0, 0)
    White* = newColor(255, 255, 255)