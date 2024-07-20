# In this geometry module are defined all the tools needed in order to implement a raytracer. 
# The content of this module spans from points, normals and vectors to linear geometry transformations
# and the implementation of bounding boxes.

from std/math import copySign, sqrt, sin, cos, degToRad, PI
from std/fenv import epsilon
from std/algorithm import reversed
from std/sequtils import concat, mapIt, minmax


type 
    Vec*[N: static[int]] = array[N, float32]
    Vec2* = Vec[2]
    Vec3* = Vec[3]
    ## Vec3 type is what it's used to represent a vector in PhotoNim
    ## It's a vector of three floating point numbers which represent components
    ## along directions x, y, and z. You can access vector elements by means of x, y, z procs, 
    ## you can sum them and multiply them by scalars and also compute cross and dot product, 
    ## evaluate norms and normalize them.

    AxisKind* = enum
        axisX = 0, axisY = 1, axisZ = 2

    Point2D* = distinct Vec2
    Point3D* = distinct Vec3
    ## Point3D type is what you have to use if you want to define a position in 3D space in PhotoNim
    ## It's just a distinct type of Vec3 so we will borrow procedures.
    
    Normal* = distinct Vec3
    ## Normals are a distinct type of Vec3, their usage is necessary when you want to study ray scattering.
    ## Their are used to create orthonormal basis, which give which provide the frame of work for studying 
    ## the physical phenomena of reflection and refraction


    Interval*[T] = tuple[min, max: T]
    AABB* = Interval[Point3D]
    ## Axis-Aligned Bounding Box Aabb is a necessary tool for implementing the bounding volume hierarchy. 
    ## In PhotoNim they are implemented as a tuple containing vertices with minimum and maximum coordinates.
    ## To evaluate AABB in the world reference system (necessary for the BVH), one must take into account 
    ## the possible transformations applied to them and to the objects they contain. For this reason, there are 
    ## procedures for creating bounding boxes from a sequence of points: once the transformation has been applied, 
    ## the vertices of the box, previously evaluated using `getVertices`, are mapped into the scene reference system,
    ## and their maximum and minimum are taken again.


    TransformationKind* = enum
        tkIdentity, tkTranslation, tkUniformScaling, tkGenericScaling, tkRotation, tkComposition

    Transformation* = object
        ## Transformations are what allow us to place objects in arbitrary positions in space. 
        ## In particular, translations, scaling and rotations around each of the axes of the standard 
        ## reference system are available. 
        case kind*: TransformationKind
        of tkIdentity: discard
        of tkComposition: transformations*: seq[Transformation]
            ## Composition kind, has a sequence of transformation as field
        
        of tkUniformScaling: factor*, invFactor*: float32
            ## Uniform scaling, used when you want to rescale uniformly along the three axis
        
        of tkGenericScaling: factors*, invFactors*: tuple[a, b, c: float32]
            ## Generic scaling, it stores direct and inverse transformation factors: a --> x, b --> y, c --> z
        
        of tkTranslation: offset*: Vec3
            ## Translation, it only stores offset vector 
        
        of tkRotation: 
            ## Rotation: rotation axis is stored, as well as sine and cosine (which are the only non zero elements in rotation matrix)
            axis*: AxisKind
            sin*, cos*: float32


proc newVec*[N: static[int]](data: array[N, float32]): Vec[N] {.inline.} = result = data
proc newVec2*(x: SomeNumber, y: SomeNumber): Vec2 {.inline.} = 
    newVec [
        when x is float32: x else: x.float32, 
        when y is float32: y else: y.float32
    ]

proc newVec3*(x: SomeNumber, y: SomeNumber, z: SomeNumber): Vec3 {.inline.} = 
    newVec [
        when x is float32: x else: x.float32, 
        when y is float32: y else: y.float32, 
        when z is float32: z else: z.float32
    ]

proc newPoint2D*(u: SomeNumber, v: SomeNumber): Point2D {.inline.} = 
    Point2D [
        when u is float32: u else: u.float32, 
        when v is float32: v else: v.float32
    ]

proc newPoint3D*(x, y, z: SomeNumber): Point3D {.inline.} = 
    Point3D [
        when x is float32: x else: x.float32, 
        when y is float32: y else: y.float32, 
        when z is float32: z else: z.float32
    ]


