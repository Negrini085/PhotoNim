type
    Color* = object
        r*, g*, b*: float32

proc newColor*(r, g, b: float32 = 0.0): Color =
    ##Constructor

    result.r = r
    result.g = g
    result.b = b

