import std/[unittest, streams, math, sequtils]
import PhotoNim


#------------------------------------#
#       Color type test suite        #
#------------------------------------#
suite "Color":

    setup:
        var 
            col1 = newColor(1, 0.5, 0.3)
            col2 = newColor(0.3, 0.2, 1)
    
    teardown:
        discard col1
        discard col2
    
    test "Const":
        # Checks wether constants are well defined or not

        check areClose(BLACK, newColor(0, 0, 0))
        check areClose(WHITE, newColor(1, 1, 1))
        check areClose(RED,   newColor(1, 0, 0))
        check areClose(GREEN, newColor(0, 1, 0))
        check areClose(BLUE,  newColor(0, 0, 1))
    

    test "newColor proc":
        # Checks newColor proc
    
        check areClose(col1, newColor(1, 0.5, 0.3))
        check areClose(col2, newColor(0.3, 0.2, 1))

    
    test "r, g, b procs":
        # Checks r, g, b procs

        check areClose(col1.r, 1.0)
        check areClose(col1.g, 0.5)
        check areClose(col1.b, 0.3)

        check areClose(col2.r, 0.3)
        check areClose(col2.g, 0.2)
        check areClose(col2.b, 1.0)
    

    test "Color operations":
        # Checks operations defined on colors
        var appo = newColor(0, 0, 0)

        check areClose(col1+col2, newColor(1.3, 0.7, 1.3))
        check areClose(col1-col2, newColor(0.7, 0.3, -0.7))

        appo += col1; check areClose(appo, col1)
        appo -= col1; check areClose(appo, BLACK)

        check areClose(2 * col1, newColor(2, 1, 0.6))
        check areClose(col2 * 2, newColor(0.6, 0.4, 2))
        check areClose(col1/2, newColor(0.5, 0.25, 0.15))

        appo = col1
        appo *= 2; check areClose(appo, newColor(2, 1, 0.6))
        appo /= 2; check areClose(appo, col1)

        check areClose(col1*col2, newColor(0.3, 0.1, 0.3))


    test "luminosity proc":
        # Checks color luminosity (we will use it in order to clamp images)
        
        check areClose(col1.luminosity(), 0.65)
        check areClose(col2.luminosity(), 0.6)




#-------------------------------------#
#      HdrImage type test suite       #
#-------------------------------------#
suite "HDRImage":
    
    setup:
        var 
            img = newHDRImage(4, 2)
        
    teardown:
        discard img


    test "newHDRImage proc":
        # Checking newHDRImage proc
        check img.width == 4 and img.height == 2
        check img.pixels.len == 8
        for i in 0..<img.height*img.width: check img.pixels[i] == BLACK
    

    test "set/getPixel proc":
        # Checking set/getPixel proc
        img.setPixel(1, 1, newColor(1.0, 2.0, 3.0))
        
        check areClose(img.getPixel(1, 0).r, 0.0)
        check areClose(img.getPixel(1, 0).g, 0.0)
        check areClose(img.getPixel(1, 0).b, 0.0)       

        check areClose(img.getPixel(1, 1).r, 1.0)
        check areClose(img.getPixel(1, 1).g, 2.0)
        check areClose(img.getPixel(1, 1).b, 3.0)


    test "avLuminosity proc":     
        # Testing Color luminosity proc
        check areClose(BLACK.luminosity, 0.0)
        check areClose(newColor(1.0, 2.0, 3.0).luminosity, 2.0)

        # Testing with blanck image and delta default value
        check areClose(log10(img.avLuminosity(1.0e-10)), -10)
        
        var newImg = newHDRImage(2, 2)
        newImg.setPixel(0, 0, newColor(1.0, 2.0, 3.0)); newImg.setPixel(0, 1, newColor(4.0, 5.0, 1.0))
        newImg.setPixel(1, 0, newColor(0.0, 1.5, 2.0)); newImg.setPixel(1, 1, newColor(2.0, 10.0, 3.0))
        check areClose(newImg.avLuminosity(0.0), pow(36, 0.25))
    


#-------------------------------------#
#       ToneMapping test suite        #
#-------------------------------------#    
suite "ToneMapping test":
    setup:
        var img = newHDRImage(2, 2)

    teardown:
        discard img


    test "image clamping":
        proc clamp(x: float32): float32 {.inline.} = x / (1.0 + x)
        proc clampColor(x: Color): Color = newColor(clamp(x.r), clamp(x.g), clamp(x.b))

        img.pixels.apply(clampColor)

        check areClose(img.getPixel(0, 0), BLACK)

        # Changing first pixel and testing over a non-null color
        img.setPixel(0, 0, newColor(1.0, 2.0, 3.0))
        img.pixels.apply(clampColor)

        check areclose(img.getPixel(0, 0), newColor(0.5, 2.0/3.0, 0.75))


    test "image normalization":
        img.setPixel(0, 0, newColor(1.0, 2.0, 3.0)); img.setPixel(0, 1, newColor(4.0, 51.0, 10.0))
        img.setPixel(1, 0, newColor(4.0, 13.5, 2.0)); img.setPixel(1, 1, newColor(24.0, 10.0, 3.0))
        
        let alpha = 2.0
        let factor = alpha / img.avLuminosity

        img.pixels.apply(proc(pix: Color): Color = pix * factor)

        check areClose(img.avLuminosity, alpha)
        check areClose(img.getPixel(0, 0), factor * newColor(1, 2, 3))



#-----------------------------------------#
#   HDRImage streaming procs test suite   #
#-----------------------------------------#
suite "HDRImage streaming test":

    setup:
        var stream: FileStream
    
    teardown:
        discard stream

    test "write/readFloat proc":
        stream = newFileStream("files/wpFloat.txt", fmWrite)
        stream.writeFloat(float32(1.0), bigEndian)
        stream.close()

        stream = newFileStream("files/wpFloat.txt", fmRead)
        check stream.readFloat(bigEndian) == 1.0
        stream.close()
    

    test "savePFM/readPFM procs":       
        var img1 = newHDRImage(10, 15)
        
        # Changing some pixel in order to test writePFM & readPFM procedures
        img1.setPixel(3, 4, newColor(1.0, 2.0, 3.0))
        img1.setPixel(6, 3, newColor(3.4, 17.8, 128.1))
        img1.setPixel(8, 9, newColor(35.1, 18.2, 255.0))

        img1.savePFM("files/wpPFM.txt", bigEndian)
        
        stream = openFileStream("files/wpPFM.txt", fmRead)
        let img2 = stream.readPFM.img
        stream.close

        check areClose(img2.getPixel(3, 4), newColor(1.0, 2.0, 3.0))
        check areClose(img2.getPixel(6, 3), newColor(3.4, 17.8, 128.1))
        check areClose(img2.getPixel(8, 9), newColor(35.1, 18.2, 255.0))  
    
