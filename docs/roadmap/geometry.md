---
layout: page
title: Geometry
parent: Roadmap
permalink: /roadmap/geometry/
nav_order: 0
---

<div style="text-align: center;">
    <span style="color: black; font-size: 40px;"> PhotoNim Geometry submodule </span>
</div>

PhotoNim is a ray tracing code that enables the rendering of complex scenery. To solve the rendering equation, define shapes, and study the evolution of rays in space and time, it is necessary to implement code to address problems in linear geometry, work with vectors, and manage entire scenarios.
<div style="height: 40px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> Vector type </span>
</div>
<div style="height: 40px;"></div>

Vectors are one of the fundamental units of our code as they allow us to define directions and will also serve as the basis for implementing points and normals. To ensure maximum generality, the most general vectors are template arrays with a specified length. The type ```Vec*[N: static[int], V]``` specializes in fixed-length, fixed-type vectors, as we are particularly interested in float32 vectors that are 2, 3, or 4 memory cells long (due to the dimensionality of the problem we want to solve).

```nim
type 
    Vec*[N: static[int], V] = array[N, V]

    Vec2*[V] = Vec[2, V]
    Vec3*[V] = Vec[3, V]
    Vec4*[V] = Vec[4, V]
    Vec2f* = Vec2[float32]
    Vec3* = Vec3[float32]
    Vec4f* = Vec4[float32]
```

It is possible to initialize a new variable of type ```Vec_``` (where the suffix, labeled as _,  indicates the specific vector type you wish to use) using the procedure ```newVec_```. We are particularly interested in procedures that allow initializing Vec of float32, specifically:

```nim
proc newVec*[N: static[int], V](data: array[N, V]): Vec[N, V] {.inline.} = result = data

proc newVec2f*(x, y: float32): Vec2f {.inline.} = newVec([x, y])
proc newVec3*(x, y, z: float32): Vec3 {.inline.} = newVec([x, y, z])
proc newVec4f*(x, y, z, w: float32): Vec4f {.inline.} = newVec([x, y, z, w])
```

We have implemented operations between vectors and between vectors and scalars by overloading the operators available in Nim. In particular, regarding operations between vectors alone, the following are available:

```nim
template VecVecToVecOp(op: untyped) =
    proc op*[N: static[int], V](a, b: Vec[N, V]): Vec[N, V] {.inline.} =
        for i in 0..<N: result[i] = op(a[i], b[i])

VecVecToVecOp(`+`)
VecVecToVecOp(`-`)


template VecVecIncrOp(op: untyped) =
    proc op*[N: static[int], V](a: var Vec[N, V], b: Vec[N, V]) {.inline.} =
        for i in 0..<N: op(a[i], b[i])

VecVecIncrOp(`+=`)
VecVecIncrOp(`-=`)
```

Regarding operations between vectors and scalars you can rescale vectors using product and division by scalars. We have also implemented cross and scalar product, as well as normalization procedure. Here we list such procedures:

```nim
proc cross*[V](a, b: Vec3[V]): Vec3[V]                          # Performs cross product

proc dot*[N: static[int], V](a, b: Vec[N, V]): V                # Performs scalar product

proc norm2*[N: static[int], V](a: Vec[N, V]): V                 # Compute vector squared norm

proc norm*[N: static[int], V](a: Vec[N, V]): float32            # Compute vector norm

proc normalize*[N: static[int], V](a: Vec[N, V]): Vec[N, V]     # Normalizes a vector

proc dir*[N: static[int], V](at, to: Vec[N, V]): Vec[N, V]      # Gives direction
```

A fundamental procedure during testing is ```areClose```, which evaluates whether two vectors are comparable with a certain level of confidence or not.

```nim
proc areClose*(x, y: float32; eps: float32 = epsilon(float32)): bool {.inline.} = abs(x - y) < eps

proc areClose*[N: static[int]](a, b: Vec[N, float32]; eps: float32 = epsilon(float32)): bool = 
    for i in 0..<N: 
        if not areClose(a[i], b[i], eps): return false
    return true
```

<div style="height: 25px;"></div>
<div style="text-align: left;">
    <span style="color: blue; font-size: 20px;"> Example </span>
</div>
<div style="height: 25px;"></div>

