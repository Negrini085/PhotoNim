import geometry, hdrimage, camera

from std/strformat import fmt
from std/sequtils import concat, apply, map, foldl, toSeq
from std/math import sgn, floor, arccos, arctan2, PI


type 
    Material* = object
        brdf*: BRDF
        radiance*: Pigment

    ShapeKind* = enum
        skAABox, skTriangle, skSphere, skPlane, skCylinder
        
    Shape* = ref object
        material*: Material

        case kind*: ShapeKind 
        of skAABox: 
            aabb*: Interval[Point3D]

        of skTriangle: 
            vertices*: array[3, Point3D]            

        of skSphere:
            radius*: float32

        of skCylinder:
            R*, phiMax*: float32
            zSpan*: Interval[float32]

        of skPlane: discard


proc newMaterial*(brdf = newDiffuseBRDF(), pigment = newUniformPigment(WHITE)): Material {.inline.} = 
    Material(brdf: brdf, radiance: pigment)


proc getAABB*(points: seq[Point3D]): Interval[Point3D] =
    if points.len == 1: return (points[0], points[0])

    let 
        x = points.map(proc(pt: Point3D): float32 = pt.x) 
        y = points.map(proc(pt: Point3D): float32 = pt.y)
        z = points.map(proc(pt: Point3D): float32 = pt.z)

    (newPoint3D(x.min, y.min, z.min), newPoint3D(x.max, y.max, z.max))


proc getVertices*(aabb: Interval[Point3D]): array[8, Point3D] =
    return [
        aabb.min, aabb.max,
        newPoint3D(aabb.min.x, aabb.min.y, aabb.max.z),
        newPoint3D(aabb.min.x, aabb.max.y, aabb.min.z),
        newPoint3D(aabb.min.x, aabb.max.y, aabb.max.z),
        newPoint3D(aabb.max.x, aabb.min.y, aabb.min.z),
        newPoint3D(aabb.max.x, aabb.min.y, aabb.max.z),
        newPoint3D(aabb.max.x, aabb.max.y, aabb.min.z),
    ]


proc getAABB*(shape: Shape): Interval[Point3D] {.inline.} =
    case shape.kind
    of skAABox: return shape.aabb
    of skTriangle: return shape.vertices.toSeq.getAABB
    of skSphere: return (newPoint3D(-shape.radius, -shape.radius, -shape.radius), newPoint3D(shape.radius, shape.radius, shape.radius))
    of skCylinder: return (newPoint3D(-shape.R, -shape.R, shape.zSpan.min), newPoint3D(shape.R, shape.R, shape.zSpan.max))
    of skPlane: return (newPoint3D(-Inf, -Inf, -Inf), newPoint3D(Inf, Inf, 0))
    
proc getVertices*(shape: Shape): seq[Point3D] {.inline.} = 
    case shape.kind
    of skTriangle: return shape.vertices.toSeq
    of skAABox: return shape.aabb.getVertices.toSeq
    else: return shape.getAABB.getVertices.toSeq
    

proc getUV*(shape: Shape; pt: Point3D): Point2D = 
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
        return newPoint2D(phi / shape.phiMax, (pt.z - shape.zSpan.min) / (shape.zSpan.max - shape.zSpan.min))

    of skPlane: 
        return newPoint2D(pt.x - floor(pt.x), pt.y - floor(pt.y))


proc getNormal*(shape: Shape; pt: Point3D, dir: Vec3f): Normal = 
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


proc newAABox*(min = ORIGIN3D, max = newPoint3D(1, 1, 1); material = newMaterial()): Shape {.inline.} =
    Shape(kind: skAABox, material: material, aabb: newInterval(min, max))

proc newAABox*(aabb: Interval[Point3D]; material = newMaterial()): Shape {.inline.} =
    Shape(kind: skAABox, material: material, aabb: aabb)

proc newSphere*(radius: float32; material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skSphere, material: material, radius: radius)

proc newUnitarySphere*(material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skSphere, material: material, radius: 1.0)

proc newTriangle*(a, b, c: Point3D; material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skTriangle, material: material, vertices: [a, b, c])

proc newTriangle*(vertices: array[3, Point3D]; material = newMaterial()): Shape {.inline.} = 
    Shape(kind: skTriangle, material: material, vertices: vertices)

proc newPlane*(material = newMaterial()): Shape {.inline.} = Shape(kind: skPlane, material: material)

proc newCylinder*(R = 1.0, zMin = 0.0, zMax = 1.0, phiMax = 2.0 * PI; material = newMaterial()): Shape {.inline.} =
    Shape(kind: skCylinder, material: material, R: R, zSpan: (zMin.float32, zMax.float32), phiMax: phiMax)


type
    MeshKind* = enum
        mkTriangular, mkSquared

    Mesh* = object
        kind*: MeshKind
        nodes*: seq[Point3D]
        edges*: seq[int]


proc newMesh*(kind: MeshKind, nodes: seq[Point3D], edges: seq[int]; transformation = Transformation): Mesh {.inline.} = 
    Mesh(kind: kind, nodes: if transformation.kind == tkIdentity: nodes else: nodes.map(proc(pt: Point3D): Point3D = apply(transformation, pt)), edges: edges)

iterator items*(mesh: Mesh): Shape =
    case mesh.kind
    of mkTriangular: 
        for i in 0..<(mesh.edges.len div 3): 
            yield newTriangle(mesh.nodes[mesh.edges[i * 3]], mesh.nodes[mesh.edges[i * 3 + 1]], mesh.nodes[mesh.edges[i * 3 + 2]])    

    of mkSquared: discard

proc newTriangularMesh*(nodes: seq[Point3D], edges: seq[int]; transformation = Transformation): Mesh {.inline.} = 
    assert edges.len mod 3 == 0, fmt"Error in creating a triangular Mesh! The length of the edges sequence must be a multiple of 3."
    newMesh(mkTriangular, nodes, edges, transformation)