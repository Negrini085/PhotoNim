import geometry, hdrimage, material

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