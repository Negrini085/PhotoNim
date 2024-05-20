---
layout: page
title: Geometry
parent: Roadmap
permalink: /roadmap/geometry/
nav_order: 0
---

# PhotoNim Geometry submodule

## Vector Type
```nim
type Vec*[N: static[int], V] = array[N, V]

proc newVec*[N: static[int], V](data: array[N, V]): Vec[N, V] {.inline.} = result = data
```

```nim
type 
    Vec2*[V] = Vec[2, V]
    Vec3*[V] = Vec[3, V]
    Vec4*[V] = Vec[4, V]
    Vec2f* = Vec2[float32]
    Vec3f* = Vec3[float32]
    Vec4f* = Vec4[float32]

proc newVec2*[V](x, y: V): Vec2[V] {.inline.} = newVec([x, y])
proc newVec3*[V](x, y, z: V): Vec3[V] {.inline.} = newVec([x, y, z])
proc newVec4*[V](x, y, z, w: V): Vec4[V] {.inline.} = newVec([x, y, z, w])
```

```nim
template VecVecToVecOp(op: untyped) =
    proc op*[N: static[int], V](a, b: Vec[N, V]): Vec[N, V] {.inline.} =
        for i in 0..<N: result[i] = op(a[i], b[i])

VecVecToVecOp(`+`)
VecVecToVecOp(`-`)
```

```nim
ScalVecToVecOp(`*`)
VecScalToVecOp(`*`)
VecScalToVecOp(`/`)

VecVecIncrOp(`+=`)
VecVecIncrOp(`-=`)

VecScalIncrOp(`*=`)
VecScalIncrOp(`/=`)
```


```nim
proc dot*[N: static[int], V](a, b: Vec[N, V]): V {.inline.} = 
    for i in 0..<N: result += a[i] * b[i]

proc norm2*[N: static[int], V](a: Vec[N, V]): V {.inline.} = dot(a, a)
proc norm*[N: static[int], V](a: Vec[N, V]): float32 {.inline.} = sqrt(dot(a, a))

proc dist2*[N: static[int], V](`from`, to: Vec[N, V]): V {.inline.} = (`from` - to).norm2
proc dist*[N: static[int], V](`from`, to: Vec[N, V]): float32 {.inline.} = (`from` - to).norm

proc normalize*[N: static[int], V](a: Vec[N, V]): Vec[N, V] {.inline.} = a / a.norm
proc dir*[N: static[int], V](at, to: Vec[N, V]): Vec[N, V] {.inline.} = (at - to).normalize
```


## Distinct Vector Types
```nim
type
    Point2D* {.borrow: `.`.} = distinct Vec2f
    Point3D* {.borrow: `.`.} = distinct Vec3f
    Normal* {.borrow: `.`.} = distinct Vec3f

proc newPoint2D*(u, v: float32): Point2D {.inline.} = Point2D([u, v]) 
proc newPoint3D*(x, y, z: float32): Point3D {.inline.} = Point3D([x, y, z])
proc newNormal*(x, y, z: float32): Normal {.inline.} = Normal([x, y, z])
```