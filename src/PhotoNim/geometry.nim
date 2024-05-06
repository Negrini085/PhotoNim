from std/strformat import fmt
from std/fenv import epsilon
from std/math import sqrt, sin, cos, arcsin, arccos, arctan2, degToRad, PI

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

proc dot2*[N: static[int], V](a, b: Vec[N, V]): V {.inline.} = 
    for i in 0..<N: result += a[i] * b[i]

proc dot*[N: static[int], V](a, b: Vec[N, V]): float32 {.inline.} = sqrt(dot2(a, b).float32)

proc norm2*[N: static[int], V](a: Vec[N, V]): V {.inline.} = dot2(a, a)
proc norm*[N: static[int], V](a: Vec[N, V]): float32 {.inline.} = dot(a, a)

proc dist2*[N: static[int], V](`from`, to: Vec[N, V]): V {.inline.} = (`from` - to).norm2
proc dist*[N: static[int], V](`from`, to: Vec[N, V]): float32 {.inline.} = (`from` - to).norm

proc normalize*[N: static[int], V](a: Vec[N, V]): Vec[N, V] {.inline.} = a / a.norm
proc dir*[N: static[int], V](at, to: Vec[N, V]): Vec[N, V] {.inline.} = (at - to).normalize

proc areClose*(x, y: float32; eps: float32 = epsilon(float32)): bool {.inline.} = abs(x - y) < eps

proc areClose*[N: static[int]](a, b: Vec[N, float32]; eps: float32 = epsilon(float32)): bool = 
    for i in 0..<N: 
        if not areClose(a[i], b[i], eps): return false


type
    Point2D* {.borrow: `.`.} = distinct Vec2f
    Point3D* {.borrow: `.`.} = distinct Vec3f
    Normal* {.borrow: `.`.} = distinct Vec3f

proc newPoint2D*(x, y: float32): Point2D {.inline.} = Point2D([x, y]) 
proc newPoint3D*(x, y, z: float32): Point3D {.inline.} = Point3D([x, y, z])
proc newNormal*(x, y, z: float32): Normal {.inline.} = Normal([x, y, z])

proc x*(a: Point2D): float32 {.inline.} = a.Vec2f[0]
proc y*(a: Point2D): float32 {.inline.} = a.Vec2f[1]

proc x*(a: Point3D | Normal): float32 {.inline.} = a.Vec3f[0]
proc y*(a: Point3D | Normal): float32 {.inline.} = a.Vec3f[1]
proc z*(a: Point3D | Normal): float32 {.inline.} = a.Vec3f[2]

proc `==`*(a, b: Point2D): bool {.borrow.}
proc `==`*(a, b: Point3D): bool {.borrow.}
proc `==`*(a, b: Normal): bool {.borrow.}

proc areClose*(a, b: Point2D; eps: float32 = epsilon(float32)): bool {.borrow.}
proc areClose*(a, b: Point3D; eps: float32 = epsilon(float32)): bool {.borrow.}
proc areClose*(a, b: Normal; eps: float32 = epsilon(float32)): bool {.borrow.}

proc `-`*(a, b: Point2D): Point2D {.borrow.}
proc `-`*(a, b: Point3D): Point3D {.borrow.}

proc `-`*(a: Normal): Normal {.borrow.}
proc `*`*(a: Normal, b: float32): Normal {.borrow.}
proc `*`*(a: float32, b: Normal): Normal {.borrow.}

proc `+`*(a: Point2D, b: Vec2f): Point2D {.inline.} = newPoint2D(a.x + b[0], a.y + b[1])
proc `+`*(a: Vec2f, b: Point2D): Point2D {.inline.} = newPoint2D(a[0] + b.x, a[1] + b.y)
proc `+`*(a: Point3D, b: Vec3f): Point3D {.inline.} = newPoint3D(a.x + b[0], a.y + b[1], a.z + b[2])
proc `+`*(a: Vec3f, b: Point3D): Point3D {.inline.} = newPoint3D(a[0] + b.x, a[1] + b.y, a[2] + b.z)

