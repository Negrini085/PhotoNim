import std/[unittest, tables, options, streams, sets]
import PhotoNim


#--------------------------------------#
#         DefScene test suite          #
#--------------------------------------#
suite "DefScene":

    setup:
        let
            col1 = newColor(0.3, 0.8, 1)
            col2 = newColor(0.3, 1, 0.3)

            sc = @[newSphere(newPoint3D(1, 2, 3), 2)]
            mat = {
                "try":  newMaterial(newSpecularBRDF(), newUniformPigment(col1)),
                "me": newMaterial(newDiffuseBRDF(), newCheckeredPigment(col1, col2, 2, 2)) 
            }.toTable
            rend = newPathTracer()
            cam = some newPerspectiveCamera(rend, (width:10, height: 12), 2.0)
            numV = {
                "pippo": 4.3.float32,
                "pluto": 1.2.float32
            }.toTable
        
        var ovV = initHashSet[string](2)
        ovV.incl("pippo")
        ovV.incl("pluto")

        let dSc = newDefScene(sc, mat, cam, numV, ovV)

    
    teardown:
        discard sc    
        discard mat 
        discard cam
        discard ovV
        discard dSc
        discard col1
        discard col2
        discard rend
        discard numV
    

    test "newDefScene proc":
        # Checking newDefScene proc test

        check dSc.scene[0].shape.kind == skSphere
        check dSc.scene[0].shape.radius == 2
        check areClose(dSc.scene[0].transformation.mat, newTranslation(newPoint3D(1, 2, 3)).mat)

        check dSc.camera.isSome
        check dSc.camera.get.kind == ckPerspective
        check dSc.camera.get.renderer.kind == rkPathTracer
        check dSc.camera.get.transformation.kind == tkIdentity

        check dSc.materials["try"].brdf.kind == SpecularBRDF
        check dSc.materials["try"].radiance.kind == pkUniform
        check areClose(dSc.materials["try"].radiance.color, col1)

        check dSc.materials["me"].brdf.kind == DiffuseBRDF
        check dSc.materials["me"].radiance.kind == pkCheckered
        check dSc.materials["me"].radiance.grid.nRows == 2.int
        check dSc.materials["me"].radiance.grid.nCols == 2.int
        check areClose(dSc.materials["me"].radiance.grid.c1, col1)
        check areClose(dSc.materials["me"].radiance.grid.c2, col2)

        check areClose(dSc.numVariables["pippo"], 4.3.float32)
        check areClose(dSc.numVariables["pluto"], 1.2.float32)
    
        check dSc.overriddenVariables.contains("pippo")
        check dSc.overriddenVariables.contains("pluto")



#---------------------------------------------------------------#
#                    Expect procs test suite                    #
#---------------------------------------------------------------#
suite "Expect":

    setup:
        var
            fname = "files/Expect/symbol.txt"
            fstr = newFileStream(fname, fmRead)

            inStr = newInputStream(fstr, fname, 4)
    
    teardown:
        discard fstr
        discard fname
        discard inStr
    

    test "expectSymbol proc":
        # Checking expectSymbol procedure

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.readChar() == '\n'

        inStr.expectSymbol('(')
        
        check inStr.readChar() == '\n'
        check inStr.location.colNum == 1
        check inStr.location.lineNum == 3
        check inStr.location.filename == fname


    test "expectKeywords proc":
        # Checking expectKeywords procedure
        let keys = @[NEW, PLANE]
        
        fname = "files/Expect/keys.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.readChar() == '\n'

        check inStr.expectKeywords(keys) == NEW
        
        check inStr.readChar() == '\n'
        check inStr.location.colNum == 1
        check inStr.location.lineNum == 3
        check inStr.location.filename == fname


    test "expectNumber proc":
        # Checking expectNumber procedure
        var ovV = initHashSet[string](2)
        ovV.incl("pippo")
        ovV.incl("pluto")

        let
            col1 = newColor(0.3, 0.8, 1)
            col2 = newColor(0.3, 1, 0.3)

            sc = @[newSphere(newPoint3D(1, 2, 3), 2)]
            mat = {
                "try":  newMaterial(newSpecularBRDF(), newUniformPigment(col1)),
                "me": newMaterial(newDiffuseBRDF(), newCheckeredPigment(col1, col2, 2, 2)) 
            }.toTable
            rend = newPathTracer()
            cam = some newPerspectiveCamera(rend, (width:10, height: 12), 2.0)
            numV = {
                "prova": 4.3.float32,
                "pluto": 1.2.float32
            }.toTable
        
        var dSc = newDefScene(sc, mat, cam, numV, ovV)
        
        fname = "files/Expect/num.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.readChar() == '\n'

        check areClose(inStr.expectNumber(dSc), 4.23)
        check areClose(inStr.expectNumber(dSc), 4.30)


    test "expectString proc":
        # Checking expectString procedure
        
        fname = "files/Expect/str.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.readChar() == '\n'

        check inStr.expectString() == "Daje"


    test "expectIdentifier proc":
        # Checking expectIdentifier procedure
        
        fname = "files/Expect/name.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.readChar() == '\n'

        check inStr.expectIdentifier() == "prova"



