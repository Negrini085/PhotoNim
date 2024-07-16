import std/unittest
import ../src/[csg, scene, shape, geometry, brdf, pigment, color, pcg]

#---------------------------------#
#       CSGUnion test suite       #
#---------------------------------#
suite "CSGUnion":

    setup:
        let
            sh1 = newSphere(
                    newPoint3D(1, 2, 3), 2,
                    newDiffuseBRDF(newUniformPigment(newColor(1, 0, 0))), newUniformPigment(newColor(1, 0, 0))
                )
            
            sh2 = newSphere(
                    newPoint3D(-5, 0, 0), 2,
                    newSpecularBRDF(newUniformPigment(newColor(0, 1, 0))), newUniformPigment(newColor(0, 1, 0))
                )
            
            sh3 = newUnitarySphere(
                    newPoint3D(0, 0, 3),
                    newDiffuseBRDF(newUniformPigment(newColor(0, 0, 1))), newUniformPigment(newColor(0, 0, 1))
                )
            
            csgUnion = newCSGUnion(@[sh1, sh2, sh3], tkBinary, 1, newRandomSetUp(42, 1))

    teardown:
        discard sh1
        discard sh2
        discard sh3
        discard csgUnion
    

    test "newCSGUnion proc":
        # Procedure to check newCSGUnion implementation

        check csgUnion.kind == hkCSG
        check csgUnion.transformation.kind == tkIdentity

        check areClose(csgUnion.aabb.max, newPoint3D( 3, 4, 5))
        check areClose(csgUnion.aabb.min, newPoint3D(-7,-2,-2))

        check csgUnion.csg.kind == csgkUnion
        
        check csgUnion.csg.tree.kind == tkBinary
        check csgUnion.csg.tree.mspl == 1
        check areClose(csgUnion.csg.tree.root.aabb.max, newPoint3D( 3, 4, 5))
        check areClose(csgUnion.csg.tree.root.aabb.min, newPoint3D(-7,-2,-2))
        check csgUnion.csg.tree.handlers.len == 3
        