proc `-`*(a: Point2D, b: Vec2f): Point2D {.inline.} = newPoint2D(a.x - b[0], a.y - b[1])
proc `-`*(a: Vec2f, b: Point2D): Point2D {.inline.} = newPoint2D(a[0] - b.x, a[1] - b.y)
proc `-`*(a: Point3D, b: Vec3f): Point3D {.inline.} = newPoint3D(a.x - b[0], a.y - b[1], a.z - b[2])
proc `-`*(a: Vec3f, b: Point3D): Point3D {.inline.} = newPoint3D(a[0] - b.x, a[1] - b.y, a[2] - b.z)

proc norm2*(a: Normal): float32 {.borrow.}    
proc norm*(a: Normal): float32 {.borrow.}    
proc normalize*(a: Normal): Normal {.borrow.}
proc dist2*(a, b: Point2D): float32 {.borrow.}    
proc dist2*(a, b: Point3D): float32 {.borrow.}    
proc dist*(a, b: Point2D): float32 {.borrow.}    
proc dist*(a, b: Point3D): float32 {.borrow.}

proc `$`*(p: Point2D): string {.inline.} = fmt"({p.x}, {p.y})"
proc `$`*(p: Point3D): string {.inline.} = fmt"({p.x}, {p.y}, {p.z})"
proc `$`*(n: Normal): string {.inline.} = fmt"<{n.x}, {n.y}, {n.z}>"

proc toVec4*(a: Point3D): Vec4f {.inline.} = newVec4(a.x, a.y, a.z, 1.0)
proc toVec4*(a: Normal): Vec4f {.inline.} = newVec4(a.x, a.y, a.z, 0.0)
proc toVec4*(a: Vec3f): Vec4f {.inline.} = newVec4(a[0], a[1], a[2], 0.0)

proc toPoint3D*(a: Vec3f | Vec4f): Point3D {.inline.} = newPoint3D(a[0], a[1], a[2])
proc toNormal*(a: Vec3f | Vec4f): Normal {.inline.} = newNormal(a[0], a[1], a[2])
proc toVec3*(a: Vec4f): Vec3f {.inline.} = newVec3[float32](a[0], a[1], a[2])


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


proc T*[N: static[int], V](mat: Mat[1, N, V]): Vec[N, V] {.inline.} = mat[0]
proc T*[N: static[int], V](vec: Vec[N, V]): Mat[1, N, V] {.inline.} = result[0] = vec

# proc T*[M, N: static[int], V](mat: Mat[M, N, V]): Mat[N, M, V] =
#     for j in 0..<N:
#         for i in 0..<M: result[j][i] = mat[i][j]


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

proc dot*[V](a: Vec3[V], b: Mat4[V]): Mat[1, 3, V] =
    for i in 0..<3:
        for j in 0..<3: result[i] += a[i][j] * b[j]

# proc dot*[V](a: Vec3[V], b: Mat4[V]): Vec3[V] =
#     for i in 0..<3:
#         for j in 0..<3: result[i] += a[i] * b[j][i]


proc areClose*[M, N: static[int], V](a, b: Mat[M, N, V]; eps: V = epsilon(V)): bool = 
    for i in 0..<M: 
        for j in 0..<N:
            if not areClose(a[i][j], b[i][j], eps): return false


type Transformation* = object of RootObj
    mat*: Mat4f
    inv_mat*: Mat4f


proc newTransformation*(mat, inv_mat: Mat4f): Transformation = 
    assert areClose(dot(mat, inv_mat), Mat4f.id), "Invalid Transfomation! Please provide the transformation matrix and its inverse."
    (result.mat, result.inv_mat) = (mat, inv_mat)

proc id*(_: typedesc[Transformation]): Transformation {.inline} = newTransformation(Mat4f.id, Mat4f.id)