const
    eX*: Vec3 = [1.0, 0.0, 0.0]
    eY*: Vec3 = [0.0, 1.0, 0.0]
    eZ*: Vec3 = [0.0, 0.0, 1.0]

    ORIGIN2D* = newPoint2D(0.0, 0.0)
    ORIGIN3D* = newPoint3D(0.0, 0.0, 0.0)


proc areClose*(x, y: float32; eps: float32 = epsilon(float32)): bool {.inline.} = abs(x - y) < eps
## `areClose` proc is used to check equivalence in floating point numbers, it's fundamental for testing
proc areClose*[N: static[int]](a, b: Vec[N]; eps: float32 = epsilon(float32)): bool = 
    for i in 0..<N: 
        if not areClose(a[i], b[i], eps): return false
    return true

proc areClose*(a, b: Point2D; eps: float32 = epsilon(float32)): bool {.borrow.}
proc areClose*(a, b: Point3D; eps: float32 = epsilon(float32)): bool {.borrow.}
proc areClose*(a, b: Normal; eps: float32 = epsilon(float32)): bool {.borrow.}


proc x*(a: Vec3): float32 {.inline.} = a[axisX.int]
proc y*(a: Vec3): float32 {.inline.} = a[axisY.int]
proc z*(a: Vec3): float32 {.inline.} = a[axisZ.int]

proc x*(a: Point3D): float32 {.borrow.}
proc y*(a: Point3D): float32 {.borrow.}
proc z*(a: Point3D): float32 {.borrow.}

proc x*(a: Normal): float32 {.borrow.}
proc y*(a: Normal): float32 {.borrow.}
proc z*(a: Normal): float32 {.borrow.}

proc u*(a: Point2D): float32 {.inline.} = a.Vec2[0]
proc v*(a: Point2D): float32 {.inline.} = a.Vec2[1]


template VecVecToVecOp(op: untyped) =
    proc op*[N: static[int]](a, b: Vec[N]): Vec[N] {.inline.} =
        for i in 0..<N: result[i] = op(a[i], b[i])

VecVecToVecOp(`+`)
VecVecToVecOp(`-`)

proc `+`*(a: Point2D, b: Vec2): Point2D {.inline.} = newPoint2D(a.u + b[0], a.v + b[1])
proc `+`*(a: Vec2, b: Point2D): Point2D {.inline.} = newPoint2D(a[0] + b.u, a[1] + b.v)
proc `-`*(a: Point2D, b: Vec2): Point2D {.inline.} = newPoint2D(a.u - b[0], a.v - b[1])
proc `-`*(a: Vec2, b: Point2D): Point2D {.inline.} = newPoint2D(a[0] - b.u, a[1] - b.v)

proc `+`*(a: Point3D, b: Vec3): Point3D {.inline.} = newPoint3D(a.x + b[0], a.y + b[1], a.z + b[2])
proc `+`*(a: Vec3, b: Point3D): Point3D {.inline.} = newPoint3D(a[0] + b.x, a[1] + b.y, a[2] + b.z)
proc `-`*(a: Point3D, b: Vec3): Point3D {.inline.} = newPoint3D(a.x - b[0], a.y - b[1], a.z - b[2])
proc `-`*(a: Vec3, b: Point3D): Point3D {.inline.} = newPoint3D(a[0] - b.x, a[1] - b.y, a[2] - b.z)

proc `-`*(a, b: Point3D): Vec3 {.inline.} = newVec3(a.x - b.x, a.y - b.y, a.z - b.z)


template VecToVecUnaryOp(op: untyped) = 
    proc op*[N: static[int]](a: Vec[N]): Vec[N] {.inline.} =
        for i in 0..<N: result[i] = op(a[i])    

VecToVecUnaryOp(`-`)

proc `-`*(a: Normal): Normal {.borrow.}


template ScalVecToVecOp(op: untyped) =
    proc op*[N: static[int]](a: SomeNumber, b: Vec[N]): Vec[N] {.inline.} =
        for i in 0..<N: result[i] = op(when a is float32: a else: a.float32, b[i])

template VecScalToVecOp(op: untyped) =
    proc op*[N: static[int]](a: Vec[N], b: SomeNumber): Vec[N] {.inline.} =
        for i in 0..<N: result[i] = op(a[i], when b is float32: b else: b.float32)

ScalVecToVecOp(`*`)
VecScalToVecOp(`*`)
VecScalToVecOp(`/`)

proc `*`*(a: Normal, b: int): Normal {.borrow.}
proc `*`*(a: int, b: Normal): Normal {.borrow.}


