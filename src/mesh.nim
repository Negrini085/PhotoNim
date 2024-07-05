# import geometry, scene, shape, bvh



# proc newMesh*(source: string; transformation = Transformation.id, treeKind: TreeKind, maxShapesPerLeaf: int, rgState, rgSeq: uint64): ShapeHandler = 
#     let (nodes, edges) = loadMesh(source)
#     assert edges.len mod 3 == 0, fmt"Error in creating a skTriangularMesh! The length of the edges sequence must be a multiple of 3."
    
#     var triangles = newSeq[ShapeHandler](edges.len div 3)
#     for i in 0..<edges.len div 3: 
#         triangles[i] = newTriangle(nodes[edges[i * 3]], nodes[edges[i * 3 + 1]], nodes[edges[i * 3 + 2]])    

#     var rg = newPCG(rgState, rgSeq)
#     newShapeHandler(
#         Shape(
#             kind: skTriangularMesh, 
#             nodes: nodes, edges: edges, 
#             tree: newBVHNode(triangles, depth = 0, treeKind.int, maxShapesPerLeaf, rg), 
#         ), transformation
#     )

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