```nim
var 
    # Here we show three different initialization proc
    v1 = newVec[3, int]([1, 2, 3])      # Initializes a Vec[3, int]
    v2 = newVec3[float32](1, 2, 3)      # Initializes a Vec3[float32]
    v3 = newVec3(4, 5, 6)              # Initializes a Vec3

echo ' '
echo "Vector sum: ", v2 + v3    # You should see (5, 7, 9)
echo "Vector difference: ", v2 - v3    # You should see (-3, -3, -3)

echo ' '
echo "Dot product: ", dot(v2, v3)    # You should see 32
echo "Cross product", cross(v2, v3)  # You should see (-3, 6, -3)

echo ' '
echo "areClose(v2, v3): ", areClose(v2, v3)                   # You should see false
echo "areClose(v2, v2)", areClose(v2, newVec3(1, 2, 3))    # You should see true

echo ' '
echo "v1 norm: ", v1.norm2   # You should see 14
```

<div style="height: 40px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> Distinct vector types </span>
</div>
<div style="height: 40px;"></div>

In order to deal with a complex scenario, vectors alone aren't adequate: we must also incorporate points and normals. To accomplish this we utilize distinct types, which are like other type aliases, but they provide type safety so that it is impossible to coerce a distinct type into its base type without explicit conversion.

```nim
type
    Point2D* {.borrow: `.`.} = distinct Vec2f
    Point3D* {.borrow: `.`.} = distinct Vec3
    Normal* {.borrow: `.`.} = distinct Vec3

# Constructor procs
proc newPoint2D*(u, v: float32): Point2D {.inline.} = Point2D([u, v]) 

proc newPoint3D*(x, y, z: float32): Point3D {.inline.} = Point3D([x, y, z])

proc newNormal*(x, y, z: float32): Normal {.inline.} = Normal([x, y, z].normalize)
```

You can access point coordinates using ```u, v``` procs for a Point2D variable or ```x, y, z``` for a Point3D. Cosidering that Point2D, Point3D and Normal are distinct types of Vec2f and Vec3 respectively, we borrow procedures implemented for Vector types. We have added procedures for addition and subtraction between points and vectors such as following, as it does not make geometric sense to add two points.

```nim
proc `+`*(a: Point2D, b: Vec2f): Point2D {.inline.} = newPoint2D(a.u + b[0], a.v + b[1])

proc `+`*(a: Point3D, b: Vec3): Point3D {.inline.} = newPoint3D(a.x + b[0], a.y + b[1], a.z + b[2])
```

<div style="height: 25px;"></div>
<div style="text-align: left;">
    <span style="color: blue; font-size: 20px;"> Example </span>
</div>
<div style="height: 25px;"></div>

```nim

var
    vec = newVec3(4, 5, 6)         # Initializes a three-dimensional vector
    p_3d = newPoint3D(1, 2, 3)      # New three-dimensional point
    p_2d = newPoint2D(1.0, 0.5)     # New two dimensional point
    normal = newNormal(1, 0, 0)     # New normal

echo ' '
echo "Vector + Point3D: ", vec + p_3d         # You should get (5, 7, 9)
echo "Point3D - Vector: ", p_3d - vec         # You should get (-3, -3, -3)

echo ' '
echo "First point2D component: ", p_2d.u       # You should get 1.0
echo "Second point2D component: ", p_2d.v      # You should get 0.5

echo ' '
echo "First point3D component: ", p_3d.x             # You should get 1
echo "First Normal component: ", normal.x            # You should get 1


echo ' '
echo "Scalar product: ", dot(normal.Vec3, vec)               # You should get 4
echo "AreClose test: ", areClose(p_3d, newPoint3D(2, 3, 4))   # You should get false
```

<div style="height: 40px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> Transformation types </span>
</div>
<div style="height: 40px;"></div>

In order to create and manipulate complex scenarios, it is necessary to apply transformations to the geometric elements we have previously defined. In PhotoNim, only invertible transformations are implemented, such as:

- scaling
- rotation
- translation

Two matrices are associated to each transformation, one representing the direct transformation, while the other describes the inverse one. Consequently, we must develop procedures and types that enable us to manipulate these matrices. 

<div style="height: 25px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 20px;"> Matrices </span>
</div>
<div style="height: 25px;"></div>

In PhotoNim a matrix is an array of arrays: working like this might seem non-optimal in terms of memory storage and usage, but considering that we use 4x4 matrices (thus of small dimensions), this is not the case. We have maintained the same approach that we used during vectors defining , starting from the definition of general template types and then moving on to the specific types relevant to PhotoNim and a RayTracing program

