import geometry, camera

from std/math import sgn, floor, arccos, arctan2, PI

type
    AABB* = tuple[min, max: Point3D]

    ShapeKind* = enum
        skAABox, skTriangle, skSphere, skPlane, skTriangularMesh, skCylinder
        
    Shape* = object
        transform*: Transformation
        material*: Material

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

        of skCylinder:
            R*: float32
            limits*: tuple[zmin, zmax, phimax: float32]

        of skPlane: discard


    World* = object
        shapes*: seq[Shape]


proc newWorld*(): World {.inline.} = World(shapes: @[])


proc newAABox*(min = ORIGIN3D, max = newPoint3D(1, 1, 1); 
                transform = Transformation.id, material = newMaterial()): Shape {.inline.} =
    Shape(
        kind: skAABox, 
        transform: transform, 
        material: material,
        min: min, max: max
    )

proc newSphere*(center: Point3D, radius: float32; material = newMaterial()): Shape {.inline.} = 
    var transform = Transformation.id
    if center != ORIGIN3D: transform = newTranslation(center.Vec3f)
    if radius != 1.0: transform = transform @ newScaling(radius)
    Shape(
        kind: skSphere,
        transform: transform,
        material: material,
        center: center, radius: radius
    )

proc newUnitarySphere*(center: Point3D; material = newMaterial()): Shape {.inline.} = 
    Shape(
        kind: skSphere,
        transform: if center != ORIGIN3D: newTranslation(center.Vec3f) else: Transformation.id, 
        material: material,
        center: center, radius: 1.0
    )

proc newTriangle*(a, b, c: Point3D; transform = Transformation.id, material = newMaterial()): Shape {.inline.} = 
    Shape(
        kind: skTriangle, 
        transform: transform,
        material: material,
        vertices: (a, b, c)
    )

proc newPlane*(transform = Transformation.id, material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skPlane, transform: transform, material: material)

proc newCylinder*(r: float32 = 1.0, z_min: float32 = 0.0, z_max: float32 = 1.0, phi_max: float32 = 2.0 * PI; 
                    transform = Transformation.id, material = newMaterial()): Shape {.inline.} =
    Shape(
        kind: skCylinder,
        transform: transform,
        material: material,
        R: r, limits: (z_min, z_max, phi_max)
    )

proc newMesh*(nodes: seq[Point3D], triang: seq[Vec3[int32]], transform = Transformation.id, material = newMaterial()): Shape {.inline.} = 
    Shape(
        kind: skTriangularMesh,
        transform: transform,
        material: material,
        nodes: nodes,
        triang: triang
    )


proc uv*(shape: Shape; pt: Point3D): Point2D = 
    case shape.kind
    of skAABox:
        if   pt.x == 0: return newPoint2D((1 + pt.y) / 4, (1 + pt.z) / 3)
        elif pt.x == 1: return newPoint2D((3 + pt.x) / 4, (1 + pt.z) / 3)
        elif pt.y == 0: return newPoint2D((2 + pt.x) / 4, (1 + pt.z) / 3)
        elif pt.y == 1: return newPoint2D((1 - pt.x) / 4, (1 + pt.z) / 3)
        elif pt.z == 0: return newPoint2D((1 + pt.y) / 4, (1 - pt.x) / 3)
        elif pt.z == 1: return newPoint2D((1 + pt.y) / 4, (2 + pt.x) / 3)   

    of skTriangle:
        let 
            (x_ptA, x_BA, x_CA) = ((pt.x - shape.vertices.A.x), (shape.vertices.B.x - shape.vertices.A.x), (shape.vertices.C.x - shape.vertices.A.x))
            (y_ptA, y_BA, y_CA) = ((pt.y - shape.vertices.A.y), (shape.vertices.B.y - shape.vertices.A.y), (shape.vertices.C.y - shape.vertices.A.y))
            (u_num, u_den) = (x_ptA * y_CA - y_ptA * x_CA, xBA * y_CA - y_BA * x_CA)
            (v_num, v_den) = (x_ptA * y_BA - y_ptA * xBA, x_CA * y_BA - y_CA * xBA)
        return newPoint2D(u_num / u_den, v_num / v_den)

    of skTriangularMesh: discard
        
    of skSphere:
        var u = arctan2(pt.y, pt.x) / (2 * PI)
        if u < 0.0: u += 1.0
        return newPoint2D(u, arccos(pt.z) / PI)

    of skCylinder:
        var phi = arctan2(pt.y, pt.x)
        if phi < 0.0: phi += 2.0 * PI
        return newPoint2D(phi / shape.limits.phimax, (pt.z - shape.limits.zmin) / (shape.limits.zmax - shape.limits.zmin))

    of skPlane: 
        return newPoint2D(pt.x - floor(pt.x), pt.y - floor(pt.y))


proc normal*(shape: Shape; pt: Point3D, dir: Vec3f): Normal = 
    case shape.kind
    of skAABox:
        if   areClose(pt.x, shape.min.x, 1e-6) or areClose(pt.x, shape.max.x, 1e-6): result = newNormal(1, 0, 0)
        elif areClose(pt.y, shape.min.y, 1e-6) or areClose(pt.y, shape.max.y, 1e-6): result = newNormal(0, 1, 0)
        elif areClose(pt.z, shape.min.z, 1e-6) or areClose(pt.z, shape.max.z, 1e-6): result = newNormal(0, 0, 1)
        else: quit "Something went wrong in calculating the normal for an AABox."
        return sgn(-dot(result.Vec3f, dir)).float32 * result

    of skTriangle:
        let 
            (A, B, C) = shape.vertices
            cross = cross((B - A).Vec3f, (C - A).Vec3f)
        return sgn(-dot(cross, dir)).float32 * cross.toNormal
        
    of skTriangularMesh: discard

    of skSphere: 
        return sgn(-dot(pt.Vec3f, dir)).float32 * newNormal(pt.x, pt.y, pt.z)

    of skCylinder:
        return newNormal(pt.x, pt.y, 0.0)

    of skPlane: 
        return newNormal(0, 0, sgn(-dir[2]).float32)