template VecVecIncrOp(op: untyped) =
    proc op*[N: static[int]](a: var Vec[N], b: Vec[N]) {.inline.} =
        for i in 0..<N: op(a[i], b[i])

VecVecIncrOp(`+=`)
VecVecIncrOp(`-=`)


template VecScalIncrOp(op: untyped) =
    proc op*[N: static[int]](a: var Vec[N], b: SomeNumber) {.inline.} =
        for i in 0..<N: op(a[i], when b is float32: b else: b.float32)

VecScalIncrOp(`*=`)
VecScalIncrOp(`/=`)


proc cross*(a, b: Vec3): Vec3 {.inline.} =
    for i in 0..2: result[i] = a[(i + 1) mod 3] * b[(i + 2) mod 3] - a[(i + 2) mod 3] * b[(i + 1) mod 3]

proc dot*[N: static[int]](a, b: Vec[N]): float32 {.inline.} = 
    for i in 0..<N: result += a[i] * b[i]

proc norm2*[N: static[int]](a: Vec[N]): float32 {.inline.} = dot(a, a)
proc dist2*(a, b: Point3D): float32 {.inline.} = (a - b).norm2

proc norm*[N: static[int]](a: Vec[N]): float32 {.inline.} = sqrt(dot(a, a))

proc normalize*[N: static[int]](a: Vec[N]): Vec[N] {.inline.} = 
    let norm = a.norm
    return if norm == 1: a else: a / norm

proc normalize*(a: Normal): Normal {.borrow.}


proc newNormal*(x: SomeNumber, y: SomeNumber, z: SomeNumber): Normal {.inline.} = 
    Normal(newVec3(x, y, z).normalize)
    
proc newNormal*(v: Vec3): Normal {.inline.} = Normal(v.normalize)

proc newONB*(normal: Normal): array[3, Vec3] {.inline.} = 
    ## Procedure to crate an orthonormal base when a normal is give. Normal will be the third component of the base.
    let
        sign = copySign(1.0, normal.z)
        a = -1.0 / (sign + normal.z)
        b = a * normal.x * normal.y
        
    [
        newVec3(1.0 + sign * a * normal.x * normal.x, sign * b, -sign * normal.x),
        newVec3(b, sign + a * normal.y * normal.y, -normal.y),
        normal.Vec3
    ]


proc determinant(m: array[3, Vec3]): float32 {.inline.} = (
    m[0][0] * m[1][1] * m[2][2] + 
    m[0][1] * m[1][2] * m[2][0] + 
    m[0][2] * m[1][0] * m[2][1] - 
    m[0][2] * m[1][1] * m[2][0] - 
    m[0][1] * m[1][0] * m[2][2] - 
    m[0][0] * m[1][2] * m[2][1]
)

proc solve*(mat: array[3, Vec3], vec: Vec3): Vec3 {.raises: ValueError.} =
    ## `solve` procedure is used to find ray-triangle intersection by using cramer method

    let det = mat.determinant
    if areClose(det, 0.0): raise newException(ValueError, "Matrix is not invertible.")
    
    var matX, matY, matZ = mat
    for i in 0..<3: (matX[i][0], matY[i][1], matZ[i][2]) = (vec[i], vec[i], vec[i])

    result[0] = matX.determinant / det
    result[1] = matY.determinant / det
    result[2] = matZ.determinant / det


proc newInterval*(a, b: SomeNumber): Interval[float32] {.inline.} = 
    result.min = when a is float32: a else: a.float32
    result.max = when b is float32: b else: b.float32

    if a > b: swap(result.min, result.max)

proc newInterval*(a, b: Point3D): AABB {.inline.} = 
    (newPoint3D(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z)), newPoint3D(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z)))


proc contains*[T](interval: Interval[T], value: T): bool {.inline.} =
    when T is SomeNumber: 
        value >= interval.min and value <= interval.max

    elif T is Point3D:
        value.x >= interval.min.x and value.x <= interval.max.x and 
        value.y >= interval.min.y and value.y <= interval.max.y and 
        value.z >= interval.min.z and value.z <= interval.max.z


proc newAABB*(points: seq[Point3D]): AABB =
    ## `newAABB` proc is needed in order to compute an AABB starting from a sequence of points
    if points.len == 1: return (points[0], points[0])

    let 
        (xMin, xMax) = points.mapIt(it.x).minmax 
        (yMin, yMax) = points.mapIt(it.y).minmax
        (zMin, zMax) = points.mapIt(it.z).minmax

    (newPoint3D(xMin, yMin, zMin), newPoint3D(xMax, yMax, zMax))