method apply*(trasf: Transformation, vec: Vec4f): Vec4f {.base, inline.} = dot(trasf.mat, vec) 
method apply*(trasf: Transformation, vec: Vec3f): Vec3f {.base, inline.} = dot(trasf.mat, vec)

## Here toVec4 is to substitute with two specific dot prod between Mat4 and Vec3 and viceversa
method apply*(trasf: Transformation, pt: Point3D): Point3D {.base, inline.} = dot(trasf.mat, pt.toVec4).toPoint3D
method apply*(trasf: Transformation, n: Normal): Normal {.base, inline.} = (dot(n.toVec4, trasf.inv_mat).T).toNormal

# ## Method to apply a generic transformation to a Normal by multiply the transpose of the inverse matrix
# var
#     x = n.x * T.inv_mat[0][0] + n.y * T.inv_mat[1][0] + n.z * T.inv_mat[2][0]
#     y = n.x * T.inv_mat[0][1] + n.y * T.inv_mat[1][1] + n.z * T.inv_mat[2][1]
#     z = n.x * T.inv_mat[0][2] + n.y * T.inv_mat[1][2] + n.z * T.inv_mat[2][2]

# result = newNormal(x, y, z)


proc `*`*(transf: Transformation, scal: float32): Transformation {.inline.} = newTransformation(transf.mat * scal, transf.inv_mat * scal)
proc `*`*(scal: float32, transf: Transformation): Transformation {.inline.} = newTransformation(transf.mat * scal, transf.inv_mat * scal)
proc `/`*(transf: Transformation, scal: float32): Transformation {.inline.} = newTransformation(transf.mat / scal, transf.inv_mat / scal)


proc `@`*(a, b: Transformation): Transformation =
    ## Compose two transformations
    result.mat = dot(a.mat, b.mat)
    result.inv_mat = dot(b.inv_mat, a.inv_mat)
    
proc inverse*(transf: Transformation): Transformation {.inline.} =
    (result.mat, result.inv_mat) = (transf.inv_mat, transf.mat)


type Scaling* = object of Transformation

proc newScaling*(factor: float32): Scaling =
    result.mat = Mat4f.id * factor
    result.inv_mat = Mat4f.id / factor
    result.mat[3][3] = 1.0
    result.inv_mat[3][3] = 1.0


proc newScaling*(v: Vec3f): Scaling =
    result.mat = [
        [v[0], 0.0, 0.0, 0.0], 
        [0.0, v[1], 0.0, 0.0], 
        [0.0, 0.0, v[2], 0.0], 
        [0.0, 0.0,  0.0, 1.0]
    ]
    result.inv_mat = [
        [1/v[0], 0.0, 0.0, 0.0], 
        [0.0, 1/v[1], 0.0, 0.0], 
        [0.0, 0.0, 1/v[2], 0.0], 
        [0.0,  0.0,  0.0,  1.0]   
    ]

method apply*(scale: Scaling, vec: Vec4f): Vec4f {.inline.} = 
    newVec4(scale.mat[0][0] * vec[0], scale.mat[1][1] * vec[1], scale.mat[2][2] * vec[2], vec[3])

method apply*(scale: Scaling, vec: Vec3f): Vec3f {.inline.} = 
    newVec3(scale.mat[0][0] * vec[0], scale.mat[1][1] * vec[1], scale.mat[2][2] * vec[2])

method apply*(scale: Scaling, pt: Point3D): Point3D {.inline.} = 
    newPoint3D(scale.mat[0][0] * pt.x, scale.mat[1][1] * pt.y, scale.mat[2][2] * pt.z)


type Translation* = object of Transformation