```
type
    Mat*[M, N: static[int], V] = array[M, array[N, V]]
    SQMat*[N: static[int], V] = Mat[N, N, V]

    Mat2*[V] = SQMat[2, V]
    Mat3*[V] = SQMat[3, V]
    Mat4*[V] = SQMat[4, V]
    Mat3f* = Mat3[float32]
    Mat4f* = Mat4[float32]
```

There are procedures available for initializing variables, but they are not relevant for our code as matrices only serve as a support for transformations. It could be useful using ```areClose``` procedure in order to test transformation equivalence, which is deeply linked to matrix equivalence.

```nim
proc areClose*[M, N: static[int], V](a, b: Mat[M, N, V]; eps: V = epsilon(V)): bool = 
    for i in 0..<M: 
        for j in 0..<N:
            if not areClose(a[i][j], b[i][j], eps): return false
    return true    
```

We overloaded sum, difference and product operators in order to have the possibility to do matrix operations:

```nim
template MatMatToMatOp(op: untyped) =
    proc op*[M, N: static[int], V](a, b: Mat[M, N, V]): Mat[M, N, V] {.inline.} =
        for i in 0..<M: 
            for j in 0..<N: result[i][j] = op(a[i][j], b[i][j])    

MatMatToMatOp(`+`)
MatMatToMatOp(`-`)
```

and operations between matrices and scalars.

```nim
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
```

Fundamental for the application of transformations is the possibility of carrying out the product between matrices and vectors: this functionality is available in PhotoNim and is of basal importance for a raytracing code like ours.

```nim
proc dot*[M, N, P: static[int], V](a: Mat[M, N, V], b: Mat[N, P, V]): Mat[M, P, V] =
    for i in 0..<M:
        for j in 0..<P:
            for k in 0..<N: result[i][j] += a[i][k] * b[k][j]

proc dot*[M, N: static[int], V](a: Mat[M, N, V], b: Vec[N, V]): Vec[M, V] =
    for i in 0..<M:
        for j in 0..<N: result[i] += a[i][j] * b[j]
```

<div style="height: 25px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 20px;"> Transformations </span>
</div>
<div style="height: 25px;"></div>

The transformations we want to have avilable in PhotoNim are:
- rotation
- scaling
- translation
- identity

and possible combinations of the ones previously listed. 
We have opted to implement them as different ```kind``` of the ```Transformation type``` due to challenges encountered with inheritance in Nim. 
The total number of transformation types is six, as we have also taken into account the possibility of generic and composite transformations.

```nim
type 
    TransformationKind* = enum
        tkIdentity, tkGeneric, tkTranslation, tkScaling, tkRotation, tkComposition

    Transformation* = object
        case kind*: TransformationKind
        of tkIdentity: discard
        of tkGeneric, tkTranslation, tkScaling, tkRotation:
            mat*, inv_mat*: Mat4f
        of tkComposition: 
            transformations*: seq[Transformation]
```

As you can see, direct and inverse matrices are 4x4: that's because 3x3 translation matrices aren't linear operators. 
In order to restore linearity, we need to add a dimension and use 4x4 matrices: in such a frame of work we also need to add a coordinate to points and vectors. 
A vector has zero as its fourth component, whilst a point has one at the same position.
To establish the most comprehensive framework wherein transformations are determined by the row-by-column multiplication of vectors and matrices, procedures are implemented to upgrade three-component elements into 4-component memory containers.

```nim
proc toVec4*(a: Point3D): Vec4f {.inline.} = newVec4(a.x, a.y, a.z, 1.0)
proc toVec4*(a: Normal): Vec4f {.inline.} = newVec4(a.x, a.y, a.z, 0.0)
proc toVec4*(a: Vec3): Vec4f {.inline.} = newVec4(a[0], a[1], a[2], 0.0)
```

Since we aim to describe various types of transformations, constructor procedures vary significantly from one another. Below, we outline the different constructor procedures:

- ```proc newTranslation*(v: Vec3): Transformation``` enables the user to define a translation procedure providing as input a Vec3, which will be the vector through which the points will be translated.

- ```proc newScaling*[T](x: T): Transformation``` which initializes a translation variable of kind ```tkScaling``` to uniform scaling if a scalar is given as input, otherwise a non-isotropic scaling if a ```Vec3``` is provided.

- ```proc newRotX*(angle: SomeNumber): Transformation``` defines a rotation around the x-axis. The angle of rotation is given in degrees.

- ```proc newRotY*(angle: SomeNumber): Transformation``` defines a rotation around the y-axis. The angle of rotation is given in degrees.