proc getTotalAABB*(boxes: seq[AABB]): AABB =
    ## Procedure to get a box containing all those provided as input
    ## This is necessary for a BVH algorithm, which is based on AABB encaplused in one another
    if boxes.len == 0: return (newPoint3D(Inf, Inf, Inf), newPoint3D(-Inf, -Inf, -Inf))
    elif boxes.len == 1: return boxes[0]

    let
        (minX, maxX) = (boxes.mapIt(it.min.x).min, boxes.mapIt(it.max.x).max)
        (minY, maxY) = (boxes.mapIt(it.min.y).min, boxes.mapIt(it.max.y).max)
        (minZ, maxZ) = (boxes.mapIt(it.min.z).min, boxes.mapIt(it.max.z).max)

    (newPoint3D(minX, minY, minZ), newPoint3D(maxX, maxY, maxZ))


proc getCentroid*(aabb: AABB): Point3D {.inline.} =
    ## Procedure to get the centroid of an AABB, this is used to split handlers into children nodes using kmeans 
    ## We need to check wether aabb limits are finite or not
    var x, y, z: float32

    # x component
    if (copySign(aabb.min.x, 1.0) == Inf) and (copySign(aabb.max.x, 1.0) == Inf):
        x = 0
    elif copySign(aabb.min.x, 1.0) == Inf:
        x = aabb.max.x
    elif copySign(aabb.max.x, 1.0) == Inf:
        x = aabb.min.x
    else:
        x = (aabb.min.x + aabb.max.x) / 2.0

    # y component
    if (copySign(aabb.min.y, 1.0) == Inf) and (copySign(aabb.max.y, 1.0) == Inf):
        y = 0
    elif copySign(aabb.min.y, 1.0) == Inf:
        y = aabb.max.y
    elif copySign(aabb.max.y, 1.0) == Inf:
        y = aabb.min.y
    else:
        y = (aabb.min.y + aabb.max.y) / 2.0

    # z component
    if (copySign(aabb.min.z, 1.0) == Inf) and (copySign(aabb.max.z, 1.0) == Inf):
        z = 0
    elif copySign(aabb.min.z, 1.0) == Inf:
        z = aabb.max.z
    elif copySign(aabb.max.z, 1.0) == Inf:
        z = aabb.min.z
    else:
        z = (aabb.min.z + aabb.max.z) / 2.0

    newPoint3D(x, y, z)


proc getVertices*(aabb: AABB): seq[Point3D] {.inline.} =
    ## Procedure to get AABB vertices
    result = newSeqOfCap[Point3D](8)
    result.add aabb.min; result.add aabb.max
    result.add newPoint3D(aabb.min.x, aabb.min.y, aabb.max.z)
    result.add newPoint3D(aabb.min.x, aabb.max.y, aabb.min.z)
    result.add newPoint3D(aabb.min.x, aabb.max.y, aabb.max.z)
    result.add newPoint3D(aabb.max.x, aabb.min.y, aabb.min.z)
    result.add newPoint3D(aabb.max.x, aabb.min.y, aabb.max.z)
    result.add newPoint3D(aabb.max.x, aabb.max.y, aabb.min.z)


proc id*(_: typedesc[Transformation]): Transformation {.inline.} = Transformation(kind: tkIdentity)

proc newTranslation*(vec: Vec3): Transformation {.inline.} = Transformation(kind: tkTranslation, offset: vec)
proc newTranslation*(pt: Point3D): Transformation {.inline.} = Transformation(kind: tkTranslation, offset: pt.Vec3)

proc newScaling*(x: SomeNumber): Transformation {.inline.} =
    assert x != 0, "Cannot create a new scaling Transformation with zero as factor."
    Transformation(kind: tkUniformScaling, factor: x, invFactor: 1 / x)

proc newScaling*(a, b, c: SomeNumber): Transformation {.inline.} =
    assert a != 0 and b != 0 and c != 0, "Cannot create a new scaling Transformation with zero as factor."
    let
        A = when a is float32: a else: a.float32
        B = when b is float32: b else: b.float32
        C = when c is float32: c else: c.float32
    Transformation(kind: tkGenericScaling, factors: (A, B, C), invFactors: (1 / A, 1 / B, 1 / C))

proc newRotation*(angle: SomeNumber, axis: AxisKind): Transformation {.inline.} = 
    let theta = degToRad(when angle is float32: angle else: angle.float32)
    Transformation(kind: tkRotation, axis: axis, cos: cos(theta), sin: sin(theta))

