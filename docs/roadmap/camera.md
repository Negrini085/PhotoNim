---
layout: page
title: Camera
parent: Roadmap
permalink: /roadmap/camera/
nav_order: 1
---

<div style="text-align: center;">
    <span style="color: black; font-size: 40px;"> PhotoNim Camera submodule </span>
</div>

The ray tracing code "PhotoNim" facilitates the conversion of images from .pfm to .png format and the rendering of intricate scenes composed of geometric figures. Consequently, it is essential to implement types and functionalities that enable efficient image processing. 


<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> Color </span>
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
    <span style="color: blue; font-size: 28px;"> HdrImage </span>
</div>


The images we are interested in are matrices of pixels. The most logical way to define high dynamic range (HDR) images in our code is as a sequence of colors. 

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
    <span style="color: blue; font-size: 28px;"> Ray </span>
</div>


What we have presented so far is sufficient to perform the conversion from a PFM image to a PNG image. However, if we want to render complex user-defined scenarios, it is necessary to implement constructs that allow us to model an observer external to the scenary. PhotoNim is a backward ray tracer, meaning that we are tracing rays from the camera to the light sources. The first tool we need to develop is indeed a type that allows us to uniquely characterize a ray:

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
    trans = newTranslation(newVec3(float32 2, 0, 0))

var 
    origin = ORIGIN3D        # Ray starting point
    dir = newVec3(float32 1, 0, 0)     # Ray direction (along x-axis)
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


<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> Camera </span>
</div>


Rays are employed for image reconstruction, a task which, within PhotoNim, can be executed through two distinct modalities:
1. orthogonal
2. perspective
To implement a projection, it is necessary to define the position of the observer and the direction in which they are looking. Typically, this involves defining a screen for which the aspect ratio must be specified. The distance between the screen and the observer is finite in the case of a perspective projection, otherwise it is infinite. The screen demarcates the visible space region, that will then be rendered. To cast a ray at a specific screen position, it is necessary to provide two coordinates, denoted as (u, v), which determine the light ray direction as follows:

![uv_mapping](https://github.com/Negrini085/PhotoNim/assets/139368862/8ef9c30f-7143-43ab-975b-50025c7c04c3)

In PhotoNim we used ```enum``` in order to define different kind of cameras: as you can see, a further data member it's needed for perspective camera in order to specify the distance between the observer and the screen.
```nim
type
    CameraKind* = enum
        ckOrthogonal, ckPerspective

    Camera* = object of RootObj
        transf*: Transformation
        aspect_ratio*: float32

        case kind: CameraKind
        of ckOrthogonal: discard
        of ckPerspective: 
            distance: float32 
```
We need to associate a transformation to a camera variable in order to place it in space as we wish. The only procedure needed other than constructors

```nim
# Create a new orthogonal camera variable with given parameters
proc newOrthogonalCamera*(a: float32; transf = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckOrthogonal, transf: transf, aspect_ratio: a)

# Create a new perspective camera varible with given parameters
proc newPerspectiveCamera*(a, d: float32; transf = Transformation.id): Camera {.inline.} = 
    Camera(kind: ckPerspective, transf: transf, aspect_ratio: a, distance: d)
```

is the one that enables the user to fire rays at a specific screen location: clearly this differs between different kinds of camera.

```nim
proc fire_ray*(cam: Camera; pixel: Point2D): Ray {.inline.} = 
    case cam.kind
    of ckOrthogonal:
        apply(cam.transform, newRay(newPoint3D(-1, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1), eX))
    of ckPerspective:
        apply(cam.transform, newRay(newPoint3D(-cam.distance, 0, 0), newVec3(cam.distance, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1)))
```

Both cameras are initialized such that the observer is positioned along the negative x-axis, and the screen lies on the xy-plane. The ray direction is perpendicular to the screen in the case of orthogonal projection, while it depends on the coordinates (u, v) otherwise. The returned ray in both cases is transformed to account for the actual arrangement of the camera in space.

<div style="text-align: left;">
    <span style="color: blue; font-size: 15px;"> Example </span>
</div>

```nim
let 
    # transformation to be associated with the chosen camera
    trans = newTranslation(newVec3(float32 -1, 0, 0))

var
    ray: Ray                                # Ray variable to store rays fired
    uv = newPoint2D(0.5, 0.5)               # (u, v) coordinates: we are firing right at the center of the screen
    pCam = newPerspectiveCamera(1.2, 1, trans)

# Firing ray, we need to give (u, v) coordinates as input
ray = pCam.fire_ray(uv)
# Printing ray: it should have
#          ---> ray.origin = (-2, 0, 0)
#          ---> ray.dir    = (1, 0, 0)
echo ray
```


<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> ImageTracer </span>
</div>


We now need to bind the HdrImage type to one of the camera kinds in order to render scenarios: the ```ImageTracer``` type is exactly what we are looking for considering that its data members are an ```HdrImage``` variable and a ```Camera``` one.

```nim
type ImageTracer* = object
    image*: HdrImage
    camera*: Camera
```

ImageTracer is responsible for casting rays to the various image pixels, working with row and column indices that allow access to specific memory cells in the color sequence. We have implemented two functionalities, which enable casting a ray to a specific pixel on the screen or to all pixels present. The first one compute index conversion such as

```nim
proc fire_ray*(im_tr: ImageTracer; x, y: int, pixel = newPoint2D(0.5, 0.5)): Ray {.inline.} =
    im_tr.camera.fire_ray(newPoint2D((x.float32 + pixel.u) / im_tr.image.width.float32, 1 - (y.float32 + pixel.v) / im_tr.image.height.float32))
```

As we transition from continuous (u, v) to discrete (x, y), we also need to decide which region of the pixel to hit, hence one of the inputs is Point2D labeled as pixel. By default, we work by hitting the center, meaning passing a tuple with both entries initialized to 0.5.
To shoot rays at all the pixels on the screen, one simply needs to iterate over the row and column indices.

```nim
proc fire_all_rays*(im_tr: var ImageTracer) = 
    for x in 0..<im_tr.image.height:
        for y in 0..<im_tr.image.width:
            discard im_tr.fire_ray(x, y)
            let 
                r = (1 - exp(-float32(x + y)))
                g = y / im_tr.image.height
                b = pow((1 - x / im_tr.image.width), 2.5)
            im_tr.image.setPixel(x, y, newColor(r, g, b))
```

Here we are creating a colormap associating each pixel with a color depending on the row and column index.

<div style="text-align: left;">
    <span style="color: blue; font-size: 15px;"> Example </span>
</div>

```nim
let
    trans = newTranslation(newVec3(float32 -1, 0, 0))  # Transformation to apply to camera

var
    ray: Ray
    img = newHdrImage(5, 5)
    pcam = newPerspectiveCamera(1, 1, trans)
    im_tr = ImageTracer(image: img, camera: pcam)   # ImageTracer initialization


# Procedure to fire a single ray
# We are choosing middle pixel
# Ray direction must be along x-axis
ray = im_tr.fire_ray(2, 2)
echo ray.origin             # Should be (-2, 0, 0)
echo ray.dir                # Should be (1, 0, 0)

# Procedure to fire all rays, HdrImage elements will change value
# We are going to check using echo, we find no initialization value (0, 0, 0)
im_tr.fire_all_rays()
echo getPixel(im_tr.image, 2, 2)
```