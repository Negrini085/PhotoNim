import std/unittest
import std/[streams, endians, strutils, math]
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
        
        #Testing float & string type
        stream.writeFloat(bigEndian, float32(1.0))
        stream.write("1.0")
        stream.close()

        stream = openFileStream("files/wpFloat.txt", fmRead)
        check areClose(stream.parseFloat(bigEndian), float32(1.0))
        check "1.0" == stream.readLine()
        stream.close()
    
    test "writeparsePFM":
        ## writePFM & parsePFM tests
        
        var 
            stream: Stream = newFileStream("files/wpPFM.txt", fmWrite)
            img1: HdrImage = newHdrImage(10, 15)
            img2: HdrImage
        
        #Changing some pixel in order to test writePFM & readPFM procedures
        img1.setPixel(3, 4, newColor(1.0, 2.0, 3.0))
        img1.setPixel(6, 3, newColor(3.4, 17.8, 128.1))
        img1.setPixel(8, 9, newColor(35.1, 18.2, 255.0))

        img1.writePFM(stream, bigEndian)
        stream.close()
        stream = openFileStream("files/wpPFM.txt", fmRead)
        img2 = stream.parsePFM()
        stream.close()

        #Checking pixel values
        check areClose(img2.get_pixel(3,4).r, 1.0)
        check areClose(img2.get_pixel(3,4).g, 2.0)
        check areClose(img2.get_pixel(3,4).b, 3.0)  

        check areClose(img2.get_pixel(6,3).r, 3.4)
        check areClose(img2.get_pixel(6,3).g, 17.8)
        check areClose(img2.get_pixel(6,3).b, 128.1)  

        check areClose(img2.get_pixel(8,9).r, 35.1)
        check areClose(img2.get_pixel(8,9).g, 18.2)
        check areClose(img2.get_pixel(8,9).b, 255.0)  
    
    test "averageLuminosity":
        ## averageLuminosity procedure test
        
        #Testing with blanck image and delta default value
        check areClose(log10(img.averageLuminosity), -10)
        #Changing pixel values and setting delta to zero
        img.setPixel(0, 0, newColor(1.0, 2.0, 3.0)); img.setPixel(0, 1, newColor(4.0, 5.0, 1.0))
        img.setPixel(1, 0, newColor(0.0, 1.5, 2.0)); img.setPixel(1, 1, newColor(2.0, 10.0, 3.0))
        check areClose(img.averageLuminosity(0.0), pow(36, 0.25))