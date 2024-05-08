import std/[unittest, streams, math]
import PhotoNim/[geometry, hdrimage]

suite "HdrImageTest":
    
    setup:
        var img: HdrImage = newHdrImage(2, 2)
    
    teardown:
        discard img
    
    test "newHdrImage":
        check img.width == 2 and img.height == 2

        for i in 0..<img.height*img.width:
            check areClose(img.pixels[i].r, 0.0)
            check areClose(img.pixels[i].g, 0.0)
            check areClose(img.pixels[i].b, 0.0)

    test "set/getPixel":
        img.setPixel(1, 1, newColor(1.0, 2.0, 3.0))
        
        check areClose(img.getPixel(1, 0).r, 0.0)
        check areClose(img.getPixel(1, 0).g, 0.0)
        check areClose(img.getPixel(1, 0).b, 0.0)       

        check areClose(img.getPixel(1, 1).r, 1.0)
        check areClose(img.getPixel(1, 1).g, 2.0)
        check areClose(img.getPixel(1, 1).b, 3.0)

    test "write/parseFloat":
        var stream = newFileStream("files/wpFloat.txt", fmWrite)

        stream.writeFloat(float32(1.0), bigEndian)
        stream.write("1.0")
        stream.close

        stream = openFileStream("files/wpFloat.txt", fmRead)
        check areClose(stream.parseFloat(bigEndian), float32(1.0))
        check "1.0" == stream.readLine
        stream.close
    
    test "write/parsePFM":       
        var 
            stream = newFileStream("files/wpPFM.txt", fmWrite)
            img1 = newHdrImage(10, 15)
        
        # Changing some pixel in order to test writePFM & readPFM procedures
        img1.setPixel(3, 4, newColor(1.0, 2.0, 3.0))
        img1.setPixel(6, 3, newColor(3.4, 17.8, 128.1))
        img1.setPixel(8, 9, newColor(35.1, 18.2, 255.0))

        stream.writePFM(img1, bigEndian)
        stream.close
        
        stream = openFileStream("files/wpPFM.txt", fmRead)
        let img2 = stream.readPFM.img
        stream.close

        # Checking pixel values
        check areClose(img2.getPixel(3, 4).r, 1.0)
        check areClose(img2.getPixel(3, 4).g, 2.0)
        check areClose(img2.getPixel(3, 4).b, 3.0)  

        check areClose(img2.getPixel(6, 3).r, 3.4)
        check areClose(img2.getPixel(6, 3).g, 17.8)
        check areClose(img2.getPixel(6, 3).b, 128.1)  

        check areClose(img2.getPixel(8, 9).r, 35.1)
        check areClose(img2.getPixel(8, 9).g, 18.2)
        check areClose(img2.getPixel(8, 9).b, 255.0)  
    
    test "colorLuminosity":
        ## Test color luminosity calculation
        let 
            col1 = newColor(1.0, 2.0, 3.0)
            col2 = newColor(0.0, 0.0, 0.0)

        check areClose(col1.luminosity, 2.0)
        check areClose(col2.luminosity, 0.0)

    test "averageLuminosity":        
        # Testing with blanck image and delta default value
        check areClose(log10(img.averageLuminosity(1.0e-10)), -10)
        
        img.setPixel(0, 0, newColor(1.0, 2.0, 3.0)); img.setPixel(0, 1, newColor(4.0, 5.0, 1.0))
        img.setPixel(1, 0, newColor(0.0, 1.5, 2.0)); img.setPixel(1, 1, newColor(2.0, 10.0, 3.0))
        check areClose(img.averageLuminosity(0.0), pow(36, 0.25))
    
    
    test "normalizeImage":
        # Changing pixel values
        img.setPixel(0, 0, newColor(1.0, 2.0, 3.0)); img.setPixel(0, 1, newColor(4.0, 51.0, 10.0))
        img.setPixel(1, 0, newColor(4.0, 13.5, 2.0)); img.setPixel(1, 1, newColor(24.0, 10.0, 3.0))
        
        let alpha = 2.0
        let factor = alpha / img.averageLuminosity

        normalizeImage(img, alpha)

        check areClose(img.averageLuminosity, alpha)
        check areClose(img.getPixel(0, 0).r, 1.0 * factor)
        check areClose(img.getPixel(0, 0).g, 2.0 * factor)
        check areClose(img.getPixel(0, 0).b, 3.0 * factor)

    
    test "clampImage":
        img.clampImage

        check areClose(img.getPixel(0, 0).r, 0.0)
        check areClose(img.getPixel(0, 0).g, 0.0)
        check areClose(img.getPixel(0, 0).b, 0.0)

        #Changing first pixel and testing over a non-null color
        img.setPixel(0, 0, newColor(1.0, 2.0, 3.0))
        img.clampImage

        check areclose(img.getPixel(0, 0).r, 0.5)
        check areClose(img.getPixel(0, 0).g, 2.0/3.0)
        check areClose(img.getPixel(0, 0).b, 0.75)