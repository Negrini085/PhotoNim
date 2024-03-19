import std/unittest
import std/[streams, endians, strutils]
import PhotoNim/[common, color, hdrimage]

suite "HdrImageTest":
    
    setup:
        var 
            img: HdrImage = newHdrImage(2, 2)
    
    test "newHdrImage":
        ## Constructor test
        
        # Checking dimensions (width and height)
        check img.width == 2
        check img.height == 2

        # Checking array content
        for i in 0..<img.height*img.width:
            check areClose(img.pixels[i].r, 0.0)
            check areClose(img.pixels[i].g, 0.0)
            check areClose(img.pixels[i].b, 0.0)


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

    
    test "parseEndian":
        ## parseEndian test
        # Checks whether endianness is read correctly
        var
            stream: Stream = newFileStream("files/endianness.txt", fmRead)
            endian: Endianness = stream.parseEndian()

        check endian == bigEndian
        stream.close()
    
    test "parseDim":
        ## parseDim test
        # Checks whether dimension are read correctly
        var
            stream: Stream = newFileStream("files/dim.txt", fmRead)
            appo: array[2, uint] = stream.parseDim()

        check areClose(float32(appo[0]), float32(12))
        check areClose(float32(appo[1]), float32(20))

    test "writeparseFloat":
        ## writeFloat & parseFloat tests
        # Checks whether writeFloat and parseFloat are correctly implemented

        var stream: Stream = newFileStream("files/wpFloat.txt", fmWrite)
        
        #Testing float 
        stream.writeFloat(bigEndian, float32(1.0))
        stream.close()
        stream = openFileStream("files/wpFloat.txt", fmRead)
        check areClose(stream.parseFloat(bigEndian), float32(1.0))
        