proc newTranslation*(v: Vec3f): Translation  = 
    result.mat = [
        [1.0, 0.0, 0.0, v[0]], 
        [0.0, 1.0, 0.0, v[1]], 
        [0.0, 0.0, 1.0, v[2]], 
        [0.0, 0.0, 0.0, 1.0]
    ]
    result.inv_mat = [
        [1.0, 0.0, 0.0, -v[0]], 
        [0.0, 1.0, 0.0, -v[1]], 
        [0.0, 0.0, 1.0, -v[2]], 
        [0.0, 0.0, 0.0,  1.0]   
    ]

method apply*(traslate: Translation, vec: Vec4f): Vec4f =
    result[0] = vec[0] + traslate.mat[0][3] * vec[3]
    result[1] = vec[1] + traslate.mat[1][3] * vec[3]
    result[2] = vec[2] + traslate.mat[2][3] * vec[3]
    result[3] = vec[3]

method apply*(translate: Translation, pt: Point3D): Point3D {.inline.} =
    newPoint3D(pt.x + translate.mat[0][3], pt.y + translate.mat[1][3], pt.z + translate.mat[2][3])


type Rotation* = object of Transformation

proc newRotX*(angle: float32): Rotation = 
    ## Procedure that creates a new rotation around x axis: angle is given in degrees
    let
        theta = degToRad(angle)
        c = cos(theta)
        s = sin(theta)

    result.mat = [
        [1.0, 0.0, 0.0, 0.0], 
        [0.0,   c,  -s, 0.0], 
        [0.0,   s,   c, 0.0], 
        [0.0, 0.0, 0.0, 1.0]
    ]
    result.inv_mat = [
        [1.0, 0.0, 0.0, 0.0], 
        [0.0,   c,   s, 0.0], 
        [0.0,  -s,   c, 0.0], 
        [0.0, 0.0, 0.0, 1.0]
    ]


proc newRotY*(angle: float32): Rotation = 
    ## Procedure that creates a new rotation around y axis: angle is given in degrees
    let
        theta = degToRad(angle)
        c = cos(theta)
        s = sin(theta)

    result.mat = [
        [  c, 0.0,   s, 0.0], 
        [0.0, 1.0, 0.0, 0.0], 
        [ -s, 0.0,   c, 0.0], 
        [0.0, 0.0, 0.0, 1.0]
    ]
    result.inv_mat = [
        [  c, 0.0,  -s, 0.0], 
        [0.0, 1.0, 0.0, 0.0], 
        [  s, 0.0,   c, 0.0], 
        [0.0, 0.0, 0.0, 1.0]
    ]


proc newRotZ*(angle: float32): Rotation = 
    ## Procedure that creates a new rotation around z axis: angle is given in degrees
    let
        theta = degToRad(angle)
        c = cos(theta)
        s = sin(theta)

    result.mat = [
        [  c,  -s, 0.0, 0.0], 
        [  s,   c, 0.0, 0.0], 
        [0.0, 0.0, 1.0, 0.0], 
        [0.0, 0.0, 0.0, 1.0]
    ]
    result.inv_mat = [
        [  c,   s, 0.0, 0.0], 
        [ -s,   c, 0.0, 0.0], 
        [0.0, 0.0, 1.0, 0.0], 
        [0.0, 0.0, 0.0, 1.0]
    ]


## =================================================
## Quat Type
## =================================================

type 
    Quat* {. borrow: `.`.} = distinct Vec4f

proc newQuat*(r, i, j, k: float32): Quat {.inline} = Quat([r, i, j, k])
proc newQuat*(scal: float32, vec: Vec3f): Quat {.inline} = Quat([scal, vec[0], vec[1], vec[2]])


proc r*(q: Quat): float32 {.inline} = q.Vec4f[0]
proc i*(q: Quat): float32 {.inline} = q.Vec4f[1]
proc j*(q: Quat): float32 {.inline} = q.Vec4f[2]
proc k*(q: Quat): float32 {.inline} = q.Vec4f[3]

proc scal*(q: Quat): float32 {.inline} = q.r
proc vec*(q: Quat): Vec3f {.inline} = newVec3(q.i, q.j, q.k)

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

    # Manually transpose the matrix
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