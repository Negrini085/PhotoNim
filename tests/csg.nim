import std/unittest
import ../src/[csg, scene, shape, geometry, color, pcg, material]

#---------------------------------#
#       CSGUnion test suite       #
#---------------------------------#
suite "CSGUnion":

    setup:
        let
            mat1 = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(newColor(1, 0, 0))), newUniformPigment(newColor(1, 0, 0)))
            mat2 = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(newColor(0, 1, 0))), newUniformPigment(newColor(0, 1, 0)))
            mat3 = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(newColor(0, 0, 1))), newUniformPigment(newColor(0, 0, 1)))

            sh1 = newSphere(newPoint3D(1, 2, 3), 2, mat1)
            sh2 = newSphere(newPoint3D(-5, 0, 0), 2, mat2)
            sh3 = newUnitarySphere(newPoint3D(0, 0, 3), mat3)

            csgUnion = newCSGUnion(@[sh1, sh2, sh3], tkBinary, 1, newRandomSetUp(42, 1))

    teardown:
        discard sh1
        discard sh2
        discard sh3
        discard mat1
        discard mat2
        discard mat3
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
        