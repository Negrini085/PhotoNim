import pcg, geometry, color, material

from std/sequtils import newSeqWith, toSeq, mapIt, keepItIf, filterIt


type    
    Scene* = object 
        ## `Scene` is an object that 
        bgColor*: Color ## Color of the background.
        tree*: BVHTree ## The BVH tree. 


    TreeKind* = enum 
        tkBinary = 2, tkTernary = 3, tkQuaternary = 4, tkOctonary = 8

    BVHTree* = object 
        ## `BVHTree` is an object that represents the Bounding Volume Hierarchy as a tree

        kind*: TreeKind ## The capacity of a branch `BVHNode`.
        mspl*: int ## The capacity of a leaf `BVHNode`.
        root*: BVHNode ## The root `BVHNode`.
        handlers*: seq[ObjectHandler] ## The `ObjectHandler`s contained in the tree.
        planeHandlers*: seq[ObjectHandler] ## Planes contained in scene


    NodeKind* = enum nkBranch, nkLeaf
    BVHNode* = ref object
        ## `BVHNode` is a ref object that

        aabb*: AABB ## `AABB` expressed in the `BVHTree` reference system.
        
        case kind*: NodeKind
        of nkBranch: children*: seq[BVHNode] ## `BVHNode` children of the branch. 
        of nkLeaf: indexes*: seq[int] ## Indexes of the `ObjectHandler`s inside `BVHTree`.


    HandlerKind* = enum hkShape, hkMesh, hkCSG
    ObjectHandler* = ref object
        ## `ObjectHandler` is a ref object that enable us to place a local figure, or more, into some other reference system based on the `Transformation` range.
        ## Every `ObjectHandler` stores information about its bounding box, in order to facilitate the procedure of building and traversing the `BVHTree`,
        ## but only the kind `hkShape` stores also an information about the `Material`: this is due to the fact that at base of any intersection with an `ObjectHandler`
        ## there is a local intersection between the `Shape` and the inverted `Ray`. 
        
        aabb*: AABB ## `AABB` expressed in the `BVHTree` reference system.
        transformation*: Transformation ## Map from local to `BVHTree` reference system.

        case kind*: HandlerKind
        of hkShape: 
            shape*: Shape 
            material*: Material ## The `material` of the shape.

        of hkMesh: 
            mesh*: BVHTree ## A mesh as a local `BVHTree`.

        of hkCSG: 
            csg*: CSG ## A CSG local type.
    
    
    ShapeKind* = enum skPlane, skSphere, skAABox, skTriangle, skCylinder, skEllipsoid
    Shape* = object
        ## `Shape` is an object that represents the most basic surfaces in 3D space and 
        ## it is the building block on which the intersection between a `Ray` and an `ObjectHandler` of any kind is based.
        ## In a `Scene` filled with `ObjectHandler` of any kind, all the `ObjectHandler` hit by a `Ray` are of kind `hkShape`: 
        ## in fact, to intersect an handler of kinds `hkMesh` or `hkCSG` we progressively advance with the search in their relative structure,
        ## which, at least at the very base, is build upon an `ObjectHandler` of kind `hkShape`.

        case kind*: ShapeKind 
        of skPlane: discard
        of skSphere: radius*: float32
        of skAABox: aabb*: AABB
        of skTriangle: vertices*: seq[Point3D]
        of skCylinder:
            R*, phiMax*: float32
            zSpan*: Interval[float32]

        of skEllipsoid: axis*: tuple[a, b, c: float32]

    CSGKind* = enum csgkUnion
    CSG* = object
        case kind*: CSGKind
        of csgkUnion:
            tree*: BVHTree


proc nearestCentroid(point: Point3D, clusterCentroids: seq[Point3D]): tuple[index: int, dist2: float32] =   
    result = (index: 0, dist2: Inf.float32)

    var tmp: float32
    for i, center in clusterCentroids.pairs:
        tmp = dist2(center, point)
        if result.dist2 > tmp: result = (i, tmp)


proc updateCentroids(data: seq[Point3D], clusters: seq[int], k: int): seq[Point3D] =
    result = newSeq[Point3D](k)

    var 
        tmp = newSeq[Vec3](k)
        counts = newSeq[int](k)
    for i, point in data.pairs: tmp[clusters[i]] += Vec3(point); counts[clusters[i]] += 1
    for i in 0..<k: result[i] = if counts[i] > 0: Point3D(tmp[i] / counts[i]) else: Point3D(tmp[i])


proc kMeansPlusPlusInit(data: seq[Point3D], k: int, rg: var PCG): seq[Point3D] =
    result = newSeq[Point3D](k)
    result[0] = data[rg.rand(0.float32, data.len.float32 - 1).int]

    var distances = newSeq[float32](data.len)
    for i in 1..<k:
        var totalDist: float32
        for j, point in data.pairs:
            distances[j] = nearestCentroid(point, result[0..<i]).dist2
            totalDist += distances[j]

        let target = rg.rand(0.0, totalDist)
        var cumulativeDist: float32
        for j, dist in distances.pairs:
            cumulativeDist += dist
            if cumulativeDist >= target: result[i] = data[j]; break


