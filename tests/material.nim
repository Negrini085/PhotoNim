import std/unittest
import ../src/[material, geometry, color, hdrimage, pcg]


#-------------------------------#
#       Pigment test suite      #
#-------------------------------#
suite "Pigment":

    setup: 
        let
            color1 = newColor(1.0, 2.0, 3.0)
            color2 = newColor(2.0, 3.0, 1.0)
            color3 = newColor(2.0, 1.0, 3.0)
            color4 = newColor(3.0, 2.0, 1.0)

    teardown:
        discard color1
        discard color2
        discard color3
        discard color4


    test "color * proc":
        # Checking color tensor product proc
        var appo: Color

        appo = color1 * color2
        check areClose(appo.r, 2.0)
        check areClose(appo.g, 6.0)
        check areClose(appo.b, 3.0)


    test "newUniformPigment proc":
        # Checking newUniformPigment proc 
        let pigment = newUniformPigment(color1)

        check areClose(pigment.getColor(newPoint2D(0.0, 0.0)), color1)
        check areClose(pigment.getColor(newPoint2D(1.0, 0.0)), color1)
        check areClose(pigment.getColor(newPoint2D(0.0, 1.0)), color1)
        check areClose(pigment.getColor(newPoint2D(1.0, 1.0)), color1)
    

    test "newTexturePigment proc":
        # Checking newTexturePigment proc
        var image = newHDRImage(2, 2)
        image.setPixel(0, 0, color1); image.setPixel(1, 0, color2)
        image.setPixel(0, 1, color3); image.setPixel(1, 1, color4)

        let pigment = newTexturePigment(image)
        check areClose(pigment.getColor(newPoint2D(0.0, 0.0)), color1)
        check areClose(pigment.getColor(newPoint2D(1.0, 0.0)), newColor(2.0, 3.0, 1.0))
        check areClose(pigment.getColor(newPoint2D(0.0, 1.0)), newColor(2.0, 1.0, 3.0))
        check areClose(pigment.getColor(newPoint2D(1.0, 1.0)), newColor(3.0, 2.0, 1.0))
    

    test "newCheckeredPigment proc":
        let pigment = newCheckeredPigment(color1, color2, 2, 2)
        check areClose(pigment.getColor(newPoint2D(0.25, 0.25)), color1)
        check areClose(pigment.getColor(newPoint2D(0.75, 0.25)), color2)
        check areClose(pigment.getColor(newPoint2D(0.25, 0.75)), color2)
        check areClose(pigment.getColor(newPoint2D(0.75, 0.75)), color1)



#-----------------------------------#
#          BRDF test suite          #
#-----------------------------------#
suite "BRDF":

    setup:
        var
            dif = newDiffuseBRDF(newUniformPigment(newColor(1, 2, 3)), 0.2)
            spe = newSpecularBRDF(newUniformPigment(newColor(1, 2, 3)))

    teardown:
        discard dif
        discard spe


    test "newBRDF proc":
        # Checking constructor procedures

        check areClose(dif.pigment.color.r, 1)
        check areClose(dif.pigment.color.g, 2)
        check areClose(dif.pigment.color.b, 3)
        check areClose(dif.reflectance, 0.2)

        check areClose(spe.pigment.color.r, 1)
        check areClose(spe.pigment.color.g, 2)
        check areClose(spe.pigment.color.b, 3)
    

    test "scatterDir proc":
        # Checking scatterDir procedure, needed to know how 
        # a shape actually react to ray intersection

        let
            rs = newRandomSetUp(42, 54)

            norm = newNormal(0, 0, 1)
            inDir = newVec3(1, 2,-1)
        
        var rg = newPCG(rs)
        
        check areClose(spe.scatterDir(norm, inDir, rg), newVec3(1, 2, 1))


#--------------------------------------#
#          Material test suite         #
#---------------------...--------------#
suite "Material":

    setup:
        let
            mat = newMaterial(newDiffuseBRDF(newUniformPigment(newColor(1, 2, 3)), 0.2))
            emMat = newEmissiveMaterial(
                    newDiffuseBRDF(newUniformPigment(newColor(0.1, 0.2, 0.3))),
                    newUniformPigment(newColor(0.1, 0.2, 0.3))
                )

    teardown:
        discard mat
        discard emMat


    test "newMaterial proc":
        # Checking newMaterial procedure, in order to have a non emissive object
        
        check mat.kind == mkNonEmissive
        check mat.brdf.kind == DiffuseBRDF
        check mat.brdf.pigment.kind == pkUniform

        check areClose(mat.brdf.pigment.getColor(newPoint2D(0, 0)), newColor(1, 2, 3))


    test "newEmissiveMaterial proc":
        # Checking newEmissiveMaterial procedure, in order to have a non emissive object
        
        check emMat.kind == mkEmissive
        check emMat.brdf.kind == DiffuseBRDF
        check emMat.brdf.pigment.kind == pkUniform
        check emMat.eRadiance.kind == pkUniform
        
        check areClose(emMat.brdf.pigment.getColor(newPoint2D(0, 0)), newColor(0.1, 0.2, 0.3))
        check areClose(emMat.eRadiance.getColor(newPoint2D(0, 0)), newColor(0.1, 0.2, 0.3))
