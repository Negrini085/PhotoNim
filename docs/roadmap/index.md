---
layout: page
title: Roadmap
permalink: /roadmap/
nav_order: 2
has_children: true
---

In this section it will be explained the code written to build the PhotoNim RayTracer.


```nim
type
    AABB* = tuple[min, max: Point3D]

    ShapeKind* = enum
        skAABox, skTriangle, skSphere, skPlane, skTriangularMesh
        
    Shape* = object
        transf*: Transformation
        material*: Material
        aabb*: Option[AABB] = none(AABB)

        case kind*: ShapeKind 
        of skAABox: 
            min*, max*: Point3D

        of skTriangle: 
            vertices*: tuple[A, B, C: Point3D]            

        of skTriangularMesh:
            nodes*: seq[Point3D]
            triang*: seq[Vec3[int32]]

        of skSphere:
            center*: Point3D
            radius*: float32

        of skPlane: discard


    World* = object
        shapes*: seq[Shape]

        
type ImageTracer* = object
    image*: HdrImage
    camera*: Camera
    sideSamples: int
    rg: PCG
```