- ```proc newRotZ*(angle: SomeNumber): Transformation``` defines a rotation around the z-axis. The angle of rotation is given in degrees.

- ```proc newComposition*(transformations: varargs[Transformation]): Transformation``` enables the user to define a transformations composition: the first one given is the first one applied. You can compose different transformation via ```@``` operator.

- ```proc newTransformation*(mat, inv_mat: Mat4f): Transformation``` is the most generic constructor procedure, gives as output a tkGeneric transformation and the user has to specify direct and inverse transformation matrices.

Once you have initialized a transformation using one of the previously listed constructor procedures, you can simply get the inverse one by calling ```proc inverse*(transf: Transformation): Transformation``` which creates a new transformation consistently exchanging transformation matrices. 

To apply the transformations defined previously, it is possible to use the ```apply``` procedure, which plays a crucial role in the analysis of intersections between light rays and different objects. 
With the goal of having a high-performance ray tracer, we carried out some calculations explicitly in order to avoid doing a lot of useless multiplication such as in applying a scaling, which has a transformation matrix that has only the principal diagonal non zero.

```nim
proc apply*[T](transf: Transformation, x: T): T =
    case transf.kind
    of tkIdentity: return x

    of tkGeneric, tkRotation: 
        when T is Point3D: 
            return dot(transf.mat, x.toVec4).toPoint3D
        elif T is Normal:
            return dot(x, transf.matInv).toNormal
        else: 
            return dot(transf.mat, x) 

    of tkTranslation: 
        when T is Vec4f:
             return newVec4(x[0] + transf.mat[0][3] * x[3], x[1] + transf.mat[1][3] * x[3], x[2] + transf.mat[2][3] * x[3], x[3])
        elif T is Vec3:
            return newVec3(x[0], x[1], x[2])
        elif T is Point3D: 
            return newPoint3D(x.x + transf.mat[0][3], x.y + transf.mat[1][3], x.z + transf.mat[2][3])
        elif T is Normal:
            return newNormal(x.x, x.y, x.z)

    of tkScaling:
        when T is Vec4f:
            return newVec4(x[0] * transf.mat[0][0], x[1] * transf.mat[1][1], x[2] * transf.mat[2][2], x[3])
        elif T is Vec3:
            return newVec3(x[0] * transf.mat[0][0], x[1] * transf.mat[1][1], x[2] * transf.mat[2][2])
        elif T is Point3D: 
            return newPoint3D(x.x * transf.mat[0][0], x.y * transf.mat[1][1], x.z * transf.mat[2][2])
        elif T is Normal: 
            return x

    of tkComposition:
        if transf.transformations.len == 1: return apply(transf.transformations[0], x)

        when T is Normal:
            return dot(x, transf.transformations.mapIt(it.matInv).foldl(dot(a, b))).toNormal
        else:
            result = x
            for i in countdown(transf.transformations.len - 1, 0):
                result = apply(transf.transformations[i], result)
```
To make the application of a composition of transformations as efficient as possible, the individual transformations are applied in PhotoNim; instead of computing the composition matrix.

<div style="height: 25px;"></div>
<div style="text-align: left;">
    <span style="color: blue; font-size: 20px;"> Example </span>
</div>
<div style="height: 25px;"></div>

```nim
var
    t1 = newScaling(2.0)                        # Uniform scaling
    t2 = newRotX(90)                            # Rotation of PI/2
    t3 = newTranslation(newVec3(1, 2, 3))      # Translation of (1, 2, 3)
    comp: Transformation
    inv: Transformation

    v = newVec3(3, 2, 1)
    p = newPoint3D(3, 2, 1)


echo ' '
echo "Vector scaling: ", t1.apply(v)         # You should get (6, 4, 2)
echo "Point3D scaling: ", t1.apply(p)        # You should get (6, 4, 2)

echo ' '
echo "Vector rotation: ", t2.apply(v)        # You should get (3, -1, 2)
echo "Point3D rotation: ", t2.apply(p)       # You should get (3, -1, 2)

echo ' '
echo "Vector translation: ", t3.apply(v)        # You should get (3, 2, 1)
echo "Point3D translation: ", t3.apply(p)       # You should get (4, 4, 4)

comp = t1 @ t2  # Compose transformations
echo ' '
echo "Vector compound transformation: ", comp.apply(v)        # You should get (6, -2, 4)
echo "Point3D compound transformation: ", comp.apply(p)       # You should get (6, -2, 4)

inv = t1.inverse
echo ' '
echo "Vector inverse transformation: ", inv.apply(v)          # You should get (1.5, 1, 0.5)
echo "Point3D inverse transformation: ", inv.apply(p)         # You should get (1.5, 1, 0.5)
```

