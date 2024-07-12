from std/math import sqrt, sin, cos, arcsin, arccos, arctan2, degToRad, PI, copySign
from std/fenv import epsilon
from std/algorithm import reversed
from std/sequtils import toSeq, concat, mapIt, foldl, foldr
from std/strformat import fmt


type 
    Vec*[N: static[int], V] = array[N, V]

    Vec2*[V] = Vec[2, V]
    Vec3*[V] = Vec[3, V]
    Vec4*[V] = Vec[4, V]
    Vec2f* = Vec2[float32]
    Vec3f* = Vec3[float32]
    Vec4f* = Vec4[float32]


proc newVec*[N: static[int], V](data: array[N, V]): Vec[N, V] {.inline.} = result = data

proc newVec2*[V](x, y: V): Vec2[V] {.inline.} = newVec([x, y])
proc newVec3*[V](x, y, z: V): Vec3[V] {.inline.} = newVec([x, y, z])
proc newVec4*[V](x, y, z, w: V): Vec4[V] {.inline.} = newVec([x, y, z, w])

proc newVec2f*(x, y: float32): Vec2f {.inline.} = newVec([x, y])
proc newVec3f*(x, y, z: float32): Vec3f {.inline.} = newVec([x, y, z])
proc newVec4f*(x, y, z, w: float32): Vec4f {.inline.} = newVec([x, y, z, w])


proc `==`*[N: static[int], V](a, b: Vec[N, V]): bool =
    for i in 0..<N:
        if a[i] != b[i]: return false
    return true

proc areClose*(x, y: float32; eps: float32 = epsilon(float32)): bool {.inline.} = abs(x - y) < eps
proc areClose*[N: static[int]](a, b: Vec[N, float32]; eps: float32 = epsilon(float32)): bool = 
    for i in 0..<N: 
        if not areClose(a[i], b[i], eps): return false
    return true


template VecVecToVecOp(op: untyped) =
    proc op*[N: static[int], V](a, b: Vec[N, V]): Vec[N, V] {.inline.} =
        for i in 0..<N: result[i] = op(a[i], b[i])

VecVecToVecOp(`+`)
VecVecToVecOp(`-`)


template VecToVecUnaryOp(op: untyped) = 
    proc op*[N: static[int], V](a: Vec[N, V]): Vec[N, V] {.inline.} =
        for i in 0..<N: result[i] = op(a[i])    

VecToVecUnaryOp(`-`)


template ScalVecToVecOp(op: untyped) =
    proc op*[N: static[int], V](a: V, b: Vec[N, V]): Vec[N, V] {.inline.} =
        for i in 0..<N: result[i] = op(a, b[i])

template VecScalToVecOp(op: untyped) =
    proc op*[N: static[int], V](a: Vec[N, V], b: V): Vec[N, V] {.inline.} =
        for i in 0..<N: result[i] = op(a[i], b)

ScalVecToVecOp(`*`)
VecScalToVecOp(`*`)
VecScalToVecOp(`/`)


template VecVecIncrOp(op: untyped) =
    proc op*[N: static[int], V](a: var Vec[N, V], b: Vec[N, V]) {.inline.} =
        for i in 0..<N: op(a[i], b[i])

VecVecIncrOp(`+=`)
VecVecIncrOp(`-=`)


template VecScalIncrOp(op: untyped) =
    proc op*[N: static[int], V](a: var Vec[N, V], b: V) {.inline.} =
        for i in 0..<N: op(a[i], b)

VecScalIncrOp(`*=`)
VecScalIncrOp(`/=`)


proc cross*[V](a, b: Vec3[V]): Vec3[V] {.inline.} =
    for i in 0..2: result[i] = a[(i + 1) mod 3] * b[(i + 2) mod 3] - a[(i + 2) mod 3] * b[(i + 1) mod 3]

proc dot*[N: static[int], V](a, b: Vec[N, V]): V {.inline.} = 
    for i in 0..<N: result += a[i] * b[i]

proc norm2*[N: static[int], V](a: Vec[N, V]): V {.inline.} = dot(a, a)
proc norm*[N: static[int], V](a: Vec[N, V]): float32 {.inline.} = sqrt(dot(a, a))

