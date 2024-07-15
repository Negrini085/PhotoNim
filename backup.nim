#---------------------------#
#    CSGUnion test suite    #
#---------------------------# 
suite "CSGUnion":

    setup:
        let 
            brdf = newDiffuseBRDF(newUniformPigment(WHITE))
            pigm = newUniformPigment(WHITE)

            tr = newTranslation(eX)
            comp = newComposition(newRotation(90, axisX), newTranslation(eY))
            
            sph1 = newSphere(newPoint3D(1, 2, 3), 2, brdf, pigm)
            spSh2 = newSphere(newPoint3D(-1, -2, -3), 2, brdf, pigm)
            triSh = newTriangle([eX.Point3D, eY.Point3D, eZ.Point3D], brdf, pigm, transformation = comp)
            
            csgUnion1 = newCSGUnion(sph1, triSh, brdf, pigm, tr)
            csgUnion2 = newCSGUnion(csgUnion1, spSh2, brdf, pigm)
    
    teardown:
        discard tr
        discard comp
        discard brdf
        discard pigm
        discard sph1
        discard spSh2
        discard triSh
        discard csgUnion1
        discard csgUnion2
    
    
    test "newCSGUnion proc":
        # Checking newCSGUnion proc

        #------------------------------------#
        #          First CSGUnion            #
        #------------------------------------#  
        check csgUnion1.shape.kind == skCSGUnion
        check csgUnion1.transformation.kind == tkTranslation
        check areClose(csgUnion1.transformation.offset, eX)

        # Checking first shape
        check csgUnion1.shape.primary.shape.kind == skSphere
        check csgUnion1.shape.primary.shape.radius == 2

        check csgUnion1.shape.primary.transformation.kind == tkTranslation
        check areClose(csgUnion1.shape.primary.transformation.offset, newVec3f(1, 2, 3))

        # Checking second shape
        check csgUnion1.shape.secondary.shape.kind == skTriangle
        check csgUnion1.shape.secondary.shape.vertices[0] == eX.Point3D
        check csgUnion1.shape.secondary.shape.vertices[1] == eY.Point3D
        check csgUnion1.shape.secondary.shape.vertices[2] == eZ.Point3D

        check csgUnion1.shape.secondary.transformation.kind == tkComposition
        check csgUnion1.shape.secondary.transformation.transformations[0].kind == tkRotation
        check csgUnion1.shape.secondary.transformation.transformations[1].kind == tkTranslation
        
        check csgUnion1.shape.secondary.transformation.transformations[0].axis == axisX
        check areClose(csgUnion1.shape.secondary.transformation.transformations[0].cos, newRotation(90, axisX).cos, eps = 1e-6)
        check areClose(csgUnion1.shape.secondary.transformation.transformations[0].sin, newRotation(90, axisX).sin, eps = 1e-6)
        check areClose(csgUnion1.shape.secondary.transformation.transformations[1].offset, eY)


        #-------------------------------------#
        #          Second CSGUnion            #
        #-------------------------------------#
        check csgUnion2.shape.kind == skCSGUnion
        check csgUnion2.transformation.kind == tkIdentity
        
        # Checking first shape
        check csgUnion2.shape.primary.shape.kind == skCSGUnion
        check csgUnion2.shape.primary.shape.primary.shape.kind == skSphere
        check csgUnion2.shape.primary.shape.secondary.shape.kind == skTriangle

        check csgUnion2.shape.primary.transformation.kind == tkTranslation
        check areClose(csgUnion2.shape.primary.transformation.offset, eX) 

        check csgUnion2.shape.primary.shape.primary.transformation.kind == tkTranslation
        check csgUnion2.shape.primary.shape.secondary.transformation.kind == tkComposition
        check csgUnion2.shape.primary.shape.secondary.transformation.transformations[0].kind == tkRotation
        check csgUnion2.shape.primary.shape.secondary.transformation.transformations[1].kind == tkTranslation
        check areClose(csgUnion2.shape.primary.shape.primary.transformation.offset, newVec3f(1, 2, 3))  
        check csgUnion2.shape.primary.shape.secondary.transformation.transformations[0].axis == axisX
        check areClose(csgUnion2.shape.primary.shape.secondary.transformation.transformations[0].cos, 0)
        check areClose(csgUnion2.shape.primary.shape.secondary.transformation.transformations[0].sin, 1)
        check areClose(csgUnion2.shape.primary.shape.secondary.transformation.transformations[1].offset, eY)  
        
        check csgUnion2.shape.primary.transformation.kind == tkTranslation
        check areClose(csgUnion2.shape.primary.transformation.offset, eX)  

        # Checking second shape
        check csgUnion2.shape.secondary.shape.kind == skSphere
        check csgUnion2.shape.primary.shape.primary.shape.kind == skSphere
        check csgUnion2.shape.primary.shape.secondary.shape.kind == skTriangle

        check csgUnion2.shape.secondary.transformation.kind == tkTranslation
        check areClose(csgUnion2.shape.secondary.transformation.offset, newVec3f(-1, -2, -3))  


    test "getAABB (Local) proc":
        # Gives aabb for a csgUnion shape in local reference system
        let 
            aabb1 = getAABB(csgUnion1.shape)
            aabb2 = getAABB(csgUnion2.shape)

        check areClose(aabb1.min, newPoint3D(-1,-1, 1), eps = 1e-6)
        check areClose(aabb1.max, newPoint3D( 3, 4, 5), eps = 1e-6)

        check areClose(aabb2.min, newPoint3D(-3,-4,-5), eps = 1e-6)
        check areClose(aabb2.max, newPoint3D( 4, 4, 5), eps = 1e-6)


    test "getVertices (Local) proc":
        # Gives vertices for all aabb being a part of CSGUnion shape, in "shape reference system".
        # We are not accounting for handler transformation
        let     
            aabb1 = csgUnion1.shape.getAABB
            aabb2 = csgUnion2.shape.getAABB

            vert1 = getVertices(aabb1)
            vert2 = getVertices(aabb2)
    
        # First CSGUnion
        check areClose(vert1[0], aabb1.min)
        check areClose(vert1[1], aabb1.max)
        check areClose(vert1[2], newPoint3D(-1,-1, 5))
        check areClose(vert1[3], newPoint3D(-1, 4, 1))
        check areClose(vert1[4], newPoint3D(-1, 4, 5))
        check areClose(vert1[5], newPoint3D( 3,-1, 1))
        check areClose(vert1[6], newPoint3D( 3,-1, 5))
        check areClose(vert1[7], newPoint3D( 3, 4, 1))


        # Second CSGUnion
        check areClose(vert2[0], aabb2.min)
        check areClose(vert2[1], aabb2.max)
        check areClose(vert2[2], newPoint3D(-3,-4, 5))
        check areClose(vert2[3], newPoint3D(-3, 4,-5))
        check areClose(vert2[4], newPoint3D(-3, 4, 5))
        check areClose(vert2[5], newPoint3D( 4,-4,-5))
        check areClose(vert2[6], newPoint3D( 4,-4, 5))
        check areClose(vert2[7], newPoint3D( 4, 4,-5))
    

    test "getAABB (World) proc":
        # Gives aabb for a csgUnion shape in world reference system
        let
            aabb1 = csgUnion1.aabb
            aabb2 = csgUnion2.aabb

        check areClose(aabb1.min, newPoint3D(0, -1, 1), eps = 1e-6)
        check areClose(aabb1.max, newPoint3D(4, 4, 5), eps = 1e-6)

        check areClose(aabb2.min, newPoint3D(-3, -4, -5), eps = 1e-6)
        check areClose(aabb2.max, newPoint3D(4, 4, 5), eps = 1e-6)



