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

<div style="text-align: center;">
    <span style="color: blue; font-size: 24px;"> Ray </span>
</div>

What we have presented so far is sufficient to perform the conversion from a PFM image to a PNG image. However, if we want to render complex user-defined scenarios, it is necessary to implement constructs that allow us to model an observer external to the scenary. The first tool we need to develop is a type that allows us to uniquely characterize a ray:

```nim
type Ray* = object
    origin*: Point3D
    dir*: Vec3f
    tmin*: float32
    tmax*: float32
    depth*: int
```

To describe a light ray, we need to specify the point where it was emitted and the direction of propagation. We also provide the temporal limits of the ray's propagation and the number of reflections it has undergone within the simulated region.
The following features are fundamental
```nim

method apply*(transf: Transformation, ray: Ray): Ray {.base, inline.} =
    Ray(origin: apply(transf, ray.origin), dir: apply(transf, ray.dir), tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)

proc translate*(ray: Ray, vec: Vec3f): Ray {.inline.} = 
    Ray(origin: ray.origin + vec, dir: ray.dir, tmin: ray.tmin, tmax: ray.tmax, depth: ray.depth)

```
because they allow for applying generic transformations to the ray, and this step is essential for evaluating intersections with shapes in their local reference system.
If you want to evaluate ray position at a certain time t, you just have to use ```at``` procedure.

<div style="text-align: left;">
    <span style="color: blue; font-size: 15px;"> Example </span>
</div>

```nim
let
    trans = newTranslation(newVec3[float32](2, 0, 0))

var 
    origin = newPoint3D(0, 0, 0)        # Ray starting point
    dir = newVec3[float32](1, 0, 0)     # Ray direction (along x-axis)
    ray = newRay(origin, dir)           # tmin, tmax and depth have default values

# Printing ray variable content
echo ray

# Transforming ray (we are applying a translation, only ray.origin will change)
ray = trans.apply(ray)
echo ray.origin         # Here you should have (2, 0, 0)

# Checking ray position at unitary time
# Ray is starting in (2, 0, 0)
# Ray is propagating along x-axis (1, 0, 0)
# You should be in (3, 0, 0) after one second of evolution
echo ray.at(1)
```

