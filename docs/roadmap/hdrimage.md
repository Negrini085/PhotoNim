---
layout: page
title: HDRImage
parent: Roadmap
permalink: /roadmap/hdrimage/
nav_order: 1
---

<div style="text-align: center;">
    <span style="color: black; font-size: 40px;"> PhotoNim HDRImage submodule </span>
</div>

The ray tracing code "PhotoNim" facilitates the conversion of images from .pfm to .png format and the rendering of intricate scenes composed of geometric figures. 
Consequently, it is essential to implement types and functionalities that enable efficient image processing. 

<div style="height: 40px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> Color </span>
</div>
<div style="height: 40px;"></div>

Within this code, we employ RGB color encoding: Color type is a ```distinct Vec3``` because we need to store the triplet of numbers that defines the color of a pixel. 
If you want to create a new Color variable, you should specify r, g and b values using the:

```nim
type Color* {.borrow: `.`.} = distinct Vec3

proc newColor*(r, g, b: float32): Color {.inline.} = Color([r, g, b])
```

You can access r, g, and b values using appropriate procedures such as

```nim
echo col.r
echo col.g
echo col.b
```

What you should see on your terminal are the three values that you used in the previous initialization.
The operations of addition and subtraction between colors, as well as multiplication and division by a scalar, are defined. 
Indeed, a procedure to do multiplication of two color variables:

```nim
proc `*`*(a: Color, b: Color): Color {.inline.} =
    newColor(a.r*b.r, a.g*b.g, a.b*b.b)
``` 

which will be used in scenery rendering module.

<div style="height: 25px;"></div>
<div style="text-align: left;">
    <span style="color: blue; font-size: 20px;"> Example </span>
</div>
<div style="height: 25px;"></div>

```nim
var
    c1 = newColor(0.1, 0.2, 0.3)
    c2 = newColor(1, 0.9, 0.5)

echo ' '
echo "First color: ", $c1        # You should get (0.1, 0.2, 0.3)
echo "Second color: ", $c2       # You should get (1.0, 0.9, 0.5)

echo ' '
echo "Color sum: ", c1 + c2     # You should get (1.1, 1.1, 0.8)
echo "Color dif: ", c1 - c2     # You should get -(0.9, 0.7, 0.2)

echo ' '
echo "Color *: ", c1 * c2               # You should get(0.1, 0.18, 0.15)
echo "Color lum: ", c1.luminosity()     # You should get 0.2
```

<div style="height: 40px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> HDRImage </span>
</div>
<div style="height: 40px;"></div>

The images we are interested in are matrices of pixels. The most logical way to define high dynamic range (HDR) images in our code is as a sequence of colors. 

```nim
type HDRImage* = object
    width*, height*: int
    pixels*: seq[Color]
```

Each color is uniquely associated with a particular pixel, which can be determined via providing an x-coordinate index and a y-coordinate index. The values of x and y are constrained by image width and image height respectively.
Given that the image is two-dimensional, while sequences are one-dimensional, it is necessary to have a procedure that allows accessing the sequence of colors correctly and efficiently: pixelOffset does just that, returning the index of the memory cell dedicated to a particular pixel.

``` nim
proc pixelOffset(img: HDRImage; x, y: int): int {.inline.} = x + img.width * y
```

Appropriate functionalities are available for setting or retrieving the color of a pixel:

- ```proc getPixel*(img: HDRImage; x, y: int): Color```, to get pixel value giving x and y indexes

- ```proc setPixel*(img: var HDRImage; x, y: int, color: Color)```, to set pixel value giving x and y indexes and input color

Equally fundamental are the procedures that allow for tone mapping, ensuring the rendering of images with correct management of brightness and colors. 
You can read or write a .pfm file by using appropriate procedure implemented in PhotoNim.nim file.

```nim
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
        result.endian = 
            if endianFloat == 1.0: bigEndian
            elif endianFloat == -1.0: littleEndian
            else: raise newException(CatchableError, "")

    except: raise newException(CatchableError, "Invalid endianness specification: required bigEndian ('1.0') or littleEndian ('-1.0')")

    result.img = newHDRImage(width, height)

    var r, g, b: float32
    for y in countdown(height - 1, 0):
        for x in countup(0, width - 1):
            r = readFloat(stream, result.endian)
            g = readFloat(stream, result.endian)
            b = readFloat(stream, result.endian)
            result.img.setPixel(x, y, newColor(r, g, b))
```

You can chose the endianness of the output and you can read files with both kinds of endianness encoding.

```nim
proc savePFM*(img: HDRImage; pfmOut: string, endian: Endianness = littleEndian) = 
    var stream = newFileStream(pfmOut, fmWrite) 
    defer: stream.close

    if stream.isNil: quit fmt"Error! An error occured while saving an HDRImage to {pfmOut}"

    stream.writeLine("PF")
    stream.writeLine(img.width, " ", img.height)
    stream.writeLine(if endian == littleEndian: -1.0 else: 1.0)

    var c: Color
    for y in countdown(img.height - 1, 0):
        for x in countup(0, img.width - 1):
            c = img.getPixel(x, y)
            stream.writeFloat(c.r, endian)
            stream.writeFloat(c.g, endian)
            stream.writeFloat(c.b, endian)


proc savePNG*(img: HDRImage; pngOut: string, alpha, gamma: float32, avLum: float32 = 0.0) =
    let 
        toneMappedImg = img.toneMap(alpha, avLum)
        gFactor = 1 / gamma

    var 
        pixelsString = newStringOfCap(3 * img.pixels.len)
        c: Color

    for y in 0..<img.height:
        for x in 0..<img.width:
            c = toneMappedImg.getPixel(x, y)
            pixelsString.add (255 * pow(c.r, gFactor)).char
            pixelsString.add (255 * pow(c.g, gFactor)).char
            pixelsString.add (255 * pow(c.b, gFactor)).char

    let successStatus = savePNG24(pngOut, pixelsString, img.width, img.height)
    if not successStatus: quit fmt"Error! An error occured while saving an HDRImage to {pngOut}"
```

<div style="height: 25px;"></div>
<div style="text-align: left;">
    <span style="color: blue; font-size: 20px;"> Example </span>
</div>
<div style="height: 25px;"></div>

```nim
# Defining a HDRImage variable
var im = newHDRImage(2, 2)

# Setting pixel value
im.setPixel(1, 1, newColor(0.1, 0.3, 0.1))

# Getting pixel value
echo "Pixel (0, 0):", im.getPixel(0, 0)      # You should get (0, 0, 0)
echo "Pixel (1, 1):", im.getPixel(1, 1)      # You should get (0.1, 0.3, 0.1)

# Tone mapping 
echo "Image avLum: ", im.avLuminosity()
im.applyToneMap(1, 0.23)    
echo "Pixel (1, 1): ", im.getPixel(1, 1)     # You should get (0.0813, 0.2439, 0.0813) 
```