#---------------------------#
#     CSGInt test suite     #
#---------------------------# 
suite "CSGInt":

    setup:
        let 
            brdf = newDiffuseBRDF(newUniformPigment(WHITE))
            pigm = newUniformPigment(WHITE)

            tr = newTranslation(eX)
            comp = newComposition(newRotation(90, axisX), newTranslation(eY))
            
            sph1 = newSphere(newPoint3D(1, 2, 3), 2, brdf, pigm)
            spSh2 = newSphere(newPoint3D(-1, -2, -3), 2, brdf, pigm)
            triSh = newTriangle([eX.Point3D, eY.Point3D, eZ.Point3D], brdf, pigm, transformation = comp)
            
            csgInt1 = newCSGInt(sph1, triSh, brdf, pigm, tr)
            csgInt2 = newCSGInt(csgInt1, spSh2, brdf, pigm)
    
    teardown:
        discard tr
        discard comp
        discard brdf
        discard pigm
        discard sph1
        discard spSh2
        discard triSh
        discard csgInt1
        discard csgInt2
    
    
    test "newCSGInt proc":
        # Checking newCSGInt proc

        #----------------------------------#
        #          First CSGInt            #
        #----------------------------------#      
        check csgInt1.shape.kind == skCSGInt
        check csgInt1.transformation.kind == tkTranslation
        check areClose(csgInt1.transformation.offset, eX)
      
        # Checking first shape
        check csgInt1.shape.primary.shape.kind == skSphere
        check csgInt1.shape.primary.shape.radius == 2

        check csgInt1.shape.primary.transformation.kind == tkTranslation
        check areClose(csgInt1.shape.primary.transformation.offset, newVec3f(1, 2, 3))

        # Checking second shape
        check csgInt1.shape.secondary.shape.kind == skTriangle
        check csgInt1.shape.secondary.shape.vertices[0] == eX.Point3D
        check csgInt1.shape.secondary.shape.vertices[1] == eY.Point3D
        check csgInt1.shape.secondary.shape.vertices[2] == eZ.Point3D

        check csgInt1.shape.secondary.transformation.kind == tkComposition
        check csgInt1.shape.secondary.transformation.transformations[0].kind == tkRotation
        check csgInt1.shape.secondary.transformation.transformations[1].kind == tkTranslation
        
        check csgInt1.shape.secondary.transformation.transformations[0].axis == axisX
        check areClose(csgInt1.shape.secondary.transformation.transformations[0].cos, newRotation(90, axisX).cos, eps = 1e-6)
        check areClose(csgInt1.shape.secondary.transformation.transformations[0].sin, newRotation(90, axisX).sin, eps = 1e-6)
        check areClose(csgInt1.shape.secondary.transformation.transformations[1].offset, eY)


        #-----------------------------------#
        #          Second CSGInt            #
        #-----------------------------------#
        check csgInt2.shape.kind == skCSGInt
        check csgInt2.transformation.kind == tkIdentity 

        # Checking first shape
        check csgInt2.shape.primary.shape.kind == skCSGInt
        check csgInt2.shape.primary.shape.primary.shape.kind == skSphere
        check csgInt2.shape.primary.shape.secondary.shape.kind == skTriangle

        check csgInt2.shape.primary.transformation.kind == tkTranslation
        check areClose(csgInt2.shape.primary.transformation.offset, eX) 

        check csgInt2.shape.primary.shape.primary.transformation.kind == tkTranslation
        check csgInt2.shape.primary.shape.secondary.transformation.kind == tkComposition
        check csgInt2.shape.primary.shape.secondary.transformation.transformations[0].kind == tkRotation
        check csgInt2.shape.primary.shape.secondary.transformation.transformations[1].kind == tkTranslation
        check areClose(csgInt2.shape.primary.shape.primary.transformation.offset, newVec3f(1, 2, 3))  
        check csgInt2.shape.primary.shape.secondary.transformation.transformations[0].axis == axisX
        check areClose(csgInt2.shape.primary.shape.secondary.transformation.transformations[0].cos, 0)
        check areClose(csgInt2.shape.primary.shape.secondary.transformation.transformations[0].sin, 1)
        check areClose(csgInt2.shape.primary.shape.secondary.transformation.transformations[1].offset, eY)  
        
        check csgInt2.shape.primary.transformation.kind == tkTranslation
        check areClose(csgInt2.shape.primary.transformation.offset, eX)  

        # Checking second shape
        check csgInt2.shape.secondary.shape.kind == skSphere
        check csgInt2.shape.primary.shape.primary.shape.kind == skSphere
        check csgInt2.shape.primary.shape.secondary.shape.kind == skTriangle

        check csgInt2.shape.secondary.transformation.kind == tkTranslation
        check areClose(csgInt2.shape.secondary.transformation.offset, newVec3f(-1, -2, -3))  


    test "getAABB (Local) proc":
        # Gives aabb for a csgInt shape in local reference system
        let 
            aabb1 = getAABB(csgInt1.shape)
            aabb2 = getAABB(csgInt2.shape)

        check areClose(aabb1.min, newPoint3D(-1,-1, 1), eps = 1e-6)
        check areClose(aabb1.max, newPoint3D( 3, 4, 5), eps = 1e-6)

        check areClose(aabb2.min, newPoint3D(-3,-4,-5), eps = 1e-6)
        check areClose(aabb2.max, newPoint3D( 4, 4, 5), eps = 1e-6)


    test "getVertices (Local) proc":
        # Gives vertices for all aabb being a part of CSGInt shape, in "shape reference system".
        # We are not accounting for handler transformation
        let     
            aabb1 = csgInt1.shape.getAABB
            aabb2 = csgInt2.shape.getAABB

            vert1 = getVertices(aabb1)
            vert2 = getVertices(aabb2)
    
        # First CSGInt
        check areClose(vert1[0], aabb1.min)
        check areClose(vert1[1], aabb1.max)
        check areClose(vert1[2], newPoint3D(-1,-1, 5))
        check areClose(vert1[3], newPoint3D(-1, 4, 1))
        check areClose(vert1[4], newPoint3D(-1, 4, 5))
        check areClose(vert1[5], newPoint3D( 3,-1, 1))
        check areClose(vert1[6], newPoint3D( 3,-1, 5))
        check areClose(vert1[7], newPoint3D( 3, 4, 1))


        # Second CSGInt
        check areClose(vert2[0], aabb2.min)
        check areClose(vert2[1], aabb2.max)
        check areClose(vert2[2], newPoint3D(-3,-4, 5))
        check areClose(vert2[3], newPoint3D(-3, 4,-5))
        check areClose(vert2[4], newPoint3D(-3, 4, 5))
        check areClose(vert2[5], newPoint3D( 4,-4,-5))
        check areClose(vert2[6], newPoint3D( 4,-4, 5))
        check areClose(vert2[7], newPoint3D( 4, 4,-5))
    

    test "getAABB (World) proc":
        # Gives aabb for a csgInt shape in world reference system
        let
            aabb1 = csgInt1.aabb
            aabb2 = csgInt2.aabb

        check areClose(aabb1.min, newPoint3D(0, -1, 1), eps = 1e-6)
        check areClose(aabb1.max, newPoint3D(4, 4, 5), eps = 1e-6)

        check areClose(aabb2.min, newPoint3D(-3, -4, -5), eps = 1e-6)
        check areClose(aabb2.max, newPoint3D(4, 4, 5), eps = 1e-6)



