import std/unittest
import PhotoNim

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
    

#    test "eval proc":
#        # Checking brdf evaluation
#        var
#            norm = newNormal(1, 0, 0)
#            inDir = newVec3(1, 2, -1)
#            outDir = newVec3(1, 2, 1)
#            appo: Color
#        
#        appo = dif.eval(norm, inDir, outDir)
#        check areClose(appo.r, 1 * 0.2/PI)
#        check areClose(appo.g, 2 * 0.2/PI)
#        check areClose(appo.b, 3 * 0.2/PI)
#
#        appo = spe.eval(norm, inDir, outDir)
#        check areClose(appo.r, 1)
#        check areClose(appo.g, 2)
#        check areClose(appo.b, 3)
    

    test "scatterDir proc":
        # Checking scatterDir procedure, needed to know how 
        # a shape actually react to ray intersection

        let
            rs = newRandomSetUp(42, 54)

            norm = newNormal(0, 0, 1)
            inDir = newVec3(1, 2,-1)
        
        var rg = newPCG(rs)
        
        check areClose(spe.scatterDir(norm, inDir, rg), newVec3(1, 2, 1))