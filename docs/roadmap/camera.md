---
layout: page
title: Camera
parent: Roadmap
permalink: /roadmap/camera/
nav_order: 1
---

The ray tracing code "PhotoNim" facilitates the conversion of images from .pfm to .png format and the rendering of intricate scenes composed of geometric figures. Consequently, it is essential to implement types and functionalities that enable efficient image processing. 

<div style="text-align: center;">
    <span style="color: blue; font-size: 24px;"> Color </span>
</div>

Within this code, we employ RGB color encoding: Color type is a ```distinct Vec3f``` because we need to store the triplet of numbers that defines the color of a pixel. 
If you want to create a new Color variable, you should specify r, g and b values such as following:
```nim
var
    r = 0.2
    g = 0.4
    b = 0.1
    col = newColor(r, g, b)
```
You can access r, g, and b values using appropriate procedures such as
```nim
echo col.r
echo col.g
echo col.b
```
What you should see on your terminal are the three values that you used in the previous initialization.
The operations of addition and subtraction between colors, as well as multiplication and division by a scalar, are defined.


<div style="text-align: center;">
    <span style="color: blue; font-size: 24px;"> HdrImage </span>
</div>

The images we are interested in are matrices of pixels, each of which has its own color. The most logical way to define high dynamic range (HDR) images in our code is as a sequence of colors. 

```nim
type HdrImage* = object
    width*, height*: int
    pixels*: seq[Color]
```

Each color is uniquely associated with a particular pixel, which can be determined via providing an x-coordinate index and a y-coordinate index. The values of x and y are constrained by image width and image height respectively.
Given that the image is two-dimensional, while sequences are one-dimensional, it is necessary to have a procedure that allows accessing the sequence of colors correctly and efficiently: pixelOffset does just that, returning the index of the memory cell dedicated to a particular pixel.

``` nim
proc pixelOffset(img: HdrImage; x, y: int): int {.inline.} = x + img.width * y
```

Appropriate functionalities are available for setting or retrieving the color of a pixel: equally fundamental are the procedures that allow for tone mapping, ensuring the rendering of images with correct management of brightness and colors. You can read or write a .pfm file by using appropriate procedure implemented in PhotoNim.nim file.

<div style="text-align: left;">
    <span style="color: blue; font-size: 15px;"> Example </span>
</div>

```nim
# Defining a HdrImage variable
var im = newHdrImage(2, 2)

# Setting pixel value
im.setPixel(1, 1, newColor(0.1, 0.3, 0.1))

# Getting pixel value
echo im.getPixel(0, 0)

# Computing avarage luminosity
echo im.averageLuminosity()

# Tone Mapping, crucial for production of images with proper color management.
im.toneMapping(1, 0.23)
```