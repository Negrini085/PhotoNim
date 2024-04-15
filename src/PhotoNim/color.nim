import common

## =================================================
## Color Type
## =================================================

type
    Color* {.borrow: `.`.} = distinct Vec3f

proc newColor*(r, g, b: float32): Color {.inline.} = 
    result.data = [r, g, b]

proc r*(a: Color): float32 {.inline.} = a.data[0]
proc g*(a: Color): float32 {.inline.} = a.data[1]
proc b*(a: Color): float32 {.inline.} = a.data[2]

proc toVec*(a: Color): Vec3f {.inline.} = newVec3(a.r, a.g, a.b)

proc `$`*(a: Color): string {.inline.} = "<" & $a.r & " " & $a.g & " " & $a.b & ">"

proc luminosity*(a: Color): float32 {.inline.} = 
    ## Return the color luminosity
    0.5 * (max(a.r, max(a.g, a.b)) + min(a.r, min(a.g, a.b)))


## =================================================
## Color Borrowed Operators from Vec3f
## =================================================

proc `==`*(a, b: Color): bool {.borrow.}
proc areClose*(a, b: Color): bool {.borrow.}

proc `+`*(a, b: Color): Color {.borrow.}
proc `+=`*(a: var Color, b: Color) {.borrow.}

proc `-`*(a, b: Color): Color {.borrow.}
proc `-=`*(a: var Color, b: Color) {.borrow.}

proc `*`*(a: Color, b: float32): Color {.borrow.}
proc `*`*(a: float32, b: Color): Color {.borrow.}
proc `*=`*(a: var Color, b: float32) {.borrow.}

proc `/`*(a: Color, b: float32): Color {.borrow.}
proc `/=`*(a: var Color, b: float32) {.borrow.}