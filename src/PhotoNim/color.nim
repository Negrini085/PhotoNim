import common

type 
    Color* = object
        ## `Color` represents a color in RGB format.
        r*, g*, b*: float32

proc newColor*(r, g, b: float32): Color {.inline.} = 
    ## Create a new RGB `Color`.
    Color(r: r, g: g, b: b)    
    
proc areClose*(x, y: Color): bool {.inline.} = 
    ## Check if two `Color`s are the same up to numerical precision using `areClose`.
    areClose(x.r, y.r) and areClose(x.g, y.g) and areClose(x.b, y.b)

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

proc `/`*(x: Color, y: float32): Color = 
    ## Divide a `Color` by a scalar.
    result.r = x.r / y
    result.g = x.g / y
    result.b = x.b / y


proc `*`*(y: float32, col: Color): Color {.inline.} = col * y ## \
    ## Multiply a scalar by a `Color`.


proc `*=`*(x: var Color, y: float32) = 
    ## Multiply a `Color` by a scalar.
    x.r *= y
    x.g *= y
    x.b *= y

proc `/=`*(x: var Color, y: float32) = 
    ## Divide a `Color` by a scalar.
    x.r /= y
    x.g /= y
    x.b /= y


proc `*`*(x, y: Color): Color = 
    ## Multiply two RGB `Color`s element wise
    result.r = x.r * y.r
    result.g = x.g * y.g
    result.b = x.b * y.b


proc `$`*(col: Color): string {.inline.} = 
    ## Stringify a `Color`
    "<" & $col.r & " " & $col.g & " " & $col.b & ">"

proc luminosity*(col: Color): float32 = 
    ## `Color` luminosity calculator
    (max(col.r, max(col.g, col.b)) + min(col.r, min(col.g, col.b))) / 2