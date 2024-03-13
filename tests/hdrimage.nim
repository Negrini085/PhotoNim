import std/unittest
import PhotoNim/[common, color, hdrimage]

suite "HdrImageTest":
    
    setup:
        var img: HdrImage = newHdrImage(2, 2)
    
    test "newHdrImage":
        ## Constructor test
        
        # Checking dimensions (width and height)
        check img.width == 2
        check img.height == 2

        # Checking array content
        for i in 0..<img.height*img.width:
            check areClose(img.image[i].r, 0.0)
            check areClose(img.image[i].g, 0.0)
            check areClose(img.image[i].b, 0.0)


    test "set/get_pixel":
        ## Set pixel test
        img.set_pixel(1, 1, newColor(1.0, 2.0, 3.0))
        
        # Get pixel test
        check areClose(img.get_pixel(1,0).r, 0.0)
        check areClose(img.get_pixel(1,0).g, 0.0)
        check areClose(img.get_pixel(1,0).b, 0.0)       

        check areClose(img.get_pixel(1,1).r, 1.0)
        check areClose(img.get_pixel(1,1).g, 2.0)
        check areClose(img.get_pixel(1,1).b, 3.0)

    
    test "parseEndianness":
        let f = open("endianness.txt")
        defer: f.close()
        var endiann: Endianness
        try:
            endiann = parseEndianness(f.readLine())
        except IOError as e:
            quit(e.msg, QuitFailure)

        echo endiann