proc dist2*[N: static[int], V](`from`, to: Vec[N, V]): V {.inline.} = (`from` - to).norm2
proc dist*[N: static[int], V](`from`, to: Vec[N, V]): float32 {.inline.} = (`from` - to).norm

proc normalize*[N: static[int], V](a: Vec[N, V]): Vec[N, V] {.inline.} = a / a.norm
proc dir*[N: static[int], V](at, to: Vec[N, V]): Vec[N, V] {.inline.} = (at - to).normalize


type
    Point2D* {.borrow: `.`.} = distinct Vec2f
    Point3D* {.borrow: `.`.} = distinct Vec3f
    Normal* {.borrow: `.`.} = distinct Vec3f

proc newPoint2D*(u, v: float32): Point2D {.inline.} = Point2D([u, v]) 
proc newPoint3D*(x, y, z: float32): Point3D {.inline.} = Point3D([x, y, z])
proc newNormal*(x, y, z: float32): Normal {.inline.} = Normal([x, y, z].normalize)


const 
    ORIGIN2D* = newPoint2D(0, 0)
    ORIGIN3D* = newPoint3D(0, 0, 0)
    eX* = newVec3f(1, 0, 0)
    eY* = newVec3f(0, 1, 0)
    eZ* = newVec3f(0, 0, 1)

proc u*(a: Point2D): float32 {.inline.} = a.Vec2f[0]
proc v*(a: Point2D): float32 {.inline.} = a.Vec2f[1]

proc x*(a: Point3D | Normal): float32 {.inline.} = a.Vec3f[0]
proc y*(a: Point3D | Normal): float32 {.inline.} = a.Vec3f[1]
proc z*(a: Point3D | Normal): float32 {.inline.} = a.Vec3f[2]

proc `==`*(a, b: Point2D): bool {.borrow.}
proc `==`*(a, b: Point3D): bool {.borrow.}
proc `==`*(a, b: Normal): bool {.borrow.}

proc `<`*(a, b: Point3D): bool {.inline.} = a.x < b.x and a.y < b.y and a.z < b.z
proc `<=`*(a, b: Point3D): bool {.inline.} = a.x <= b.x and a.y <= b.y and a.z <= b.z

proc areClose*(a, b: Point2D; eps: float32 = epsilon(float32)): bool {.borrow.}
proc areClose*(a, b: Point3D; eps: float32 = epsilon(float32)): bool {.borrow.}
proc areClose*(a, b: Normal; eps: float32 = epsilon(float32)): bool {.borrow.}

proc `-`*(a, b: Point2D): Point2D {.borrow.}
proc `-`*(a, b: Point3D): Point3D {.borrow.}

proc `*`*(a: Point2D, b: float32): Point2D {.borrow.}
proc `*`*(a: float32, b: Point2D): Point2D {.borrow.}
proc `*`*(a: Point3D, b: float32): Point3D {.borrow.}
proc `*`*(a: float32, b: Point3D): Point3D {.borrow.}

proc `-`*(a: Normal): Normal {.borrow.}
proc `*`*(a: Normal, b: float32): Normal {.borrow.}
proc `*`*(a: float32, b: Normal): Normal {.borrow.}

proc `+`*(a: Point2D, b: Vec2f): Point2D {.inline.} = newPoint2D(a.u + b[0], a.v + b[1])
proc `+`*(a: Vec2f, b: Point2D): Point2D {.inline.} = newPoint2D(a[0] + b.u, a[1] + b.v)
proc `-`*(a: Point2D, b: Vec2f): Point2D {.inline.} = newPoint2D(a.u - b[0], a.v - b[1])
proc `-`*(a: Vec2f, b: Point2D): Point2D {.inline.} = newPoint2D(a[0] - b.u, a[1] - b.v)

proc `+`*(a: Point3D, b: Vec3f): Point3D {.inline.} = newPoint3D(a.x + b[0], a.y + b[1], a.z + b[2])
proc `+`*(a: Vec3f, b: Point3D): Point3D {.inline.} = newPoint3D(a[0] + b.x, a[1] + b.y, a[2] + b.z)
proc `-`*(a: Point3D, b: Vec3f): Point3D {.inline.} = newPoint3D(a.x - b[0], a.y - b[1], a.z - b[2])
proc `-`*(a: Vec3f, b: Point3D): Point3D {.inline.} = newPoint3D(a[0] - b.x, a[1] - b.y, a[2] - b.z)

