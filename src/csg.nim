import pcg, geometry, scene

# from std/streams import newFileStream, atEnd, readLine
# from std/strutils import parseInt, parseFloat, isEmptyOrWhitespace, splitWhitespace, rsplit
# from std/strformat import fmt
from std/sequtils import toSeq, mapIt


proc newCSGUnion*(localHandlers: seq[ObjectHandler], treeKind: TreeKind, maxShapesPerLeaf: int, rgSetUp: RandomSetUp, transformation = Transformation.id): ObjectHandler  =    
    let tree = newBVHTree(localHandlers, treeKind, maxShapesPerLeaf, rgSetUp)

    ObjectHandler(
        kind: hkCSG, 
        aabb: newAABB tree.root.aabb.getVertices.mapIt(apply(transformation, it)),
        transformation: transformation,
        csg: CSG(kind: csgkUnion, tree: tree)
    )