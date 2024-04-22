from std/math import sqrt
from std/fenv import epsilon

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
    Vec4*[T] = Vec[4, T]
    Vec2f* = Vec2[float32]
    Vec3f* = Vec3[float32]
    Vec4f* = Vec4[float32]


proc newVec2*[T](x, y: T): Vec2[T] {.inline.} =
    ## Create a new 2-dimensional vector with the specified components.
    result.data = [x, y]

proc newVec3*[T](x, y, z: T): Vec3[T] {.inline.} =
    ## Create a new 3-dimensional vector with the specified components.
    result.data = [x, y, z]

proc newVec4*[T](x, y, z, w: T): Vec4[T] {.inline.} =
    ## Create a new 4-dimensional vector with the specified components.
    result.data = [x, y, z, w]


proc `[]`*[N: static[int], T](a: Vec[N, T], i: int): T {.inline.} = a.data[i]
proc `[]`*[N: static[int], T](a: var Vec[N, T], i: int): var T {.inline.} = a.data[i]

proc `[]=`*[N: static[int], T](a: var Vec[N, T], i: int, val: T) {.inline.} = 
    ## Set the value of the element at index `i` in the vector `a`.
    a.data[i] = val

proc `$`*[N: static[int], T](a: Vec[N, T]): string {.inline.} = $a.data


## =================================================
## Vector Operations Templates
## =================================================

template VecVecToVecOp(op: untyped) =
    ## Template for element-wise operations between two vectors resulting in a new vector.
    proc op*[N: static[int], T](a, b: Vec[N, T]): Vec[N, T] {.inline.} =
        for i in 0..<N: result[i] = op(a[i], b[i])


template ScalVecToVecOp(op: untyped) =
    ## Template for element-wise operations between a scalar and a vector resulting in a new vector.
    proc op*[N: static[int], T](a: T, b: Vec[N, T]): Vec[N, T] {.inline.} =
        for i in 0..<N: result[i] = op(a, b[i])

template VecScalToVecOp(op: untyped) =
    ## Template for element-wise operations between a vector and a scalar resulting in a new vector.
    proc op*[N: static[int], T](a: Vec[N, T], b: T): Vec[N, T] {.inline.} =
        for i in 0..<N: result[i] = op(a[i], b)


template VecToVecUnaryOp(op: untyped) = 
    ## Template for element-wise unary operations on vectors resulting in a new vector.
    proc op*[N: static[int], T](a: Vec[N, T]): Vec[N, T] {.inline.} =
        for i in 0..<N: result[i] = op(a[i])    


template VecVecIncrOp(op: untyped) =
    ## Template for in-place element-wise operations between two vectors.
    proc op*[N: static[int], T](a: var Vec[N, T], b: Vec[N, T]) {.inline.} =
        for i in 0..<N: op(a[i], b[i])


template VecScalIncrOp(op: untyped) =
    ## Template for in-place element-wise operations between a vector and a scalar.
    proc op*[N: static[int], T](a: var Vec[N, T], b: T) {.inline.} =
        for i in 0..<N: op(a[i], b)


template VecVecToBoolOp(op: untyped) =
    ## Template for element-wise comparison between two vectors resulting in a boolean value.
    proc op*[N: static[int], T](a, b: Vec[N, T]): bool =
        for i in 0..<N: 
            if not op(a[i], b[i]): return false



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


## =================================================
## Vector Functions
## =================================================

proc cat*[M, N: static[int], T](a: Vec[M, T], b: Vec[N, T]): Vec[M + N, T] =
    ## Concatenate two vectors of arbitrary sizes into a single vector.
    for i in 0..<M: result[i] = a[i]
    for i in 0..<N: result[i + M] = b[i]

proc dot2*[N: static[int], T](a, b: Vec[N, T]): T {.inline.} =
    ## Calculate the dot product of two vectors.
    for i in 0..<N: result += a[i] * b[i]

proc dot*[N: static[int], T](a, b: Vec[N, T]): float32 {.inline.} =
    ## Calculate the dot product of two vectors.
    sqrt(dot2(a, b).float32)

proc norm2*[N: static[int], T](a: Vec[N, T]): T {.inline.} =
    ## Calculate the squared norm (length) of a vector.
    dot2(a, a)

proc norm*[N: static[int], T](a: Vec[N, T]): float32 {.inline.} =
    ## Calculate the norm (length) of a vector.
    sqrt(dot(a, a))