proc `@`*(a, b: Transformation): Transformation =
    ## Compose operator, used to create more complex transformations
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
    ## `newComposition` procedure to create a composed transformation
    ## Transformation will be applied from right to left
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
    of tkIdentity: t
    of tkComposition: Transformation(kind: kind, transformations: t.transformations.reversed.mapIt(it.inverse))
    of tkRotation: Transformation(kind: tkRotation, axis: t.axis, cos: t.cos, sin: -t.sin)
    of tkTranslation: newTranslation(-t.offset)
    of tkUniformScaling: newScaling(t.invFactor)
    of tkGenericScaling: newScaling(t.invFactors.a, t.invFactors.b, t.invFactors.c)
    

proc apply*(t: Transformation, vec: Vec3): Vec3 =
    ## `apply` on a Vec3f. A vector cannot be translated, other transformations are applied explicitly
    ## in order to have a faster code and avoid useless computations

    case t.kind
    of tkIdentity, tkTranslation: return vec
    of tkComposition:
        if t.transformations.len == 1: return apply(t.transformations[0], vec)
        result = vec
        for i in countdown(t.transformations.len - 1, 0): result = apply(t.transformations[i], result)
    
    of tkUniformScaling: return newVec3(vec[0] * t.factor, vec[1] * t.factor, vec[2] * t.factor)
    of tkGenericScaling: return newVec3(vec[0] * t.factors.a, vec[1] * t.factors.b, vec[2] * t.factors.c)

    of tkRotation: 
        case t.axis
        of axisX: return newVec3(vec[0], vec[1] * t.cos - vec[2] * t.sin, vec[1] * t.sin + vec[2] * t.cos)
        of axisY: return newVec3(vec[0] * t.cos + vec[2] * t.sin, vec[1], vec[2] * t.cos - vec[0] * t.sin)
        of axisZ: return newVec3(vec[0] * t.cos - vec[1] * t.sin, vec[0] * t.sin + vec[1] * t.cos, vec[2])


proc apply*(t: Transformation, pt: Point3D): Point3D =
    ## `apply` procedure on a point, transformations are applied explicitly
    ## in order to have a faster code and avoid useless computations

    case t.kind
    of tkIdentity: return pt
    of tkComposition:
        if t.transformations.len == 1: return apply(t.transformations[0], pt)

        result = pt
        for i in countdown(t.transformations.len - 1, 0): result = apply(t.transformations[i], result)
    
    of tkRotation: 
        case t.axis
        of axisX: return newPoint3D(pt.x, pt.y * t.cos - pt.z * t.sin, pt.y * t.sin + pt.z * t.cos)
        of axisY: return newPoint3D(pt.x * t.cos + pt.z * t.sin, pt.y, pt.z * t.cos - pt.x * t.sin)
        of axisZ: return newPoint3D(pt.x * t.cos - pt.y * t.sin, pt.x * t.sin + pt.y * t.cos, pt.z)

    of tkTranslation: return pt + t.offset
    of tkUniformScaling: return newPoint3D(pt.x * t.factor, pt.y * t.factor, pt.z * t.factor)
    of tkGenericScaling: return newPoint3D(pt.x * t.factors.a, pt.y * t.factors.b, pt.z * t.factors.c)


proc apply*(t: Transformation, norm: Normal): Normal =
    ## `apply` procedure on a normal. The transformation you have to apply is the transposed of the inverse one:
    ## also here computations are made explicitly in order to boost code performance 
    
    case t.kind
    of tkIdentity, tkTranslation, tkUniformScaling: return norm
    of tkComposition:
        if t.transformations.len == 1: return apply(t.transformations[0], norm)

        result = norm
        for i in countdown(t.transformations.len-1, 0): result = apply(t.transformations[i], result)

    of tkRotation: 
        case t.axis
        of axisX: return newNormal(norm.x, norm.y * t.cos - norm.z * t.sin, norm.y * t.sin + norm.z * t.cos)
        of axisY: return newNormal(norm.x * t.cos + norm.z * t.sin, norm.y, norm.z * t.cos - norm.x * t.sin)
        of axisZ: return newNormal(norm.x * t.cos - norm.y * t.sin, norm.x * t.sin + norm.y * t.cos, norm.z)

    of tkGenericScaling: return newNormal(norm.x / t.factors.a, norm.y / t.factors.b, norm.z / t.factors.c)