import std/unittest
from math import degToRad
import PhotoNim

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
            spe = newSpecularBRDF(newUniformPigment(newColor(1, 2, 3)), 110)

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
        check areClose(spe.threshold_angle, 0.1 * degToRad(110.0).float32)
    

#    test "eval proc":
#        # Checking brdf evaluation
#        var
#            norm = newNormal(1, 0, 0)
#            in_dir = newVec3f(1, 2, -1)
#            out_dir = newVec3f(1, 2, 1)
#            uv = newPoint2D(0.3, 0.5)
#            appo: Color
#        
#        appo = dif.eval(norm, in_dir, out_dir, uv)
#        check areClose(appo.r, 1 * 0.2/PI)
#        check areClose(appo.g, 2 * 0.2/PI)
#        check areClose(appo.b, 3 * 0.2/PI)
#
#        appo = spe.eval(norm, in_dir, out_dir, uv)
#        check areClose(appo.r, 1)
#        check areClose(appo.g, 2)
#        check areClose(appo.b, 3)



#-----------------------------------#
#        Material test suite        #
#-----------------------------------#
suite "Material":

    setup:
        let
            mat1 = newMaterial(newSpecularBRDF(), newCheckeredPigment(WHITE, BLACK, 2, 2))
            mat2 = newMaterial(newDiffuseBRDF(), newUniformPigment(newColor(0.3, 0.7, 1)))

    teardown:
        discard mat1
        discard mat2 

    test "newMaterial proc":
        # Checking newMaterial proc
        check mat1.brdf.kind == SpecularBRDF
        check mat1.emittedRadiance.kind == pkCheckered
        check areClose(mat1.emittedRadiance.getColor(newPoint2D(0.3, 0.2)), WHITE)
        check areClose(mat1.emittedRadiance.getColor(newPoint2D(0.8, 0.7)), WHITE)
        check areClose(mat1.emittedRadiance.getColor(newPoint2D(0.8, 0.2)), BLACK)
        check areClose(mat1.emittedRadiance.getColor(newPoint2D(0.3, 0.7)), BLACK)


        check mat2.brdf.kind == DiffuseBRDF
        check mat2.emittedRadiance.kind == pkUniform
        check areClose(mat2.emittedRadiance.getColor(newPoint2D(0.5, 0.5)), newColor(0.3, 0.7, 1))