proc norm2*(a: Normal): float32 {.borrow.}    
proc norm*(a: Normal): float32 {.borrow.}    
proc normalize*(a: Normal): Normal {.borrow.}
proc dist2*(a, b: Point2D): float32 {.borrow.}    
proc dist2*(a, b: Point3D): float32 {.borrow.}    
proc dist*(a, b: Point2D): float32 {.borrow.}    
proc dist*(a, b: Point3D): float32 {.borrow.}

proc `$`*(p: Point2D): string {.inline.} = fmt"({p.u}, {p.v})"
proc `$`*(p: Point3D): string {.inline.} = fmt"({p.x}, {p.y}, {p.z})"
proc `$`*(n: Normal): string {.inline.} = fmt"<{n.x}, {n.y}, {n.z}>"

proc toVec4*(a: Point3D): Vec4f {.inline.} = newVec4(a.x, a.y, a.z, 1.0)
proc toVec4*(a: Normal): Vec4f {.inline.} = newVec4(a.x, a.y, a.z, 0.0)
proc toVec4*(a: Vec3f): Vec4f {.inline.} = newVec4(a[0], a[1], a[2], 0.0)

proc toPoint3D*(a: Vec3f | Vec4f): Point3D {.inline.} = newPoint3D(a[0], a[1], a[2])
proc toNormal*(a: Vec3f | Vec4f): Normal {.inline.} = newNormal(a[0], a[1], a[2])

proc toVec3*(a: Vec4f): Vec3f {.inline.} = newVec3(a[0], a[1], a[2])
proc toVec3*(a: Normal): Vec3f {.inline.} = newVec3(a.x, a.y, a.z)


type
    Interval*[T] = tuple[min, max: T]

proc newInterval*[T](a, b: T): Interval[T] =
    when T is SomeNumber: 
        result = if a > b: (b, a) else: (a, b)

    elif T is Point2D: 
        result.min = newPoint2D(min(a.u, b.u), min(a.v, b.v))
        result.max = newPoint2D(max(a.u, b.u), max(a.v, b.v))

    elif T is Point3D:
        result.min = newPoint3D(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z))
        result.max = newPoint3D(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z))

    elif T is Vec3f:
        result.min = newVec3f(min(a[0], b[0]), min(a[1], b[1]), min(a[2], b[2]))
        result.min = newVec3f(max(a[0], b[0]), max(a[1], b[1]), max(a[2], b[2]))


proc contains*[T](interval: Interval, value: T): bool {.inline.} =
    when T is SomeNumber: 
        return value >= interval.min and value <= interval.max
    elif T is Point2D: 
        return value.u >= interval.min.u and value.u <= interval.max.u and 
            value.v >= interval.min.v and value.v <= interval.max.v
    elif T is Point3D:
        return value.x >= interval.min.x and value.x <= interval.max.x and 
            value.y >= interval.min.y and value.y <= interval.max.y and 
            value.z >= interval.min.z and value.z <= interval.max.z
    elif T is Vec3f:
        return x[0] >= interval.min[0] and x[0] <= interval.max[0] and 
            x[1] >= interval.min[1] and x[1] <= interval.max[1] and 
            x[2] >= interval.min[2] and x[2] <= interval.max[2]


type
    Mat*[M, N: static[int], V] = array[M, array[N, V]]
    SQMat*[N: static[int], V] = Mat[N, N, V]

    Mat2*[V] = SQMat[2, V]
    Mat3*[V] = SQMat[3, V]
    Mat4*[V] = SQMat[4, V]
    Mat3f* = Mat3[float32]
    Mat4f* = Mat4[float32]

proc newMat*[M, N: static[int], V](data: array[M, array[N, V]]): Mat[M, N, V] {.inline.} = result = data

proc newMat2*[V](x, y: array[2, V]): Mat2[V] {.inline.} = newMat([x, y])
proc newMat3*[V](x, y, z: array[3, V]): Mat3[V] {.inline.} = newMat([x, y, z])
proc newMat4*[V](x, y, z, w: array[4, V]): Mat4[V] {.inline.} = newMat([x, y, z, w])

