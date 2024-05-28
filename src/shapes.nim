import geometry, camera

from std/strformat import fmt
from std/sequtils import map
from std/math import sgn, floor, arccos, arctan2, PI

type
    AABB* = Interval[Point3D]

proc newAABB*(points: openArray[Point3D]): AABB =
    if points.len == 1: return (points[0], points[0])

    let 
        x = points.map(proc(pt: Point3D): float32 = pt.x) 
        y = points.map(proc(pt: Point3D): float32 = pt.y)
        z = points.map(proc(pt: Point3D): float32 = pt.z)

    (min: newPoint3D(x.min, y.min, z.min), max: newPoint3D(x.max, y.max, z.max))


type
    ShapeKind* = enum
        skAABox, skTriangle, skSphere, skPlane, skCylinder
        
    Shape* = object
        transform*: Transformation # this should be a ref or ptr

        material*: Material

        case kind*: ShapeKind 
        of skAABox: 
            aabb*: AABB

        of skTriangle: 
            vertices*: array[3, Point3D]            

        of skSphere:
            radius*: float32

        of skCylinder:
            R*, zMin*, zMax*, phiMax*: float32

        of skPlane: discard


proc newAABox*(min = ORIGIN3D, max = newPoint3D(1, 1, 1), material = newMaterial(), transform = IDENTITY): Shape {.inline.} =
    Shape(kind: skAABox, material: material, aabb: newInterval(min, max), transform: transform)

proc newAABox*(aabb: AABB, material = newMaterial(), transform = IDENTITY): Shape {.inline.} =
    Shape(kind: skAABox, material: material, aabb: aabb, transform: transform)


proc getAABox*(shape: Shape): Shape {.inline.} =
    case shape.kind
    of skAABox: 
        return shape
    of skTriangle: 
        return newAABox(newAABB(shape.vertices), transform = shape.transform)
    of skSphere: 
        return newAABox(newPoint3D(-shape.radius, -shape.radius, -shape.radius), newPoint3D(shape.radius, shape.radius, shape.radius), transform = shape.transform)
    of skCylinder: 
        return newAABox(newPoint3D(-shape.R, -shape.R, shape.zMin), newPoint3D(shape.R, shape.R, shape.zMax), transform = shape.transform)
    of skPlane: 
        return newAABox(newPoint3D(-Inf, -Inf, -Inf), newPoint3D(Inf, Inf, Inf), transform = shape.transform)


proc getVertices*(shape: Shape): seq[Point3D] = 
    case shape.kind
    of skTriangle:
        return shape.vertices[0..^1]
    of skAABox:
        return @[
            shape.aabb.min, shape.aabb.max,
            newPoint3D(shape.aabb.min.x, shape.aabb.min.y, shape.aabb.max.z),
            newPoint3D(shape.aabb.min.x, shape.aabb.max.y, shape.aabb.min.z),
            newPoint3D(shape.aabb.min.x, shape.aabb.max.y, shape.aabb.max.z),
            newPoint3D(shape.aabb.max.x, shape.aabb.min.y, shape.aabb.min.z),
            newPoint3D(shape.aabb.max.x, shape.aabb.min.y, shape.aabb.max.z),
            newPoint3D(shape.aabb.max.x, shape.aabb.max.y, shape.aabb.min.z),
        ]
    else: 
        return shape.getAABox.getVertices


proc getTransformedVertices*(shape: Shape): seq[Point3D] {.inline.} = 
    shape.getVertices.map(proc(pt: Point3D): Point3D = apply(shape.transform, pt))
    

proc getWorldAABB*(shape: Shape): AABB {.inline.} =
    case shape.kind
    of skAABox, skTriangle, skCylinder: return newAABB(shape.getTransformedVertices)

    of skSphere: 
        let center = apply(shape.transform, ORIGIN3D)
        let radiusPt = newVec3f(shape.radius, shape.radius, shape.radius)
        return newInterval(center - radiusPt, center + radiusPt)

    of skPlane: return newInterval(apply(shape.transform, newPoint3D(-Inf, -Inf, -Inf)), apply(shape.transform, newPoint3D(Inf, Inf, Inf)))


proc newAABB*(shapes: openArray[Shape]): AABB =
    if shapes.len == 0: return (ORIGIN3D, ORIGIN3D)
    result = (min: newPoint3D(Inf, Inf, Inf), max: newPoint3D(-Inf, -Inf, -Inf))
    
    for shape in shapes:
        let aabb = shape.getWorldAABB
        result = newInterval(newInterval(aabb.min, result.min).min, newInterval(aabb.max, result.max).max)

proc getWorldAABox*(shape: Shape): Shape {.inline.} = newAABox(shape.getWorldAABB)


proc newSphere*(center: Point3D, radius: float32; material = newMaterial()): Shape {.inline.} =   
    Shape(
        kind: skSphere,
        transform: if center != ORIGIN3D: newTranslation(center.Vec3f) else: IDENTITY,
        material: material,
        radius: radius
    )

proc newUnitarySphere*(center: Point3D; material = newMaterial()): Shape {.inline.} = 
    Shape(
        kind: skSphere,
        transform: if center != ORIGIN3D: newTranslation(center.Vec3f) else: IDENTITY, 
        material: material,
        radius: 1.0
    )

proc newTriangle*(a, b, c: Point3D; transform = IDENTITY, material = newMaterial()): Shape {.inline.} = 
    Shape(
        kind: skTriangle, 
        transform: transform,
        material: material,
        vertices: [a, b, c]
    )

