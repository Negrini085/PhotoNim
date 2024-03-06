type
    Color* = object
        r*, g*, b*: float32

## Constructor
proc newColor*(r, g, b: float32): Color = Color(r: r, g: g, b: b)