proc toMat3*(mat: Mat4f): Mat3f {.inline.} = 
    for i in 0..<3:
        for j in 0..<3: result[i][j] = mat[i][j]

proc toMat4*(mat: Mat3f): Mat4f =
    for i in 0..<3:
        for j in 0..<3: result[i][j] = mat[i][j]

    result[3][3] = 1.0


proc areClose*[M, N: static[int], V](a, b: Mat[M, N, V]; eps: V = epsilon(V)): bool = 
    for i in 0..<M: 
        for j in 0..<N:
            if not areClose(a[i][j], b[i][j], eps): return false
    return true    


template MatMatToMatOp(op: untyped) =
    proc op*[M, N: static[int], V](a, b: Mat[M, N, V]): Mat[M, N, V] {.inline.} =
        for i in 0..<M: 
            for j in 0..<N: result[i][j] = op(a[i][j], b[i][j])    

MatMatToMatOp(`+`)
MatMatToMatOp(`-`)


template MatToMatUnaryOp(op: untyped) = 
    proc op*[M, N: static[int], V](a: Mat[M, N, V]): Mat[M, N, V] {.inline.} =
        for i in 0..<M: 
            for j in 0..<N: result[i][j] = op(a[i][j])    

MatToMatUnaryOp(`-`)


template ScalMatToMatOp(op: untyped) =
    proc op*[M, N: static[int], V](a: V, b: Mat[M, N, V]): Mat[M, N, V] {.inline.} =
        for i in 0..<M: 
            for j in 0..<N: 
                result[i][j] = op(a, b[i][j])    

template MatScalToMatOp(op: untyped) =
    proc op*[M, N: static[int], V](a: Mat[M, N, V], b: V): Mat[M, N, V] {.inline.} =
        for i in 0..<M: 
            for j in 0..<N: result[i][j] = op(a[i][j], b)    

ScalMatToMatOp(`*`)
MatScalToMatOp(`*`)
MatScalToMatOp(`/`)


template MatMatIncrOp(op: untyped) =
    proc op*[M, N: static[int], V](a: var Mat[M, N, V], b: Mat[M, N, V]) {.inline.} =
        for i in 0..<M: 
            for j in 0..<N: op(a[i][j], b[i][j])

MatMatIncrOp(`+=`)
MatMatIncrOp(`-=`)


template MatScalIncrOp(op: untyped) =
    proc op*[M, N: static[int], V](a: var Mat[M, N, V], b: V) {.inline.} =
        for i in 0..<M: 
            for j in 0..<N: op(a[i][j], b)

MatScalIncrOp(`*=`)
MatScalIncrOp(`/=`)


proc id*[N: static[int], V](_: typedesc[SQMat[N, V]]): SQMat[N, V] {.inline.} = 
    for i in 0..<N: result[i][i] = V(1)

proc Tv*[N: static[int], V](mat: Mat[1, N, V]): Vec[N, V] {.inline.} = mat[0]
proc T*[N: static[int], V](vec: Vec[N, V]): Mat[1, N, V] {.inline.} = result[0] = vec
proc T*[M, N: static[int], V](mat: Mat[M, N, V]): Mat[N, M, V] =

    for i in 0..<N:
        for j in 0..<M:
            result[i][j] = mat[j][i]


proc dot*[M, N, P: static[int], V](a: Mat[M, N, V], b: Mat[N, P, V]): Mat[M, P, V] =
    for i in 0..<M:
        for j in 0..<P:
            for k in 0..<N: result[i][j] += a[i][k] * b[k][j]

proc dot*[M, N: static[int], V](a: Mat[M, N, V], b: Vec[N, V]): Vec[M, V] =
    for i in 0..<M:
        for j in 0..<N: result[i] += a[i][j] * b[j]

proc dot*[M, N: static[int], V](a: Vec[M, V], b: Mat[M, N, V]): Mat[1, N, V] {.inline.} = dot(a.T, b)


proc dot*[V](a: Mat4[V], b: Vec3[V]): Vec3[V] =
    for i in 0..<3:
        for j in 0..<3: result[i] += a[i][j] * b[j]