proc newTriangle*(vertices: array[3, Point3D]; transform = IDENTITY, material = newMaterial()): Shape {.inline.} = 
    Shape(
        kind: skTriangle, 
        transform: transform,
        material: material,
        vertices: vertices
    )

proc newPlane*(transform = IDENTITY, material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skPlane, transform: transform, material: material)

proc newCylinder*(r: float32 = 1.0, z_min: float32 = 0.0, z_max: float32 = 1.0, phi_max: float32 = 2.0 * PI; 
                    transform = IDENTITY, material = newMaterial()): Shape {.inline.} =
    Shape(
        kind: skCylinder,
        transform: transform,
        material: material,
        R: r, zMin: z_min, zMax: z_max, phiMax: phi_max
    )


proc uv*(shape: Shape; pt: Point3D): Point2D = 
    case shape.kind
    of skAABox:
        if pt.x == shape.aabb.min.x: 
            return newPoint2D((pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.x == shape.aabb.max.x: 
            return newPoint2D((pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.y == shape.aabb.min.y: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.y == shape.aabb.max.y: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.z - shape.aabb.min.z) / (shape.aabb.max.z - shape.aabb.min.z))
        elif pt.z == shape.aabb.min.z: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y))
        elif pt.z == shape.aabb.max.z: 
            return newPoint2D((pt.x - shape.aabb.min.x) / (shape.aabb.max.x - shape.aabb.min.x), (pt.y - shape.aabb.min.y) / (shape.aabb.max.y - shape.aabb.min.y))
        else:
            return newPoint2D(0, 0)

    of skTriangle:
        let 
            (x_ptA, x_BA, x_CA) = ((pt.x - shape.vertices[0].x), (shape.vertices[1].x - shape.vertices[0].x), (shape.vertices[2].x - shape.vertices[0].x))
            (y_ptA, y_BA, y_CA) = ((pt.y - shape.vertices[0].y), (shape.vertices[1].y - shape.vertices[0].y), (shape.vertices[2].y - shape.vertices[0].y))
            (u_num, u_den) = (x_ptA * y_CA - y_ptA * x_CA, xBA * y_CA - y_BA * x_CA)
            (v_num, v_den) = (x_ptA * y_BA - y_ptA * xBA, x_CA * y_BA - y_CA * xBA)
        return newPoint2D(u_num / u_den, v_num / v_den)
        
    of skSphere:
        var u = arctan2(pt.y, pt.x) / (2 * PI)
        if u < 0.0: u += 1.0
        return newPoint2D(u, arccos(pt.z) / PI)

    of skCylinder:
        var phi = arctan2(pt.y, pt.x)
        if phi < 0.0: phi += 2.0 * PI
        return newPoint2D(phi / shape.phiMax, (pt.z - shape.zMin) / (shape.zMax - shape.zMin))

    of skPlane: 
        return newPoint2D(pt.x - floor(pt.x), pt.y - floor(pt.y))


proc normal*(shape: Shape; pt: Point3D, dir: Vec3f): Normal = 
    case shape.kind
    of skAABox:
        if   areClose(pt.x, shape.aabb.min.x, 1e-6) or areClose(pt.x, shape.aabb.max.x, 1e-6): result = newNormal(1, 0, 0)
        elif areClose(pt.y, shape.aabb.min.y, 1e-6) or areClose(pt.y, shape.aabb.max.y, 1e-6): result = newNormal(0, 1, 0)
        elif areClose(pt.z, shape.aabb.min.z, 1e-6) or areClose(pt.z, shape.aabb.max.z, 1e-6): result = newNormal(0, 0, 1)
        else: quit "Something went wrong in calculating the normal for an AABox."
        return sgn(-dot(result.Vec3f, dir)).float32 * result

    of skTriangle:
        let cross = cross((shape.vertices[1] - shape.vertices[0]).Vec3f, (shape.vertices[2] - shape.vertices[0]).Vec3f)
        return sgn(-dot(cross, dir)).float32 * cross.toNormal
        
    of skSphere: 
        return sgn(-dot(pt.Vec3f, dir)).float32 * newNormal(pt.x, pt.y, pt.z)

    of skCylinder:
        return newNormal(pt.x, pt.y, 0.0)

    of skPlane: 
        return newNormal(0, 0, sgn(-dir[2]).float32)


type 
    MeshKind* = enum
        mkTriangular, mkSquared

    Mesh* = object
        nodes*: seq[Point3D]
        edges*: seq[int]
        kind*: MeshKind


iterator items*(mesh: Mesh): Shape =
    case mesh.kind
    of mkTriangular: 
        for i in 0 ..< (mesh.edges.len div 3): 
            yield newTriangle(mesh.nodes[mesh.edges[i * 3]], mesh.nodes[mesh.edges[i * 3 + 1]], mesh.nodes[mesh.edges[i * 3 + 2]])    

    of mkSquared: discard


proc newMesh*(kind: MeshKind, nodes: seq[Point3D], edges: seq[int]; transform = IDENTITY): Mesh {.inline.} = 
    Mesh(kind: kind, nodes: if transform.kind == tkIdentity: nodes else: nodes.map(proc(pt: Point3D): Point3D = apply(transform, pt)), edges: edges)

proc newTriangularMesh*(nodes: seq[Point3D], edges: seq[int]; transform = IDENTITY): Mesh {.inline.} = 
    assert edges.len mod 3 == 0, fmt"Error in creating a triangular Mesh! The length of the edges sequence must be a multiple of 3."
    newMesh(mkTriangular, nodes, edges, transform)