#---------------------------#
#     CSGDiff test suite     #
#---------------------------# 
suite "CSGDiff":

    setup:
        let 
            brdf = newDiffuseBRDF(newUniformPigment(WHITE))
            pigm = newUniformPigment(WHITE)

            tr = newTranslation(eX)
            comp = newComposition(newRotation(90, axisX), newTranslation(eY))
            
            sph1 = newSphere(newPoint3D(1, 2, 3), 2, brdf, pigm)
            spSh2 = newSphere(newPoint3D(-1, -2, -3), 2, brdf, pigm)
            triSh = newTriangle([eX.Point3D, eY.Point3D, eZ.Point3D], brdf, pigm, transformation = comp)
            
            csgDiff1 = newCSGDiff(sph1, triSh, brdf, pigm, tr)
            csgDiff2 = newCSGDiff(csgDiff1, spSh2, brdf, pigm)
    
    teardown:
        discard tr
        discard comp
        discard brdf
        discard pigm
        discard sph1
        discard spSh2
        discard triSh
        discard csgDiff1
        discard csgDiff2
    
    
    test "newCSGDiff proc":
        # Checking newCSGDiff proc

        #----------------------------------#
        #          First CSGDiff            #
        #----------------------------------#      
        check csgDiff1.shape.kind == skCSGDiff
        check csgDiff1.transformation.kind == tkTranslation
        check areClose(csgDiff1.transformation.offset, eX)
      
        # Checking first shape
        check csgDiff1.shape.primary.shape.kind == skSphere
        check csgDiff1.shape.primary.shape.radius == 2

        check csgDiff1.shape.primary.transformation.kind == tkTranslation
        check areClose(csgDiff1.shape.primary.transformation.offset, newVec3f(1, 2, 3))

        # Checking second shape
        check csgDiff1.shape.secondary.shape.kind == skTriangle
        check csgDiff1.shape.secondary.shape.vertices[0] == eX.Point3D
        check csgDiff1.shape.secondary.shape.vertices[1] == eY.Point3D
        check csgDiff1.shape.secondary.shape.vertices[2] == eZ.Point3D

        check csgDiff1.shape.secondary.transformation.kind == tkComposition
        check csgDiff1.shape.secondary.transformation.transformations[0].kind == tkRotation
        check csgDiff1.shape.secondary.transformation.transformations[1].kind == tkTranslation
        
        check csgDiff1.shape.secondary.transformation.transformations[0].axis == axisX
        check areClose(csgDiff1.shape.secondary.transformation.transformations[0].cos, newRotation(90, axisX).cos, eps = 1e-6)
        check areClose(csgDiff1.shape.secondary.transformation.transformations[0].sin, newRotation(90, axisX).sin, eps = 1e-6)
        check areClose(csgDiff1.shape.secondary.transformation.transformations[1].offset, eY)


        #-----------------------------------#
        #          Second CSGDiff            #
        #-----------------------------------#
        check csgDiff2.shape.kind == skCSGDiff
        check csgDiff2.transformation.kind == tkIdentity 

        # Checking first shape
        check csgDiff2.shape.primary.shape.kind == skCSGDiff
        check csgDiff2.shape.primary.shape.primary.shape.kind == skSphere
        check csgDiff2.shape.primary.shape.secondary.shape.kind == skTriangle

        check csgDiff2.shape.primary.transformation.kind == tkTranslation
        check areClose(csgDiff2.shape.primary.transformation.offset, eX) 

        check csgDiff2.shape.primary.shape.primary.transformation.kind == tkTranslation
        check csgDiff2.shape.primary.shape.secondary.transformation.kind == tkComposition
        check csgDiff2.shape.primary.shape.secondary.transformation.transformations[0].kind == tkRotation
        check csgDiff2.shape.primary.shape.secondary.transformation.transformations[1].kind == tkTranslation
        check areClose(csgDiff2.shape.primary.shape.primary.transformation.offset, newVec3f(1, 2, 3))  
        check csgDiff2.shape.primary.shape.secondary.transformation.transformations[0].axis == axisX
        check areClose(csgDiff2.shape.primary.shape.secondary.transformation.transformations[0].cos, 0)
        check areClose(csgDiff2.shape.primary.shape.secondary.transformation.transformations[0].sin, 1)
        check areClose(csgDiff2.shape.primary.shape.secondary.transformation.transformations[1].offset, eY)  
        
        check csgDiff2.shape.primary.transformation.kind == tkTranslation
        check areClose(csgDiff2.shape.primary.transformation.offset, eX)  

        # Checking second shape
        check csgDiff2.shape.secondary.shape.kind == skSphere
        check csgDiff2.shape.primary.shape.primary.shape.kind == skSphere
        check csgDiff2.shape.primary.shape.secondary.shape.kind == skTriangle

        check csgDiff2.shape.secondary.transformation.kind == tkTranslation
        check areClose(csgDiff2.shape.secondary.transformation.offset, newVec3f(-1, -2, -3))  


    test "getAABB (Local) proc":
        # Gives aabb for a csgDiff shape in local reference system
        let 
            aabb1 = getAABB(csgDiff1.shape)
            aabb2 = getAABB(csgDiff2.shape)

        check areClose(aabb1.min, newPoint3D(-1,-1, 1), eps = 1e-6)
        check areClose(aabb1.max, newPoint3D( 3, 4, 5), eps = 1e-6)

        check areClose(aabb2.min, newPoint3D(-3,-4,-5), eps = 1e-6)
        check areClose(aabb2.max, newPoint3D( 4, 4, 5), eps = 1e-6)


    test "getVertices (Local) proc":
        # Gives vertices for all aabb being a part of CSGDiff shape, in "shape reference system".
        # We are not accounting for handler transformation
        let     
            aabb1 = csgDiff1.shape.getAABB
            aabb2 = csgDiff2.shape.getAABB

            vert1 = getVertices(aabb1)
            vert2 = getVertices(aabb2)
    
        # First CSGDiff
        check areClose(vert1[0], aabb1.min)
        check areClose(vert1[1], aabb1.max)
        check areClose(vert1[2], newPoint3D(-1,-1, 5))
        check areClose(vert1[3], newPoint3D(-1, 4, 1))
        check areClose(vert1[4], newPoint3D(-1, 4, 5))
        check areClose(vert1[5], newPoint3D( 3,-1, 1))
        check areClose(vert1[6], newPoint3D( 3,-1, 5))
        check areClose(vert1[7], newPoint3D( 3, 4, 1))


        # Second CSGDiff
        check areClose(vert2[0], aabb2.min)
        check areClose(vert2[1], aabb2.max)
        check areClose(vert2[2], newPoint3D(-3,-4, 5))
        check areClose(vert2[3], newPoint3D(-3, 4,-5))
        check areClose(vert2[4], newPoint3D(-3, 4, 5))
        check areClose(vert2[5], newPoint3D( 4,-4,-5))
        check areClose(vert2[6], newPoint3D( 4,-4, 5))
        check areClose(vert2[7], newPoint3D( 4, 4,-5))
    

    test "getAABB (World) proc":
        # Gives aabb for a csgDiff shape in world reference system
        let
            aabb1 = csgDiff1.aabb
            aabb2 = csgDiff2.aabb

        check areClose(aabb1.min, newPoint3D(0, -1, 1), eps = 1e-6)
        check areClose(aabb1.max, newPoint3D(4, 4, 5), eps = 1e-6)

        check areClose(aabb2.min, newPoint3D(-3, -4, -5), eps = 1e-6)
        check areClose(aabb2.max, newPoint3D(4, 4, 5), eps = 1e-6)

        of hkCSG: 
            op*: CSGKind
            csg*: BVHTree

    CSGKind* = enum csgkUnion, csgkInt, csgkDiff


