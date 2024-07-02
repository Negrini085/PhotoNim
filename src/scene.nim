import geometry, hdrimage, material

from std/math import sgn, floor, arccos, arctan2, PI
# from std/streams import newFileStream, close, atEnd, readLine 
# from std/sequtils import concat, foldl, toSeq, filterIt, mapIt
# from std/strutils import isEmptyOrWhiteSpace, rsplit, splitWhitespace, parseFloat, parseInt
# from std/strformat import fmt
from std/sequtils import mapIt


type    
    Scene* = object 
        bgColor*: Color
        handlers*: seq[ObjectHandler]


    ObjectHandlerKind = enum hkShape, hkMesh
    ObjectHandler* = ref object
        transformation*: Transformation

        case kind*: ObjectHandlerKind
        of hkShape: 
            shape*: Shape 
        
        of hkMesh: 
            mesh*: Mesh


    ShapeKind* = enum skAABox, skTriangle, skSphere, skPlane, skCylinder
    Shape* = object
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


    Mesh* = ref object
        nodes*: seq[Point3D]
        edges*: seq[seq[int]]
        tree*: BVHNode


    BVHNodeKind* = enum nkBranch, nkLeaf
    BVHNode* = ref object
        aabb*: Interval[Point3D]
        
        case kind*: BVHNodeKind
        of nkBranch:
            children*: seq[BVHNode]
        
        of nkLeaf:
            handlers*: seq[ObjectHandler]


proc newScene*(handlers: seq[ObjectHandler], bgColor: Color = BLACK): Scene {.inline.} = 
    Scene(bgColor: bgColor, handlers: handlers)
    

proc newAABB*(points: seq[Point3D]): Interval[Point3D] =
    if points.len == 1: return (points[0], points[0])

    let 
        x = points.mapIt(it.x) 
        y = points.mapIt(it.y)
        z = points.mapIt(it.z)

    (newPoint3D(x.min, y.min, z.min), newPoint3D(x.max, y.max, z.max))

# method getAABB*(obj: HittableObject): Interval[Point3D] {.base.} = quit "to implement"

# proc loadMesh*(source: string): tuple[nodes: seq[Point3D], edges: seq[int]] = 
#     var istream = newFileStream(source, fmRead)

#     if istream.isNil: quit fmt"Error! Cannot open file {source}."

#     while not istream.atEnd:

#         var line = 
#             try: istream.readLine 
#             except: quit fmt"Error! Some failing happend while reading {source}."

#         # I want to do further check only if we actually got something
#         if not line.isEmptyOrWhitespace:
#             let items = line.splitWhitespace.toSeq
            
#             if items[0] == "v": result.nodes.add newPoint3D(items[1].parseFloat, items[2].parseFloat, items[3].parseFloat)
#             elif items[0] == "f": 
#                 # We have only three indeces, so that we are defining only one triangular face
#                 if items.len == 4: 
#                     # We want to have infos only regarding faces (we are going to discard normals and additional stuff)
#                     result.edges.add items[1].rsplit('/')[0].parseInt - 1 
#                     result.edges.add items[2].rsplit('/')[0].parseInt - 1
#                     result.edges.add items[3].rsplit('/')[0].parseInt - 1

#                 else:
#                     # Here we are triangulating non triangular meshes
#                     for i in 0..items.len-4:
#                         result.edges.add items[1].rsplit('/')[0].parseInt - 1 
#                         result.edges.add items[2+i].rsplit('/')[0].parseInt - 1
#                         result.edges.add items[3+i].rsplit('/')[0].parseInt - 1


# proc loadTexture*(world: Scene, source: string, shape: Shape) = quit "to implement"


proc newShapeHandler(shape: Shape, transformation = Transformation.id): ObjectHandler {.inline.} =
    ObjectHandler(kind: hkShape, shape: shape, transformation: transformation)

proc newSphere*(center: Point3D, radius: float32; material = newMaterial()): ObjectHandler {.inline.} =   
    newShapeHandler(Shape(kind: skSphere, material: material, radius: radius), if center != ORIGIN3D: newTranslation(center) else: Transformation.id)

proc newUnitarySphere*(center: Point3D; material = newMaterial()): ObjectHandler {.inline.} = 
    newShapeHandler(Shape(kind: skSphere, material: material, radius: 1.0), if center != ORIGIN3D: newTranslation(center) else: Transformation.id)

proc newPlane*(material = newMaterial(), transformation = Transformation.id): ObjectHandler {.inline.} = 
    newShapeHandler(Shape(kind: skPlane, material: material), transformation)

proc newBox*(aabb: Interval[Point3D], material = newMaterial(), transformation = Transformation.id): ObjectHandler {.inline.} =
    newShapeHandler(Shape(kind: skAABox, aabb: aabb, material: material), transformation)

proc newTriangle*(a, b, c: Point3D; material = newMaterial(), transformation = Transformation.id): ObjectHandler {.inline.} = 
    newShapeHandler(Shape(kind: skTriangle, material: material, vertices: [a, b, c]), transformation)

proc newTriangle*(vertices: array[3, Point3D]; material = newMaterial(), transformation = Transformation.id): ObjectHandler {.inline.} = 
    newShapeHandler(Shape(kind: skTriangle, material: material, vertices: vertices), transformation)

proc newCylinder*(R = 1.0, zMin = 0.0, zMax = 1.0, phiMax = 2.0 * PI; material = newMaterial(), transformation = Transformation.id): ObjectHandler {.inline.} =
    newShapeHandler(Shape(kind: skCylinder, material: material, R: R, zSpan: (zMin.float32, zMax.float32), phiMax: phiMax), transformation)