proc kMeans(data: seq[Point3D], k: int, rg: var PCG): seq[int] =
    if data.len == k: return countup(0, k - 1).toSeq

    result = newSeq[int](data.len)

    var 
        centroids = kMeansPlusPlusInit(data, k, rg)
        tmpCentroids = newSeq[Point3D](k)
        converged = false

    while not converged:
        result = data.mapIt(it.nearestCentroid(centroids).index)
        tmpCentroids = updateCentroids(data, result, k)
        converged = true
        for i in 0..<k:
            if not areClose(centroids[i], tmpCentroids[i], 1.0e-3):
                converged = false
                break

        centroids = tmpCentroids


proc newBVHNode*(handlers: seq[tuple[key: int, val: ObjectHandler]], kClusters, maxShapesPerLeaf: int, rgSetUp: RandomSetUp): BVHNode =
    ## Creates a new BVHNode for organizing a sequence of `ObjectHandler`s.
    ##
    ## Parameters:
    ## - `handlers`: `seq[tuple[key: int, val: ObjectHandler]]` -> A sequence of tuples containing indices and `ObjectHandler`s to be organized.
    ## - `kClusters`: `int` -> The number of clusters to use for splitting the handlers.
    ## - `maxShapesPerLeaf`: `int` -> The maximum number of shapes allowed in a leaf node.
    ## - `rgSetUp`: `RandomSetUp` -> Random setup parameters for initializing the node creation.
    ##
    ## Returns:
    ## - `BVHNode`: 
    ##      a `BVHNode` of kind `nkLeaf` is returned if the lenght of the `handlers` sequence is less than the `maxShapesPerLeaf`,
    ##      otherwise a `BVHNode` of kind `nkBranch`.
    ##      If the sequence is empty then a `nil` reference is returned. 

    if handlers.len == 0: return nil

    let handlersAABBs = handlers.mapIt(it.val.aabb)
    
    if handlers.len <= maxShapesPerLeaf:
        return BVHNode(kind: nkLeaf, aabb: handlersAABBs.getTotalAABB, indexes: handlers.mapIt(it.key))
    
    var 
        rg = newPCG(rgSetUp)
        clusters = newSeqWith[seq[int]](kClusters, newSeqOfCap[int](handlers.len div kClusters))

    for handlerIdx, clusterIdx in kMeans(handlersAABBs.mapIt(it.getCentroid), kClusters, rg).pairs: 
        clusters[clusterIdx].add handlerIdx

    clusters.keepItIf(it.len > 0)
    
    BVHNode(
        kind: nkBranch, 
        aabb: handlersAABBs.getTotalAABB,
        children: clusters.mapIt(
            newBVHNode(
                it.mapIt(handlers[it]), 
                kClusters, maxShapesPerLeaf, 
                newRandomSetUp(rg)
            )
        )      
    )


proc newBVHTree*(handlers: seq[ObjectHandler], treeKind: TreeKind, maxShapesPerLeaf: int, rgSetUp: RandomSetUp): BVHTree =
    ## Creates a new Bounding Volume Hierarchy (BVH) Tree for organizing `ObjectHandler`s inside a `Scene`.
    ##
    ## Parameters:
    ## - `handlers`: `seq[ObjectHandler]` -> A sequence of `ObjectHandler`s to be organized in the BVH tree.
    ## - `treeKind`: `TreeKind` -> The type of tree structure (binary, ternary, quaternary, or octonary).
    ## - `maxShapesPerLeaf`: `int` -> The maximum number of shapes allowed in a leaf node.
    ## - `rgSetUp`: `RandomSetUp` -> Random setup parameters for initializing the BVH tree using kmeans clustering.

    let hand = handlers.filterIt(it.kind != hkShape) & handlers.filterIt(it.kind == hkShape).filterIt(it.shape.kind != skPlane)
    BVHTree(
        kind: treeKind, 
        mspl: maxShapesPerLeaf, 
        root: newBVHNode(hand.pairs.toSeq, treeKind.int, maxShapesPerLeaf, rgSetUp), 
        handlers: hand,
        planeHandlers: handlers.filterIt(it.kind == hkShape).filterIt(it.shape.kind == skPlane)
    )


proc newScene*(bgColor: Color, handlers: seq[ObjectHandler], treeKind: TreeKind, maxShapesPerLeaf: int, rgSetUp: RandomSetUp): Scene {.inline.} =
    ## Creates a new `Scene` object with a specified background color, a sequence of `ObjectHandler`s, 
    ## and a BVH tree for efficient spatial organization.
    ##
    ## Parameters:
    ## - `bgColor`: `Color` -> The color of the scene's background.
    ## - `handlers`: `seq[ObjectHandler]` -> A sequence of `ObjectHandler`s to be included in the scene.
    ## - `treeKind`: `TreeKind` -> The type of tree structure (binary, ternary, quaternary, or octonary).
    ## - `maxShapesPerLeaf`: `int` -> The maximum number of shapes allowed in a leaf node of the BVH tree.
    ## - `rgSetUp`: `RandomSetUp` -> Random setup parameters for initializing the BVH tree.
    ##
    ## Raises:
    ## - `AssertionError` if the `handlers` sequence is empty.
    let msg = "Error! Cannot create a Scene from an empty sequence of ObjectHandlers which are not Planes."
    doAssert (handlers.filterIt(it.kind != hkShape) & handlers.filterIt(it.kind == hkShape).filterIt(it.shape.kind != skPlane)).len > 0, msg
    Scene(bgColor: bgColor, tree: newBVHTree(handlers, treeKind, maxShapesPerLeaf, rgSetUp))