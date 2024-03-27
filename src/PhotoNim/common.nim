import std/[fenv, math]

## =================================================
## Vector Type
## =================================================

type 
    ## Define a generic vector type with a fixed size and element type.
    Vec*[N: static[int], T] = object 
        data*: array[N, T]

    ## Define vector type aliases for common size and element type vectors.
    Vec2*[T] = Vec[2, T]
    Vec3*[T] = Vec[3, T]
    Vec2f* = Vec2[float32]
    Vec3f* = Vec3[float32]


proc newVec*[T](x, y: T): Vec2[T] {.inline.} =
    result.data = [x, y]

proc newVec*[T](x, y, z: T): Vec3[T] {.inline.} =
    result.data = [x, y, z]

proc `[]`*[N: static[int], T](a: Vec[N, T], i: int): T {.inline.} = a.data[i]
proc `[]`*[N: static[int], T](a: var Vec[N, T], i: int): var T {.inline.} = a.data[i]

proc `$`*[N: static[int], T](a: Vec[N, T]): string {.inline.} = $a.data


## =================================================
## Vector Operations Templates
## =================================================

template VecVecToVecOp(op: untyped) =
    proc op*[N: static[int], T](a, b: Vec[N, T]): Vec[N, T] {.inline.} =
        for i in 0..<N: result.data[i] = op(a[i], b[i])


template ScalVecToVecOp(op: untyped) =
    proc op*[N: static[int], T](a: T, b: Vec[N, T]): Vec[N, T] {.inline.} =
        for i in 0..<N: result.data[i] = op(a, b[i])

template VecScalToVecOp(op: untyped) =
    proc op*[N: static[int], T](a: Vec[N, T], b: T): Vec[N, T] {.inline.} =
        for i in 0..<N: result.data[i] = op(a[i], b)


template VecToVecUnaryOp(op: untyped) = 
    ## Template for performing element-wise unary operations on vectors.
    proc op*[N: static[int], T](a: Vec[N, T]): Vec[N, T] {.inline.} =
        for i in 0..<N: result.data[i] = op(a[i])    


template VecVecIncrOp(op: untyped) =
    proc op*[N: static[int], T](a: var Vec[N, T], b: Vec[N, T]) {.inline.} =
        for i in 0..<N: op(a[i], b[i])


template VecScalIncrOp(op: untyped) =
    proc op*[N: static[int], T](a: var Vec[N, T], b: T) {.inline.} =
        for i in 0..<N: op(a[i], b)


template VecVecToBoolOp(op: untyped) =
    proc op*[N: static[int], T](a, b: Vec[N, T]): bool =
        for i in 0..<N: 
            if not op(a[i], b[i]): return false
        true


## =================================================
## Vector Operations
## =================================================

VecVecToVecOp(`+`)
VecVecToVecOp(`-`)

ScalVecToVecOp(`*`)
VecScalToVecOp(`*`)
VecScalToVecOp(`/`)

VecToVecUnaryOp(`-`)

VecVecIncrOp(`+=`)
VecVecIncrOp(`-=`)

VecScalIncrOp(`*=`)
VecScalIncrOp(`/=`)

VecVecToBoolOp(`==`)
VecVecToBoolOp(`!=`)


## =================================================
## Vector Functions
## =================================================

proc dot2*[N: static[int], T](a, b: Vec[N, T]): T {.inline.} =
    for i in 0..<N: result += a[i] * b[i]

proc dot*[N: static[int], T](a, b: Vec[N, T]): float32 {.inline} = sqrt(dot2(a, b).float32)


proc norm2*[N: static[int], T](a: Vec[N, T]): T {.inline} = dot2(a, a)

proc norm*[N: static[int], T](a: Vec[N, T]): float32 {.inline} = dot(a, a)


proc dist2*[N: static[int], T](at, to: Vec[N, T]): T {.inline} = (at - to).norm2

proc dist*[N: static[int], T](at, to: Vec[N, T]): float32 {.inline} = (at - to).norm


proc normalize*[N: static[int], T](a: Vec[N, T]): Vec[N, T] {.inline} = a / a.norm

proc dir*[N: static[int], T](at, to: Vec[N, T]): Vec[N, T] {.inline} = (at - to).normalize

proc cross*[T](a, b: Vec3[T]): Vec3[T] {.inline.} =
    for i in 0..2: result[i] = a[(i + 1) mod 3] * b[(i + 2) mod 3] - a[(i + 2) mod 3] * b[(i + 1) mod 3]



## =================================================
## areClose Functions
## =================================================

proc areClose*(x, y: float32): bool {.inline.} = abs(x - y) < epsilon(float32) ## \
   ## Check if two floats are the same up to numerical precision 

proc areClose*[N: static[int]](a, b: Vec[N, float32]): bool = 
    for i in 0..<N: 
        if not areClose(a[i], b[i]): return false
    true