<div style="height: 40px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> Ray </span>
</div>
<div style="height: 40px;"></div>

PhotoNim is a backward ray tracer, meaning that we are tracing rays from the camera to the light sources.
The first tool we need to develop is indeed a type that allows us to uniquely characterize a ray:

```nim
type Ray* = ref object
    origin*: Point3D
    dir*: Vec3
    tSpan*: Interval[float32]
    depth*: int
```

To describe a light ray, we need to specify the point where it was emitted and the direction of propagation.
We also provide the temporal limits of the ray's propagation and the number of reflections it has undergone within the simulated region.
It's possible to inizialize a ```Ray``` variable by means of ```newRay``` proc.
It's fundamental to 
The following feature is fundamental to be able to apply generic transformations to the ray, because  it's needed in order to evaluate intersections with shapes in their local reference system.

```nim
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
```

If you want to evaluate ray position at a certain time t, you just have to use ```at``` procedure.

<div style="height: 25px;"></div>
<div style="text-align: left;">
    <span style="color: blue; font-size: 20px;"> Example </span>
</div>
<div style="height: 25px;"></div>

```nim
let
    trans = newTranslation(newVec3(2, 0, 0))
    rotY = newRotY(90)

var 
    origin = ORIGIN3D        # Ray starting point
    dir = newVec3(1, 0, 0)     # Ray direction (along x-axis)
    ray = newRay(origin, dir)           # tSpan and depth have default values

# Printing ray variable content
echo ' '
echo "Ray variable: "
echo $ray

# Translating ray
echo ' '
echo "Ray origin (translated): ", ray.transform(trans).origin   # You should see [2, 0, 0]
echo "Ray direction (translated): ", ray.transform(trans).dir   # You should see [1, 0, 0]

# Rotating ray
echo ' '
echo "Ray origin (rotated): ", ray.transform(rotY).origin   # You should see [0, 0, 0]
echo "Ray direction (rotated): ", ray.transform(rotY).dir   # You should see [0, 0, -1]


# Checking ray position at unitary time
# Ray is starting in (0, 0, 0) and propagating in (1, 0, 0)
echo ' '
echo "Ray position at t = 1: ", ray.at(1)      # You should see [1, 0, 0]
```

<div style="height: 40px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> ONB </span>
</div>
<div style="height: 40px;"></div>

So far, we have defined geometric constructs that enable us to work with shapes and describe the propagation of rays, but we have yet to address the problem of ray diffusion after a ray-scenery intersection. 
In order to scatter rays we will need to have an orthonormal base in order to define a local reference system.
An important block of code is ```newONB``` proc, which creates an ONB when a normal is given as input using the [_Duff et al. algorithm_](https://graphics.pixar.com/library/OrthonormalB/paper.pdf).
This particoular proc return a Mat3f, whose rows are the basis vectors.

```nim
proc newONB*(normal: Normal): Mat3f = 
    let
        sign = copySign(1.0, normal.z)
        a = -1.0 / (sign + normal.z)
        b = a * normal.x * normal.y
        
    [
        newVec3(1.0 + sign * a * normal.x * normal.x, sign * b, -sign * normal.x),
        newVec3(b, sign + a * normal.y * normal.y, -normal.y),
        normal.Vec3
    ]
```

The last given matrix row is the surface normal in the intersection point.
This procedure is tested by means of a method known as random testing: what we are doing in the following code block is generating randomly 1000 ONB and actually checking if ONB properties are verified or not.

```nim
    test "ONB random testing":
        # Checking Duff et al. algorithm
        # We are gonna random test it, so we will check random normals as input
        var 
            pcg = newPCG()
            normal: Normal  


        for i in 0..<1000:
            normal = newNormal(pcg.rand, pcg.rand, pcg.rand).normalize
            onb = newONB(normal)

            check areClose(onb[2], normal.Vec3)

            check areClose(dot(onb[0], onb[1]), 0, eps = 1e-6)
            check areClose(dot(onb[1], onb[2]), 0, eps = 1e-6)
            check areClose(dot(onb[2], onb[0]), 0, eps = 1e-6)

            check areClose(onb[0].norm, 1, eps = 1e-6)
            check areClose(onb[1].norm, 1, eps = 1e-6)
            check areClose(onb[2].norm, 1, eps = 1e-6)
```