proc dot*[V](n: Normal, mat: Mat4[V]): Vec3[V] {.inline.} =
    for i in 0..<3: result[i] = n.x * mat[0][i] + n.y * mat[1][i] + n.z * mat[2][i]

proc det*[N: static[int], V](m: SQMat[N, V]): V =
    when N == 1:
        return m[0][0]
    elif N == 2: 
        return m[0][0] * m[1][1] - m[0][1] * m[1][0]
    elif N == 3:
        return (
            m[0][0] * m[1][1] * m[2][2] + 
            m[0][1] * m[1][2] * m[2][0] + 
            m[0][2] * m[1][0] * m[2][1] - 
            m[0][2] * m[1][1] * m[2][0] - 
            m[0][1] * m[1][0] * m[2][2] - 
            m[0][0] * m[1][2] * m[2][1]
        )
    elif N == 4:
        return (
            m[3][0] * m[2][1] * m[1][2] * m[0][3]  -  m[2][0] * m[3][1] * m[1][2] * m[0][3]  -  m[3][0] * m[1][1] * m[2][2] * m[0][3]  +  m[1][0] * m[3][1] * m[2][2] * m[0][3] +
            m[2][0] * m[1][1] * m[3][2] * m[0][3]  -  m[1][0] * m[2][1] * m[3][2] * m[0][3]  -  m[3][0] * m[2][1] * m[0][2] * m[1][3]  +  m[2][0] * m[3][1] * m[0][2] * m[1][3] +
            m[3][0] * m[0][1] * m[2][2] * m[1][3]  -  m[0][0] * m[3][1] * m[2][2] * m[1][3]  -  m[2][0] * m[0][1] * m[3][2] * m[1][3]  +  m[0][0] * m[2][1] * m[3][2] * m[1][3] +
            m[3][0] * m[1][1] * m[0][2] * m[2][3]  -  m[1][0] * m[3][1] * m[0][2] * m[2][3]  -  m[3][0] * m[0][1] * m[1][2] * m[2][3]  +  m[0][0] * m[3][1] * m[1][2] * m[2][3] +
            m[1][0] * m[0][1] * m[3][2] * m[2][3]  -  m[0][0] * m[1][1] * m[3][2] * m[2][3]  -  m[2][0] * m[1][1] * m[0][2] * m[3][3]  +  m[1][0] * m[2][1] * m[0][2] * m[3][3] +
            m[2][0] * m[0][1] * m[1][2] * m[3][3]  -  m[0][0] * m[2][1] * m[1][2] * m[3][3]  -  m[1][0] * m[0][1] * m[2][2] * m[3][3]  +  m[0][0] * m[1][1] * m[2][2] * m[3][3] 
        )
    else:
        quit "Determinant is only implemented for matrices at most 4x4."


proc solve*(mat: Mat3f, vec: Vec3f): Vec3f {.raises: ValueError.} =
    let det = mat.det
    if det == 0.0: raise newException(ValueError, "Matrix is not invertible.")
    
    var matX, matY, matZ = mat
    for i in 0..<3: (matX[i][0], matY[i][1], matZ[i][2]) = (vec[i], vec[i], vec[i])

    result[0] = matX.det / det
    result[1] = matY.det / det
    result[2] = matZ.det / det


type 

    AxisKind* = enum axisX = 0, axisY = 1, axisZ = 2

    TransformationKind* = enum
        tkIdentity, tkTranslation, tkUniformScaling, tkGenericScaling, tkRotation, tkComposition

    Transformation* = object
        case kind*: TransformationKind
        of tkComposition: transformations*: seq[Transformation]
        of tkIdentity: discard
        of tkTranslation: offset*: Vec3f
        of tkUniformScaling: factor*: float32
        of tkGenericScaling: factors*: tuple[a, b, c: float32]
        of tkRotation: 
            axis*: AxisKind
            sin*, cos*: float32

proc id*(_: typedesc[Transformation]): Transformation {.inline.} = Transformation(kind: tkIdentity)

proc newTranslation*(vec: Vec3f): Transformation {.inline.} = 
    Transformation(kind: tkTranslation, offset: vec)