proc dist2*[N: static[int], T](at, to: Vec[N, T]): T {.inline.} =
    ## Calculate the squared distance between two vectors.
    (at - to).norm2

proc dist*[N: static[int], T](at, to: Vec[N, T]): float32 {.inline.} =
    ## Calculate the distance between two vectors.
    (at - to).norm

proc normalize*[N: static[int], T](a: Vec[N, T]): Vec[N, T] {.inline.} =
    ## Normalize a vector.
    a / a.norm

proc dir*[N: static[int], T](at, to: Vec[N, T]): Vec[N, T] {.inline.} =
    ## Calculate the direction vector from one point to another.
    (at - to).normalize

proc cross*[T](a, b: Vec3[T]): Vec3[T] {.inline.} =
    ## Calculate the cross product of two 3-dimensional vectors.
    for i in 0..2: result[i] = a[(i + 1) mod 3] * b[(i + 2) mod 3] - a[(i + 2) mod 3] * b[(i + 1) mod 3]



## =================================================
## Matrix Types
## =================================================

type
    Mat*[M, N: static[int], V] = array[M, array[N, V]]
    SQMat*[N: static[int], V] = Mat[N, N, V]

    Mat2*[V] = SQMat[2, V]
    Mat3*[V] = SQMat[3, V]
    Mat4*[V] = SQMat[4, V]

    Mat3f* = Mat3[float32]
    Mat4f* = Mat4[float32]

proc id*[N: static[int], V](_: typedesc[SQMat[N, V]]): SQMat[N, V] {.inline.} = 
    for i in 0 ..< N: result[i][i] = V(1)


template MatOp(op: untyped) =
    ## Template for performing element-wise operations on matrices.
    ## ToDo: 
    ##  - int vs float in matrix inversion because bad casting

    proc op*[M, N: static[int], V](a, b: Mat[M, N, V]): Mat[M, N, V] =
        for i in 0 ..< M: 
            for j in 0 ..< N:
                result[i][j] = op(a[i][j], b[i][j])    

    proc op*[M, N: static[int], V](a: Mat[M, N, V], b: V): Mat[M, N, V] =
        for i in 0 ..< M: 
            for j in 0 ..< N:
                result[i][j] = op(a[i][j], b)    

    proc op*[M, N: static[int], V](a: V, b: Mat[M, N, V]): Mat[M, N, V] =
        for i in 0 ..< M: 
            for j in 0 ..< N:
                result[i][j] = op(a, b[i][j])    

MatOp(`+`)
MatOp(`-`)
MatOp(`*`)
MatOp(`/`)


proc dot*[M, N, P: static[int], T](a: Mat[M, N, T], b: Mat[N, P, T]): Mat[M, P, T] =
    for i in 0 ..< M:
        for j in 0 ..< P:
            for k in 0 ..< N:
                result[i][j] += a[i][k] * b[k][j]

proc dot*[M, N: static[int], T](a: Mat[M, N, T], b: Vec[N, T]): Vec[M, T] =
    for i in 0 ..< M:
        for j in 0 ..< N:
            result[i] += a[i][j] * b[j]

proc dot*[M, N: static[int], T](a: Vec[M, T], b: Mat[M, N, T]): Vec[N, T] =
    for i in 0 ..< M:
        for j in 0 ..< N:
            result[j] += a[i] * b[i][j]


## =================================================
## areClose Functions
## =================================================

proc areClose*(x, y: float32): bool {.inline.} = abs(x - y) < epsilon(float32) ## \
   ## Check if two floats are the same up to numerical precision 

proc areClose*[N: static[int]](a, b: Vec[N, float32]): bool = 
    ## Check if two vectors of floats are approximately equal element-wise.
    for i in 0..<N: 
        if not areClose(a[i], b[i]): return false
    return true
    

proc areClose*[N: static[int], T](a, b: array[N, T]): bool = 
    ## Check if two vectors of floats are approximately equal element-wise.
    for i in 0..<N: 
        if not areClose(a[i], b[i]): return false
    return true
    

proc areClose*[N: static[int], T](a, b: Mat[N, N, T]): bool = 
    ## Check if two matrix of floats are approximately equal element-wise.
    for i in 0..<N: 
        for j in 0..<N:
            if not areClose(a[i][j], b[i][j]): return false
    return true