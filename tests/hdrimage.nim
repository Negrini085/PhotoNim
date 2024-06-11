import std/[unittest, streams, math, sequtils, endians, strutils]
import PhotoNim


proc readFloat*(stream: Stream, endianness: Endianness = littleEndian): float32 = 
    ## Reads a float from a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32 = stream.readFloat32
    if endianness == littleEndian: littleEndian32(addr result, addr tmp)
    else: bigEndian32(addr result, addr tmp)

proc writeFloat*(stream: Stream, value: float32, endianness: Endianness = littleEndian) = 
    ## Writes a float to a stream accordingly to the given endianness (default is littleEndian)
    var tmp: float32
    if endianness == littleEndian: littleEndian32(addr tmp, addr value)
    else: bigEndian32(addr tmp, addr value)
    stream.write(tmp)


proc readPFM*(stream: FileStream): tuple[img: HDRImage, endian: Endianness] {.raises: [CatchableError].} =
    assert stream.readLine == "PF", "Invalid PFM magic specification: required 'PF'"
    let sizes = stream.readLine.split(" ")
    assert sizes.len == 2, "Invalid image size specification: required 'width height'."

    var width, height: int
    try:
        width = parseInt(sizes[0])
        height = parseInt(sizes[1])
    except:
        raise newException(CatchableError, "Invalid image size specification: required 'width height' as unsigned integers")
    
    try:
        let endianFloat = parseFloat(stream.readLine)
        if endianFloat == 1.0:
            result.endian = bigEndian
        elif endianFloat == -1.0:
            result.endian = littleEndian
        else:
            raise newException(CatchableError, "")
    except:
        raise newException(CatchableError, "Invalid endianness specification: required bigEndian ('1.0') or littleEndian ('-1.0')")

    result.img = newHDRImage(width, height)

    var r, g, b: float32
    for y in countdown(height - 1, 0):
        for x in 0..<width:
            r = readFloat(stream, result.endian)
            g = readFloat(stream, result.endian)
            b = readFloat(stream, result.endian)
            result.img.setPixel(x, y, newColor(r, g, b))

proc writePFM*(stream: FileStream, img: HDRImage, endian: Endianness = littleEndian) = 
    stream.writeLine("PF")
    stream.writeLine(img.width, " ", img.height)
    stream.writeLine(if endian == littleEndian: -1.0 else: 1.0)

    var c: Color
    for y in countdown(img.height - 1, 0):
        for x in 0..<img.width:
            c = img.getPixel(x, y)
            stream.writeFloat(c.r, endian)
            stream.writeFloat(c.g, endian)
            stream.writeFloat(c.b, endian)


suite "HDRImage unittest":
    
    setup:
        var img = newHDRImage(4, 2)
        
    teardown:
        discard img

    test "newHDRImage proc":
        check img.width == 4 and img.height == 2
        for i in 0..<img.height*img.width: check img.pixels[i] == BLACK

    test "set/getPixel proc":
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
    
    
suite "ToneMapping test":
    setup:
        var img = newHDRImage(2, 2)
    
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


suite "HDRImage streaming test":

    test "write/readFloat proc":
        var stream = newFileStream("files/wpFloat.txt", fmWrite)

        stream.writeFloat(float32(1.0), bigEndian)
        stream.close

        stream = openFileStream("files/wpFloat.txt", fmRead)
        check stream.readFloat(bigEndian) == 1.0
        stream.close
    

    test "write/parsePFM proc":       
        var stream = newFileStream("files/wpPFM.txt", fmWrite)
        var img1 = newHDRImage(10, 15)
        
        # Changing some pixel in order to test writePFM & readPFM procedures
        img1.setPixel(3, 4, newColor(1.0, 2.0, 3.0))
        img1.setPixel(6, 3, newColor(3.4, 17.8, 128.1))
        img1.setPixel(8, 9, newColor(35.1, 18.2, 255.0))

        stream.writePFM(img1, bigEndian)
        stream.close
        
        stream = openFileStream("files/wpPFM.txt", fmRead)
        let img2 = stream.readPFM.img
        stream.close

        check areClose(img2.getPixel(3, 4), newColor(1.0, 2.0, 3.0))
        check areClose(img2.getPixel(6, 3), newColor(3.4, 17.8, 128.1))
        check areClose(img2.getPixel(8, 9), newColor(35.1, 18.2, 255.0))  
    
