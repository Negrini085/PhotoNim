import std/[math, random]    

type 
    ## Define a generic vector type with a fixed size and element type.
    Vec*[N: static[int], V] = array[N, V]

    ## Define vector type aliases for common size and element type vectors.
    Vec2*[V] = Vec[2, V]
    Vec3*[V] = Vec[3, V]
    Vec4*[V] = Vec[4, V]
    Vec2i* = Vec2[int]
    Vec3i* = Vec3[int]
    Vec4i* = Vec4[int]
    Vec2f* = Vec2[float32]
    Vec3f* = Vec3[float32]
    Vec4f* = Vec4[float32]

    

template VecOp(op: untyped) =
    ## Template for performing element-wise operations on vectors.
    
    proc op*[N: static[int], T](a: Vec[N, T], b: T): Vec[N, T] =
        for i in 0..<N: 
            result[i] = op(a[i], b)

    proc op*[N: static[int], T](a: T, b: Vec[N, T]): Vec[N, T] =
        for i in 0..<N: 
            result[i] = op(a, b[i])    

    proc op*[N: static[int], T](a, b: Vec[N, T]): Vec[N, T] =
        for i in 0..<N: 
            result[i] = op(a[i], b[i])  


VecOp(`+`)
VecOp(`-`)
VecOp(`*`)
VecOp(`/`)
VecOp(`div`)
VecOp(`mod`)
VecOp(min)
VecOp(max)



type
    Color = distinct Vec3f

proc `+`*(a, b: Color): Color {.borrow.}


proc `[]`*(a: Color, i: Ordinal): float32 {.borrow.}
proc r*(a: Color): float32 {.inline.} = a[0]
proc g*(a: Color): float32 {.inline.} = a[1]
proc b*(a: Color): float32 {.inline.} = a[2]


proc dot2*[N: static[int], T](a, b: Vec[N, T]): T =
    for i in 0..<N:
        result += a[i] * b[i]

proc norm2*[N: static[int], T](a: Vec[N, T]): T {.inline} = dot2(a, a)

proc dist2*[N: static[int], T](at, to: Vec[N, T]): T {.inline} = (at - to).norm2

proc dot*[N: static[int], T](a, b: Vec[N, T]): float {.inline} = sqrt(dot2(a, b).float)

proc norm*[N: static[int], T](a: Vec[N, T]): float {.inline} = dot(a, a)

proc dist*[N: static[int], T](at, to: Vec[N, T]): float {.inline} = (at - to).norm

proc normalize*[N: static[int], T](a: Vec[N, T]): Vec[N, T] {.inline} = a / a.norm

proc dir*[N: static[int], T](at, to: Vec[N, T]): Vec[N, T] {.inline} = (at - to).normalize

proc angle*[T](a, b: Vec[2, T] | Vec[3, T]): float {.inline} = arccos(dot(a, b) / (a.norm * b.norm)) 

proc cross*[T](a, b: Vec3[T]): Vec3[T] =
    for i in 0..2:
        result[i] = a[(i + 1) mod 3] * b[(i + 2) mod 3] - a[(i + 2) mod 3] * b[(i + 1) mod 3]