proc newTranslation*(pt: Point3D): Transformation {.inline.} = 
    Transformation(kind: tkTranslation, offset: pt.Vec3f)

proc newScaling*(x: SomeNumber): Transformation {.inline.} =
    assert x != 0, "Cannot create a new scaling Transformation with zero as factor."
    Transformation(kind: tkUniformScaling, factor: when x is float32: x else: x.float32)

proc newScaling*(a, b, c: float32): Transformation {.inline.} =
    assert a != 0 and b != 0 and c != 0, "Cannot create a new scaling Transformation with zero as factor."
    Transformation(kind: tkGenericScaling, factors: (a, b, c))

proc newRotation*(angle: SomeNumber, axis: AxisKind): Transformation {.inline.} = 
    let theta = degToRad(when angle is float32: angle else: angle.float32)
    Transformation(kind: tkRotation, axis: axis, cos: cos(theta), sin: sin(theta))

proc `@`*(a, b: Transformation): Transformation =
    if a.kind == tkIdentity: return b
    if b.kind == tkIdentity: return a

    var transforms: seq[Transformation]
    if a.kind == tkComposition:
        if b.kind == tkComposition: 
            transforms = concat(a.transformations, b.transformations)
        else: 
            transforms = a.transformations
            transforms.add b        

    elif b.kind == tkComposition: 
        transforms = b.transformations
        transforms.insert(a, 0)

    else: transforms.add a; transforms.add b

    Transformation(kind: tkComposition, transformations: transforms)

proc newComposition*(transformations: varargs[Transformation]): Transformation =
    if transformations.len == 1: return transformations[0]
    elif transformations.len == 2: return transformations[0] @ transformations[1]
    var transforms = newSeq[Transformation]()
    for t in transformations:
        case t.kind
        of tkIdentity: continue
        of tkComposition: transforms = concat(transforms, t.transformations)
        else: transforms.add t

    Transformation(kind: tkComposition, transformations: transforms)


proc inverse*(t: Transformation): Transformation =
    let kind = t.kind
    case kind
    of tkComposition: Transformation(kind: kind, transformations: t.transformations.reversed.mapIt(it.inverse))
    of tkIdentity: t
    of tkTranslation: newTranslation(-t.offset)
    of tkUniformScaling: newScaling(1 / t.factor)
    of tkGenericScaling: newScaling(1 / t.factors.a, 1 / t.factors.b, 1 / t.factors.c)
    of tkRotation: Transformation(kind: tkRotation, axis: t.axis, cos: t.cos, sin: -t.sin)
    

proc apply*(t: Transformation, vec: Vec3f): Vec3f =
    case t.kind
    of tkComposition:
        if t.transformations.len == 1: return apply(t.transformations[0], vec)
        result = vec
        for i in countdown(t.transformations.len - 1, 0):
            result = apply(t.transformations[i], result)
    
    of tkIdentity: return vec

    of tkRotation: 
        case t.axis
        of axisX: return newVec3f(vec[0], vec[1] * t.cos - vec[2] * t.sin, vec[1] * t.sin + vec[2] * t.cos)
        of axisY: return newVec3f(vec[0] * t.cos + vec[2] * t.sin, vec[1], vec[2] * t.cos - vec[0] * t.sin)
        of axisZ: return newVec3f(vec[0] * t.cos - vec[1] * t.sin, vec[0] * t.sin + vec[1] * t.cos, vec[2])

    of tkTranslation: return vec
    of tkUniformScaling: return newVec3(vec[0] * t.factor, vec[1] * t.factor, vec[2] * t.factor)
    of tkGenericScaling: return newVec3(vec[0] * t.factors.a, vec[1] * t.factors.b, vec[2] * t.factors.c)

