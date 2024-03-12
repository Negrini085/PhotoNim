import std/unittest
import PhotoNim/common
import PhotoNim/types



#-------------------------------------------------------#
#                   Test of Color type                  #
#-------------------------------------------------------#

suite "ColorTest":
    setup:
        let col1 = newColor(1.0, 2.0, 3.0)
        var col2 = Color()

    test "newColor":
        ## Constructor test
        check areClose(col1.r, 1.0) 
        check areClose(col1.g, 2.0) 
        check areClose(col1.b, 3.0)
        check areClose(col2, newColor(0.0, 0.0, 0.0))

    test "sumCol":
        ## Sum of two color test
        col2 = newColor(0.1, 0.2, 0.3)
        var res: Color = col1.sumCol(col2)

        check areClose(res.r, 1.1)
        check areClose(res.g, 2.2)
        check areClose(res.b, 3.3)

    test "multByScal":
        ## Multiplication by a scalar test
        col2 = col1.multByScal(2)
        check areClose(col2.r, 2.0)
        check areClose(col2.g, 4.0)
        check areClose(col2.b, 6.0)

    test "multCol":
        ## Multiplication of two colors test
        col2 = col1.multByScal(2)
        var col3: Color = col1.multCol(col2)

        check areClose(col3.r, 2.0)
        check areClose(col3.g, 8.0)
        check areClose(col3.b, 18.0)






#-------------------------------------------------------#
#                 Test of HdrImage type                 #
#-------------------------------------------------------#

suite "HdrImageTest":
    
    setup:
        let im1: HdrImage = newHdrImage(2, 2)
        let im2: HdrImage = HdrImage()
    
    test "newHdrImage":
        ## Constructor test
        
        # Checking dimensions (width and height)
        check areClose(float(im1.width), 2.0)
        check areClose(float(im1.height), 2.0)
        check areClose(float(im2.width), 0.0)
        check areClose(float(im2.height), 0.0)

        #Checking array content
        for i in 0..<im1.height*im1.width:
            check areClose(im1.image[i].r, 0.0)
            check areClose(im1.image[i].g, 0.0)
            check areClose(im1.image[i].b, 0.0)

    test "valid_coord":
        ## Valid coordinates test
        
        # Testing negative coordinates
        check not valid_coord(im1, -1, 0)
        check not valid_coord(im1, 0, -1)

        #Testing out of bound coordinates
        check not valid_coord(im1, 2, 0)
        check not valid_coord(im1, 0, 2)

        #Testing valid coordinates
        check valid_coord(im1, 0, 0)
        check valid_coord(im1, 1, 1)

    test "pixel_ind":
        ## Pixel index calculator test
        check areClose(float(im1.pixel_ind(0,0)), 0.0)
        check areClose(float(im1.pixel_ind(1,1)), 3)