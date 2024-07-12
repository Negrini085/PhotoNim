import geometry, pcg, hdrimage, pigment, brdf, scene, shape

from std/streams import newFileStream, atEnd, readLine
from std/strutils import parseInt, parseFloat, isEmptyOrWhitespace, splitWhitespace, rsplit
from std/strformat import fmt
from std/sequtils import toSeq, mapIt


proc loadMesh*(source: string): tuple[nodes: seq[Point3D], edges: seq[int]] = 
    var istream =
        try: newFileStream(source, fmRead)
        except: quit "Error: something happend while trying to read a texture. " & getCurrentExceptionMsg()

    while not istream.atEnd:

        var line = 
            try: istream.readLine 
            except: quit fmt"Error! Some failing happend while reading {source}."

        # I want to do further check only if we actually got something
        if not line.isEmptyOrWhitespace:
            let items = line.splitWhitespace.toSeq
            
            if items[0] == "v": result.nodes.add newPoint3D(items[1].parseFloat, items[2].parseFloat, items[3].parseFloat)
            elif items[0] == "f": 
                # We have only three indeces, so that we are defining only one triangular face
                if items.len == 4: 
                    # We want to have infos only regarding faces (we are going to discard normals and additional stuff)
                    result.edges.add items[1].rsplit('/')[0].parseInt - 1 
                    result.edges.add items[2].rsplit('/')[0].parseInt - 1
                    result.edges.add items[3].rsplit('/')[0].parseInt - 1

                else:
                    # Here we are triangulating non triangular meshes
                    for i in 0..items.len-4:
                        result.edges.add items[1].rsplit('/')[0].parseInt - 1 
                        result.edges.add items[2+i].rsplit('/')[0].parseInt - 1
                        result.edges.add items[3+i].rsplit('/')[0].parseInt - 1



proc newMesh*(source: string, treeKind: TreeKind, maxShapesPerLeaf: int, rgSetUp: RandomSetUp; brdf: BRDF, emittedRadiance = newUniformPigment(BLACK), transformation = Transformation.id): ObjectHandler =    
    let (nodes, edges) = loadMesh(source)
    var shapes = newSeq[ObjectHandler](edges.len div 3)

    for i in 0..<edges.len div 3: 
        shapes[i] = newTriangle(
            vertices = [nodes[edges[i * 3]], nodes[edges[i * 3 + 1]], nodes[edges[i * 3 + 2]]], 
            brdf, emittedRadiance, 
            transformation
        )
    
    let root = newBVHNode(shapes.pairs.toSeq, treeKind.int, maxShapesPerLeaf, rgSetUp)

    ObjectHandler(
        kind: hkMesh, 
        brdf: brdf, emittedRadiance: emittedRadiance,
        transformation: Transformation.id,
        mesh: (treeKind, maxShapesPerLeaf, root, shapes)
    )