proc apply*(t: Transformation, pt: Point3D): Point3D =
    case t.kind
    of tkComposition:
        if t.transformations.len == 1: return apply(t.transformations[0], pt)

        result = pt
        for i in countdown(t.transformations.len - 1, 0):
            result = apply(t.transformations[i], result)
    
    of tkIdentity: return pt

    of tkRotation: 
        case t.axis
        of axisX: return newPoint3D(pt.x, pt.y * t.cos - pt.z * t.sin, pt.y * t.sin + pt.z * t.cos)
        of axisY: return newPoint3D(pt.x * t.cos + pt.z * t.sin, pt.y, pt.z * t.cos - pt.x * t.sin)
        of axisZ: return newPoint3D(pt.x * t.cos - pt.y * t.sin, pt.x * t.sin + pt.y * t.cos, pt.z)

    of tkTranslation: return pt + t.offset
    of tkUniformScaling: return newPoint3D(pt.x * t.factor, pt.y * t.factor, pt.z * t.factor)
    of tkGenericScaling: return newPoint3D(pt.x * t.factors.a, pt.y * t.factors.b, pt.z * t.factors.c)

proc apply*(t: Transformation, norm: Normal): Normal =
    case t.kind
    of tkComposition:
        if t.transformations.len == 1: return apply(t.transformations[0], norm)
        result = norm
        for i in countdown(t.transformations.len-1, 0):
            result = apply(t.transformations[i], result)

    
    of tkIdentity: return norm

    of tkRotation: 
        case t.axis
        of axisX: return newNormal(norm.x, norm.y * t.cos - norm.z * t.sin, norm.y * t.sin + norm.z * t.cos)
        of axisY: return newNormal(norm.x * t.cos + norm.z * t.sin, norm.y, norm.z * t.cos - norm.x * t.sin)
        of axisZ: return newNormal(norm.x * t.cos - norm.y * t.sin, norm.x * t.sin + norm.y * t.cos, norm.z)

    of tkTranslation: return norm
    of tkUniformScaling: return norm
    of tkGenericScaling: 
        return newNormal(norm.x / t.factors.a, norm.y / t.factors.b, norm.z / t.factors.c)

type Ray* = ref object
    origin*: Point3D
    dir*: Vec3f
    tSpan*: Interval[float32]
    depth*: int

proc newRay*(origin: Point3D, direction: Vec3f, depth: int = 0): Ray {.inline.} = 
    Ray(origin: origin, dir: direction, tSpan: (float32 1.0, float32 Inf), depth: depth)  

proc areClose*(a, b: Ray; eps: float32 = epsilon(float32)): bool {.inline.} = 
    areClose(a.origin, b.origin, eps) and areClose(a.dir, b.dir, eps)

proc transform*(ray: Ray; transformation: Transformation): Ray {.inline.} =
    case transformation.kind: 
    of tkIdentity: ray
    of tkTranslation: 
        Ray(
            origin: apply(transformation, ray.origin), 
            dir: ray.dir, 
            tSpan: ray.tSpan, depth: ray.depth
        )
    else: 
        Ray(
            origin: apply(transformation, ray.origin), 
            dir: apply(transformation, ray.dir), 
            tSpan: ray.tSpan, depth: ray.depth
        )

proc `$`*(ray: Ray): string {.inline.} =
    return fmt"Origin: {ray.origin}, Direction: {ray.dir}, Tmin: {ray.tSpan.min}, Tmax: {ray.tSpan.max}, Depth: {ray.depth}"

proc at*(ray: Ray; time: float32): Point3D {.inline.} = ray.origin + ray.dir * time


proc newONB*(normal: Normal): Mat3f = 
    let
        sign = copySign(1.0, normal.z)
        a = -1.0 / (sign + normal.z)
        b = a * normal.x * normal.y
        
    [
        newVec3f(1.0 + sign * a * normal.x * normal.x, sign * b, -sign * normal.x),
        newVec3f(b, sign + a * normal.y * normal.y, -normal.y),
        normal.Vec3f
    ]


type 
    Quat* {. borrow: `.`.} = distinct Vec4f

proc newQuat*(r, i, j, k: float32): Quat {.inline.} = Quat([r, i, j, k])
proc newQuat*(scal: float32, vec: Vec3f): Quat {.inline.} = Quat([scal, vec[0], vec[1], vec[2]])


proc r*(q: Quat): float32 {.inline.} = q.Vec4f[0]
proc i*(q: Quat): float32 {.inline.} = q.Vec4f[1]
proc j*(q: Quat): float32 {.inline.} = q.Vec4f[2]
proc k*(q: Quat): float32 {.inline.} = q.Vec4f[3]