#--------------------------------------------------------------#
#                    Parse procs test suite                    #
#--------------------------------------------------------------#
suite "Parse":

    setup:
        var ovV = initHashSet[string](2)
        ovV.incl("pippo")
        ovV.incl("pluto")

        let
            col1 = newColor(0.3, 0.8, 1)
            col2 = newColor(0.3, 1, 0.3)

            sc = @[newSphere(newPoint3D(1, 2, 3), 2)]
            mat = {
                "try":  newMaterial(newSpecularBRDF(), newUniformPigment(col1)),
                "me": newMaterial(newDiffuseBRDF(), newCheckeredPigment(col1, col2, 2, 2)) 
            }.toTable
            rend = newPathTracer()
            cam = some newPerspectiveCamera(rend, (width:10, height: 12), 2.0)
            numV = {
                "prova": 4.3.float32,
                "pluto": 1.2.float32
            }.toTable

        var
            fname = "files/Parse/vec_col.txt"
            fstr = newFileStream(fname, fmRead)

            inStr = newInputStream(fstr, fname, 4)
            dSc = newDefScene(sc, mat, cam, numV, ovV)
    
    teardown:
        discard sc
        discard dSc
        discard mat
        discard cam
        discard ovV
        discard col1
        discard col2
        discard fstr
        discard rend
        discard numV
        discard fname
        discard inStr
    

    test "parseVec proc":
        # Checking parseVec proc

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check areClose(inStr.parseVec(dSc), newVec3(4.3, 3, 1))


    test "parseColor proc":
        # Checking parseColor proc

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check areClose(inStr.parseVec(dSc), newVec3(4.3, 3, 1))
        check areClose(inStr.parseColor(dSc), newColor(0.2, 0.9, 0))


    test "parsePigment proc":
        # Checking parsePigment proc
        var pg: Pigment
    
        fname = "files/Parse/pigment.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'

        pg = inStr.parsePigment(dSc)
        check pg.kind == pkUniform
        check areClose(pg.color, newColor(1.0, 0.3, 0.1)) 

        pg = inStr.parsePigment(dSc)
        check pg.kind == pkCheckered
        check areClose(pg.grid.c1, newColor(1.0, 0.3, 0.1)) 
        check areClose(pg.grid.c2, newColor(0.3, 0.9, 0.1)) 
        check pg.grid.nCols == 2 
        check pg.grid.nRows == 2

        pg = inStr.parsePigment(dSc)
        check pg.kind == pkTexture


    test "parseBRDF proc":
        # Checking parseBRDF proc
        var brdf: BRDF
    
        fname = "files/Parse/brdf.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'

        brdf = inStr.parseBRDF(dSc)
        check brdf.kind == DiffuseBRDF
        check brdf.pigment.kind == pkUniform
        check areClose(brdf.pigment.color, newColor(1.0, 0.3, 0.1)) 

        brdf = inStr.parseBRDF(dSc)
        check brdf.kind == SpecularBRDF
        check brdf.pigment.kind == pkCheckered
        check areClose(brdf.pigment.grid.c1, newColor(1.0, 0.3, 0.1)) 
        check areClose(brdf.pigment.grid.c2, newColor(0.1, 4.3, 0.2)) 
        check brdf.pigment.grid.nRows == 2 
        check brdf.pigment.grid.nCols == 2 


    test "parseMaterial proc":
        # Checking parseMaterial proc
        var appo: tuple[name: string, mat: Material]
    
        fname = "files/Parse/material.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'

        appo = inStr.parseMaterial(dSc)
        check appo.name == "daje"
        check appo.mat.brdf.kind == DiffuseBRDF
        check appo.mat.radiance.kind == pkUniform
        check appo.mat.brdf.pigment.kind == pkUniform
        check areClose(appo.mat.radiance.color, newColor(0.1, 0.2, 0.3)) 
        check areClose(appo.mat.brdf.pigment.color, newColor(0.1, 0.2, 0.3)) 

        appo = inStr.parseMaterial(dSc)
        check appo.name == "sium"
        check appo.mat.brdf.kind == SpecularBRDF
        check appo.mat.radiance.kind == pkUniform
        check appo.mat.brdf.pigment.kind == pkCheckered
        check areClose(appo.mat.radiance.color, newColor(0.1, 0.2, 0.3)) 
        check areClose(appo.mat.brdf.pigment.grid.c1, newColor(0.1, 0.2, 0.3)) 
        check areClose(appo.mat.brdf.pigment.grid.c2, newColor(4.3, 0.1, 0.2)) 
        check appo.mat.brdf.pigment.grid.nRows == 2 
        check appo.mat.brdf.pigment.grid.nCols == 2 


    test "parseTransformation proc":
        # Checking parseTransformation proc
        var trans: Transformation
            
        fname = "files/Parse/trans.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'

        trans = inStr.parseTransformation(dSc)
        check trans.kind == tkTranslation
        check areClose(trans.mat, newTranslation(newVec3(1, 2, 3)).mat)

        trans = inStr.parseTransformation(dSc)
        check trans.kind == tkRotation
        check areClose(trans.mat, newRotX(45).mat, eps = 1e-6)

        trans = inStr.parseTransformation(dSc)
        check trans.kind == tkRotation
        check areClose(trans.mat, newRotY(21.2).mat, eps = 1e-6)

        trans = inStr.parseTransformation(dSc)
        check trans.kind == tkRotation
        check areClose(trans.mat, newRotZ(12).mat, eps = 1e-6)

        trans = inStr.parseTransformation(dSc)
        check trans.kind == tkScaling
        check areClose(trans.mat, newScaling(newVec3(4.3, 0.3, 1.2)).mat)

        trans = inStr.parseTransformation(dSc)
        check trans.kind == tkIdentity

        trans = inStr.parseTransformation(dSc)
        check trans.kind == tkComposition
        check trans.transformations.len == 2
        check areClose(trans.transformations[0].mat, newTranslation(newVec3(4, 5, 6)).mat)
        check areClose(trans.transformations[1].mat, newRotX(33).mat, eps = 1e-6)

        trans = inStr.parseTransformation(dSc)
        check trans.kind == tkComposition
        check trans.transformations.len == 3
        check areClose(trans.transformations[0].mat, newTranslation(newVec3(7, 8, 9)).mat)
        check areClose(trans.transformations[1].mat, newScaling(newVec3(1, 2, 3)).mat)
        check areClose(trans.transformations[2].mat, newRotY(90).mat, eps = 1e-6)
    

    test "parseSphereSH proc":
        # Checking parseSphereSH procedure, returns a ObjectHandler of a sphere
        var 
            sphereSH: ObjectHandler
            keys  = @[KeywordKind.SPHERE, KeywordKind.PLANE]

        fname = "files/Parse/Handlers/sphereSH.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.expectKeywords(keys) == KeywordKind.SPHERE

        sphereSH = inStr.parseSphereSH(dSc)
        check sphereSH.shape.kind == skSphere
        check areClose(sphereSH.shape.radius, 2)
        check sphereSH.transformation.kind == tkTranslation
        check sphereSH.shape.material.brdf.kind == SpecularBRDF
        check sphereSH.shape.material.radiance.kind == pkUniform
        check areClose(sphereSH.shape.material.radiance.color, newColor(0.3, 0.8, 1))
        check areClose(sphereSH.transformation.mat, newTranslation(newPoint3D(1, 2, 3)).mat)


    test "parsePlaneSH proc":
        # Checking parsePlaneSH procedure, returns a ObjectHandler of a plane 
        var 
            planeSH: ObjectHandler
            keys  = @[KeywordKind.SPHERE, KeywordKind.PLANE]

        fname = "files/Parse/Handlers/planeSH.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.expectKeywords(keys) == KeywordKind.PLANE

        planeSH = inStr.parsePlaneSH(dSc)
        check planeSH.shape.kind == skPlane
        check planeSH.transformation.kind == tkComposition

        check planeSH.transformation.transformations.len == 2
        check areClose(planeSH.transformation.transformations[0].mat, newTranslation(newVec3(1, 2, 3)).mat)
        check areClose(planeSH.transformation.transformations[1].mat, newScaling(newVec3(0.1, 0.2, 0.3)).mat)

        check planeSH.shape.material.brdf.kind == DiffuseBRDF
        check planeSH.shape.material.radiance.kind == pkCheckered
        check areClose(planeSH.shape.material.radiance.grid.c1, col1)
        check areClose(planeSH.shape.material.radiance.grid.c2, col2)
        check planeSH.shape.material.radiance.grid.nRows == 2
        check planeSH.shape.material.radiance.grid.nCols == 2


    test "parseBoxSH proc":
        # Checking parseBoxSH procedure, returns a ObjectHandler of a box 
        var 
            boxSH: ObjectHandler
            keys  = @[KeywordKind.SPHERE, KeywordKind.PLANE, KeywordKind.BOX]

        fname = "files/Parse/Handlers/boxSH.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.expectKeywords(keys) == KeywordKind.BOX

        boxSH = inStr.parseBoxSH(dSc)
        check boxSH.shape.kind == skAABox
        check boxSH.transformation.kind == tkComposition

        check boxSH.transformation.transformations.len == 2
        check areClose(boxSH.transformation.transformations[0].mat, newRotX(45).mat, eps = 1e-6)
        check areClose(boxSH.transformation.transformations[1].mat, newScaling(newVec3(0.1, 0.2, 0.3)).mat)

        check boxSH.shape.material.brdf.kind == SpecularBRDF
        check boxSH.shape.material.radiance.kind == pkUniform
        check areClose(boxSH.shape.material.radiance.color, newColor(0.3, 0.8, 1))


    test "parseTriangleSH proc":
        # Checking parseTriangleSH procedure, returns a ObjectHandler of a triangle 
        var 
            triangleSH: ObjectHandler
            keys  = @[KeywordKind.TRIANGLE, KeywordKind.PLANE, KeywordKind.BOX]

        fname = "files/Parse/Handlers/triangleSH.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.expectKeywords(keys) == KeywordKind.TRIANGLE

        triangleSH = inStr.parseTriangleSH(dSc)
        check triangleSH.shape.kind == skTriangle
        check areClose(triangleSH.shape.vertices[0], newPoint3D(1, 2, 3))
        check areClose(triangleSH.shape.vertices[1], newPoint3D(4, 5, 6))
        check areClose(triangleSH.shape.vertices[2], newPoint3D(7, 8, 9))

        check triangleSH.shape.material.brdf.kind == DiffuseBRDF
        check triangleSH.shape.material.radiance.kind == pkCheckered
        check areClose(triangleSH.shape.material.radiance.grid.c1, col1)
        check areClose(triangleSH.shape.material.radiance.grid.c2, col2)
        check triangleSH.shape.material.radiance.grid.nRows == 2
        check triangleSH.shape.material.radiance.grid.nCols == 2

        check triangleSH.transformation.kind == tkTranslation
        check areClose(triangleSH.transformation.mat, newTranslation(newVec3(9, 8, 7)).mat)


    test "parseCylinderSH proc":
        # Checking parseCylinderSH procedure, returns a ObjectHandler of a cylinder 
        var 
            cylinderSH: ObjectHandler
            keys  = @[KeywordKind.TRIANGLE, KeywordKind.CYLINDER, KeywordKind.BOX]

        fname = "files/Parse/Handlers/cylinderSH.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.expectKeywords(keys) == KeywordKind.CYLINDER

        cylinderSH = inStr.parseCylinderSH(dSc)
        check cylinderSH.shape.kind == skCylinder
        check areClose(cylinderSH.shape.R, 2.0)
        check areClose(cylinderSH.shape.zSpan.min, -1.0)
        check areClose(cylinderSH.shape.zSpan.max, 1.0)
        check areClose(cylinderSH.shape.phiMax, 4.0)

        check cylinderSH.shape.material.brdf.kind == SpecularBRDF
        check cylinderSH.shape.material.radiance.kind == pkUniform
        check areClose(cylinderSH.shape.material.radiance.color, newColor(0.3, 0.8, 1))

        check cylinderSH.transformation.kind == tkScaling
        check areClose(cylinderSH.transformation.mat, newScaling(newVec3(1, 2, 3)).mat)


    # test "parseMeshSH proc":
    #     # Checking parseMeshSH procedure, returns a ObjectHandler of a mesh
    #     var 
    #         meshSH: ObjectHandler
    #         keys  = @[KeywordKind.TRIANGLE, KeywordKind.TRIANGULARMESH, KeywordKind.BOX]

    #     fname = "files/Parse/Handlers/meshSH.txt"
    #     fstr = newFileStream(fname, fmRead)
    #     inStr = newInputStream(fstr, fname, 4)

    #     check not fstr.isNil
    #     check inStr.readChar() == 'a'
    #     check inStr.expectKeywords(keys) == KeywordKind.TRIANGULARMESH

    #     meshSH = inStr.parseMeshSH(dSc)
    #     check meshSH.shape.kind == skTriangularMesh

    #     check meshSH.transformation.kind == tkTranslation
    #     check areClose(meshSH.transformation.mat, newTranslation(newVec3(1, 2, 3)).mat)


    test "parseCSGUnionSH proc":
        # Cheking parseCSGUnionSH procedure, returns a shapeHandler of a CSGUnion shape
        var
            csgUnionSH: ShapeHandler
            keys = @[KeywordKind.PLANE, KeywordKind.CSGUNION, KeywordKind.SPHERE]
        
        fname = "files/Parse/Handlers/csgUnionSH.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)
    
        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.expectKeywords(keys) == KeywordKind.CSGUNION
        
        csgUnionSH = inStr.parseCSGUnionSH(dSc)
        check csgUnionSH.shape.kind == skCSGUnion

        check csgUnionSH.shape.shapes.primary.kind == skSphere
        check csgUnionSH.shape.shapes.secondary.kind == skTriangle

        check csgUnionSH.shape.shTrans.tPrimary.kind == tkTranslation
        check csgUnionSH.shape.shTrans.tSecondary.kind == tkTranslation
        check areClose(csgUnionSH.shape.shTrans.tPrimary.offset, newVec3(1, 2, 3))
        check areClose(csgUnionSH.shape.shTrans.tSecondary.offset, newVec3(1, 2, 3))

        check csgUnionSH.shape.shapes.primary.material.brdf.kind == SpecularBRDF
        check csgUnionSH.shape.shapes.secondary.material.brdf.kind == DiffuseBRDF

        check csgUnionSH.transformation.kind == tkTranslation
        check areClose(csgUnionSH.transformation.offset, newVec3(1, 2, 3))


    test "parseCamera proc":
        # Checking parseCamera procedure
        var 
            camP: Camera
            keys  = @[KeywordKind.CAMERA, KeywordKind.NEW]

        fname = "files/Parse/camera.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check not fstr.isNil
        check inStr.readChar() == 'a'
        check inStr.expectKeywords(keys) == KeywordKind.CAMERA

        camP = inStr.parseCamera(dSc)
        check camP.kind == ckPerspective
        check camP.viewport.width == 5
        check camP.viewport.height == 6
        check areClose(camP.distance, 1.2)
        check camP.transformation.kind == tkRotation
        check areClose(camP.transformation.mat, newRotX(45).mat, eps = 1e-6)

        check inStr.expectKeywords(keys) == KeywordKind.CAMERA

        camP = inStr.parseCamera(dSc)
        check camP.kind == ckOrthogonal
        check camP.viewport.width == 1
        check camP.viewport.height == 4
        check camP.transformation.kind == tkTranslation
        check areClose(camP.transformation.mat, newTranslation(newVec3(1, 2, 4.3)).mat)


    test "parseDefScene proc":
        # Check parseDefScene proc
        var 
            matP: Material
            camP: Camera

        fname = "files/Parse/scene.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)    
        dSc = inStr.parseDefScene()

        # Checking numVariables
        check dSc.numVariables.len() == 1
        check "clock" in dSc.numVariables
        check areClose(dSc.numVariables["clock"], 150.0)

        # Checking materials
        check dSc.materials.len == 3
        check "sphereMaterial" in dSc.materials
        check "skyMaterial" in dSc.materials
        check "groundMaterial" in dSc.materials

        matP = dSc.materials["sphereMaterial"]
        check matP.brdf.kind == SpecularBRDF
        check matP.brdf.pigment.kind == pkUniform
        check areClose(matP.brdf.pigment.color, newColor(0.5, 0.5, 0.5))
        check matP.radiance.kind == pkUniform
        check areClose(matP.radiance.color, BLACK)

        matP = dSc.materials["skyMaterial"]
        check matP.brdf.kind == DiffuseBRDF
        check matP.brdf.pigment.kind == pkUniform
        check areClose(matP.brdf.pigment.color, BLACK)
        check matP.radiance.kind == pkUniform
        check areClose(matP.radiance.color, newColor(0.7, 0.5, 1.0))

        matP = dSc.materials["groundMaterial"]
        check matP.brdf.kind == DiffuseBRDF
        check matP.brdf.pigment.kind == pkCheckered
        check areClose(matP.brdf.pigment.grid.c1, newColor(0.3, 0.5, 0.1))
        check areClose(matP.brdf.pigment.grid.c2, newColor(0.1, 0.2, 0.5))
        check matP.brdf.pigment.grid.nRows == 2
        check matP.brdf.pigment.grid.nCols == 2
        check matP.radiance.kind == pkUniform
        check areClose(matP.radiance.color, BLACK)

        # Checking shapes 
        check dSc.scene.len == 3

        check dSc.scene[0].shape.kind == skPlane
        check dSc.scene[0].transformation.kind == tkComposition
        check dSc.scene[0].transformation.transformations.len == 2
        check dSc.scene[0].transformation.transformations[0].kind == tkTranslation
        check dSc.scene[0].transformation.transformations[1].kind == tkRotation
        check areClose(dSc.scene[0].transformation.transformations[0].mat, newTranslation(newVec3(0, 0, 100)).mat)
        check areClose(dSc.scene[0].transformation.transformations[1].mat, newRotY(150).mat, eps = 1e-6)

        check dSc.scene[1].shape.kind == skPlane
        check dSc.scene[1].transformation.kind == tkIdentity

        check dSc.scene[2].shape.kind == skSphere
        check dSc.scene[2].transformation.kind == tkTranslation
        check areClose(dSc.scene[2].transformation.mat, newTranslation(eZ).mat)

        # Checking camera
        check dSc.camera.isSome
        camP = dSc.camera.get

        check camP.kind == ckPerspective
        check camP.transformation.kind == tkComposition
        check camP.transformation.transformations.len == 2
        check camP.transformation.transformations[0].kind == tkRotation
        check camP.transformation.transformations[1].kind == tkTranslation
        check areClose(camP.transformation.transformations[0].mat, newRotZ(30).mat, eps = 1e-6) 
        check areClose(camP.transformation.transformations[1].mat, newTranslation(newVec3(-4, 0, 1)).mat)
        check areClose(camP.distance, 2)
        check camP.viewport.width == 100
        check camP.viewport.height == 100
