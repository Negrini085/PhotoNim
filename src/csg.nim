import pcg, geometry, color, pigment, brdf, scene, shape

from std/streams import newFileStream, atEnd, readLine
from std/strutils import parseInt, parseFloat, isEmptyOrWhitespace, splitWhitespace, rsplit
from std/strformat import fmt
from std/sequtils import toSeq, mapIt


proc newCSGUnion*(localHandlers: seq[ObjectHandler], treeKind: TreeKind, maxShapesPerLeaf: int, rgSetUp: RandomSetUp; brdf: BRDF, emittedRadiance = newUniformPigment(BLACK), transformation = Transformation.id): ObjectHandler =    
    
    let root = newBVHNode(localHandlers.pairs.toSeq, treeKind.int, maxShapesPerLeaf, rgSetUp)

    ObjectHandler(
        kind: hkCSG, 
        brdf: brdf, emittedRadiance: emittedRadiance,
        transformation: transformation,
        aabb: newAABB root.aabb.getVertices.mapIt(apply(transformation, it)),
        csg: CSG(kind: csgkUnion, tree: (treeKind, maxShapesPerLeaf, root, localHandlers))
    )