proc newCSGUnion*(sh1, sh2: ObjectHandler, brdf = newDiffuseBRDF(newUniformPigment(WHITE)), emittedRadiance = newUniformPigment(BLACK), transformation = Transformation.id): ObjectHandler {.inline.} = 
    newShapeHandler(Shape(kind: skCSGUnion, primary: sh1, secondary: sh2), brdf, emittedRadiance, transformation)    

proc newCSGInt*(sh1, sh2: ObjectHandler, brdf = newDiffuseBRDF(newUniformPigment(WHITE)), emittedRadiance = newUniformPigment(BLACK), transformation = Transformation.id): ObjectHandler {.inline.} = 
    newShapeHandler(Shape(kind: skCSGInt, primary: sh1, secondary: sh2), brdf, emittedRadiance, transformation)

proc newCSGDiff*(sh1, sh2: ObjectHandler, brdf = newDiffuseBRDF(newUniformPigment(WHITE)), emittedRadiance = newUniformPigment(BLACK), transformation = Transformation.id): ObjectHandler {.inline.} = 
    newShapeHandler(Shape(kind: skCSGDiff, primary: sh1, secondary: sh2), brdf, emittedRadiance, transformation)    

proc isOnSurface*(pt:Point3D, shape: Shape): bool = 
    # Procedure to check wether a point is on shape surface or not
    case shape.kind
    of skAABox:
        if areClose(pt.x, shape.aabb.min.x, 1e-6): 
            return true
        elif areClose(pt.x, shape.aabb.max.x, 1e-6): 
            return true
        elif areClose(pt.y, shape.aabb.min.y, 1e-6): 
            return true
        elif areClose(pt.y, shape.aabb.max.y, 1e-6): 
            return true
        elif areClose(pt.z, shape.aabb.min.z, 1e-6): 
            return true
        elif areClose(pt.z, shape.aabb.max.z, 1e-6): 
            return true

        return false
        
    of skSphere:
        if areClose(sqrt(pow(pt.x, 2) + pow(pt.y, 2) + pow(pt.z, 2)), pow(shape.radius, 2), 1e-6):
            return true
        
        return false

    of skCylinder:
        if not areClose(sqrt(pow(pt.x, 2) + pow(pt.y, 2)), shape.R):
            return false
        elif not shape.zSpan.contains(pt.z):
            return false
        elif arctan2(pt.y, pt.x) <= shape.phiMax:
            return false
        
        return true

    of skPlane:
        if pt.z == 0:
            return true

        return false

    of skEllipsoid: 
        let scal = newScaling(1/shape.axis.a, 1/shape.axis.b, 1/shape.axis.c)
        return apply(scal, pt).isOnSurface(Shape(kind: skSphere, radius: 1))

    of skTriangle: discard
