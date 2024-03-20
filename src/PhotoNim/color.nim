import common

type 
    Color* = object
        ## `Color` represents a color in RGB format.
        r*, g*, b*: float32

proc newColor*(r, g, b: float32): Color {.inline.} = Color(r: r, g: g, b: b) ## \
    ## Create a new RGB `Color`.
    
    
proc areClose*(x, y: Color): bool {.inline.} = areClose(x.r, y.r) and areClose(x.g, y.g) and areClose(x.b, y.b) ## \
    ## Check if two `Color`s are the same up to numerical precision using `areClose`.


proc `+`*(x, y: Color): Color =
    ## Sum of two RGB `Color`s.
    result.r = x.r + y.r
    result.g = x.g + y.g
    result.b = x.b + y.b


proc `*`*(x: Color, y: float32): Color = 
    ## Multiply a `Color` by a scalar.
    result.r = x.r * y
    result.g = x.g * y
    result.b = x.b * y

proc `*`*(y: float32, col: Color): Color {.inline.} = col * y ## \
    ## Multiply a scalar by a `Color`.


proc `*`*(x, y: Color): Color = 
    ## Multiply two RGB `Color`s element wise
    result.r = x.r * y.r
    result.g = x.g * y.g
    result.b = x.b * y.b


proc `$`*(col: Color): string {.inline.} = "<" & $col.r & " " & $col.g & " " & $col.b & ">" ## \
    ## Stringify a `Color`


const 
    Black* = newColor(0, 0, 0)
    White* = newColor(255, 255, 255)