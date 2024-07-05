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