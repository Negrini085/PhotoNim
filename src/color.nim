import geometry

from std/fenv import epsilon 


type Color* {.borrow: `.`.} = distinct Vec3

proc newColor*(r, g, b: float32): Color {.inline.} = Color([r, g, b])

proc r*(a: Color): float32 {.inline.} = a.Vec3[0]
proc g*(a: Color): float32 {.inline.} = a.Vec3[1]
proc b*(a: Color): float32 {.inline.} = a.Vec3[2]

proc `==`*(a, b: Color): bool {.borrow.}
proc areClose*(a, b: Color; epsilon = epsilon(float32)): bool {.borrow.}

proc `+`*(a, b: Color): Color {.borrow.}
proc `+=`*(a: var Color, b: Color) {.borrow.}
proc `-`*(a, b: Color): Color {.borrow.}
proc `-=`*(a: var Color, b: Color) {.borrow.}

proc `*`*(a: Color, b: float32): Color {.borrow.}
proc `*`*(a: float32, b: Color): Color {.borrow.}
proc `*=`*(a: var Color, b: float32) {.borrow.}
proc `/`*(a: Color, b: float32): Color {.borrow.}
proc `/=`*(a: var Color, b: float32) {.borrow.}

proc `*`*(a: Color, b: Color): Color {.inline.} = newColor(a.r*b.r, a.g*b.g, a.b*b.b)

proc `$`*(a: Color): string {.borrow.}
proc luminosity*(a: Color): float32 {.inline.} = 0.5 * (max(a.r, max(a.g, a.b)) + min(a.r, min(a.g, a.b)))


const 
    WHITE* = newColor(1, 1, 1)
    BLACK* = newColor(0, 0, 0)
    RED*   = newColor(1, 0, 0)
    GREEN* = newColor(0, 1, 0)
    BLUE*  = newColor(0, 0, 1)