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

    test "sumColor":
        ## Sum of two color test
        col2 = newColor(0.1, 0.2, 0.3)
        var res: Color = col1 + col2

        check areClose(res.r, 1.1)
        check areClose(res.g, 2.2)
        check areClose(res.b, 3.3)

    test "mulColor":
        ## Multiplication of two colors test
        col2 = col1 * 2.0
        var col3: Color = col1 * col2

        check areClose(col3.r, 2.0)
        check areClose(col3.g, 8.0)
        check areClose(col3.b, 18.0)

    test "scaleColor":
        ## Multiplication by a scalar test
        col2 = 2.0 * col1
        check areClose(col2.r, 2.0)
        check areClose(col2.g, 4.0)
        check areClose(col2.b, 6.0)



#-------------------------------------------------------#
#                 Test of HdrImage type                 #
#-------------------------------------------------------#

suite "HdrImageTest":
    
    setup:
        var img: HdrImage = newHdrImage(2, 2)
    
    test "newHdrImage":
        ## Constructor test
        
        # Checking dimensions (width and height)
        check areClose(float(img.width), 2.0)
        check areClose(float(img.height), 2.0)

        #Checking array content
        for i in 0..<img.height*img.width:
            check areClose(img.image[i].r, 0.0)
            check areClose(img.image[i].g, 0.0)
            check areClose(img.image[i].b, 0.0)

    # test "valid_coord":
    #     ## Valid coordinates test
        
    #     # Testing negative coordinates
    #     check not valid_coord(img, -1, 0)
    #     check not valid_coord(img, 0, -1)

    #     #Testing out of bound coordinates
    #     check not valid_coord(img, 2, 0)
    #     check not valid_coord(img, 0, 2)

    #     #Testing valid coordinates
    #     check valid_coord(img, 0, 0)
    #     check valid_coord(img, 1, 1)

    # test "pixel_offset":
    #     ## Pixel index calculator test
    #     check areClose(float(img.pixel_offset(0,0)), 0.0)
    #     check areClose(float(img.pixel_offset(1,1)), 3)

    test "get_pixel":
        ## Get pixel test
        img.image[3] = newColor(1.0, 2.0, 3.0)
        
        # Testing black color
        check areClose(img.get_pixel(1,0).r, 0.0)
        check areClose(img.get_pixel(1,0).g, 0.0)
        check areClose(img.get_pixel(1,0).b, 0.0)       

        # Testing non black color
        check areClose(img.get_pixel(1,1).r, 1.0)
        check areClose(img.get_pixel(1,1).g, 2.0)
        check areClose(img.get_pixel(1,1).b, 3.0)