proc scal*(q: Quat): float32 {.inline.} = q.r
proc vec*(q: Quat): Vec3f {.inline.} = newVec3(q.i, q.j, q.k)

proc `==`*(a, b: Quat): bool {.borrow.}
proc areClose*(a, b: Quat): bool {.borrow.}

proc `+`*(a, b: Quat): Quat {.borrow.}
proc `-`*(a, b: Quat): Quat {.borrow.}
proc `*`*(a: Quat, b: float32): Quat {.borrow.}
proc `*`*(a: float32, b: Quat): Quat {.borrow.}
proc `/`*(a: Quat, b: float32): Quat {.borrow.}

proc norm*(a: Quat): float32 {.borrow}
proc conj*(a: Quat): Quat {.inline.} = newQuat(a.scal, -a.vec)
proc inv*(a: Quat): Quat {.inline.} = a.conj / a.norm

proc dot*(a, b: Quat): Quat {.inline.} =
    newQuat(
        a.j * b.k - a.k * b.j + a.i * b.r + a.r * b.i,
        a.k * b.i - a.i * b.k + a.j * b.r + a.r * b.j,
        a.i * b.j - a.j * b.i + a.k * b.r + a.r * b.k,
        a.r * b.r - a.i * b.i - a.j * b.j - a.k * b.k
    )

proc angle*(q: Quat): float32 {.inline.} = 2.0 * arccos(q.r)
proc rotateVec*(q: Quat, v: Vec3f): Vec3f {.inline.} = dot(q, dot(newQuat(0.0, v), q.inv)).vec

proc toMat4*(q: Quat): Mat4f =
    result[0][1] = -q.k
    result[0][2] = q.j
    result[1][2] = -q.i
    result[0][3] = q.i
    result[1][3] = q.j
    result[2][3] = q.k

    var tmp: float
    for i in 0..3:
        for j in i + 1..3:
            tmp = result[i][j]
            result[i][j] = result[j][i]
            result[j][i] = tmp

    for i in 0..3:
        result[i][i] = q.r

proc toMat3*(q: Quat): Mat3f =
    let 
        sqx = q.i * q.i
        sqy = q.j * q.j
        sqz = q.k * q.k
        xy = q.i * q.j
        xz = q.i * q.k
        yz = q.j * q.k
        xw = q.i * q.r
        yw = q.j * q.r
        zw = q.k * q.r
    [
        [1 - 2 * sqy - 2 * sqz, 2 * xy - 2 * zw, 2 * xz + 2 * yw],
        [2 * xy + 2 * zw, 1 - 2 * sqx - 2 * sqz, 2 * yz - 2 * xw],
        [2 * xz - 2 * yw, 2 * yz + 2 * xw, 1 - 2 * sqx - 2 * sqy]
    ]

proc fromEulerAngles*(ang: Vec3f): Quat =
    let
        angles = ang / 2.0
        c1 = cos(angles[2])
        c2 = cos(angles[1])
        c3 = cos(angles[0])
        s1 = sin(angles[2])
        s2 = sin(angles[1])
        s3 = sin(angles[0])

    newQuat(
        c1 * c2 * s3 - s1 * s2 * c3,
        c1 * s2 * c3 + s1 * c2 * s3,
        s1 * c2 * c3 - c1 * s2 * s3,
        c1 * c2 * c3 + s1 * s2 * s3
    )

proc toEulerAngles*(q: Quat): Vec3f = 
    let 
        sqw = q.r * q.r
        sqx = q.i * q.i
        sqy = q.j * q.j
        sqz = q.k * q.k
      
    result[1] = arcsin(2.0 * (q.r * q.j - q.i * q.k))
    if 0.5 * PI - abs(result[1]) > epsilon(float):
        result[2] = arctan2(2.0 * (q.i * q.j + q.r * q.k), sqx - sqy - sqz + sqw)
        result[0] = arctan2(2.0 * (q.r * q.i + q.j * q.k), sqw - sqx - sqy + sqz)
    else:
        result[2] = arctan2(2.0 * q.j * q.k - 2 * q.i * q.r, 2 * q.i * q.k + 2 * q.j * q.r)
        result[0] = 0.0

    if result[1] < 0.0:
        result[2] = PI - result[2]