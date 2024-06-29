---
layout: page
title: Camera
parent: Roadmap
permalink: /roadmap/camera/
nav_order: 2
---

<div style="height: 40px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> Camera </span>
</div>
<div style="height: 40px;"></div>

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
proc fireRay*(cam: Camera; pixel: Point2D): Ray {.inline.} = 
    case cam.kind
    of ckOrthogonal:
        apply(cam.transform, newRay(newPoint3D(-1, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1), eX))
    of ckPerspective:
        apply(cam.transform, newRay(newPoint3D(-cam.distance, 0, 0), newVec3(cam.distance, (1 - 2 * pixel.u) * cam.aspect_ratio, 2 * pixel.v - 1)))
```

Both cameras are initialized such that the observer is positioned along the negative x-axis, and the screen lies on the xy-plane. The ray direction is perpendicular to the screen in the case of orthogonal projection, while it depends on the coordinates (u, v) otherwise. The returned ray in both cases is transformed to account for the actual arrangement of the camera in space.

<div style="height: 25px;"></div>
<div style="text-align: left;">
    <span style="color: blue; font-size: 20px;"> Example </span>
</div>
<div style="height: 25px;"></div>

```nim
let 
    # transformation to be associated with the chosen camera
    trans = newTranslation(newVec3f(-1, 0, 0))

var
    ray: Ray                                # Ray variable to store rays fired
    uv = newPoint2D(0.5, 0.5)               # (u, v) coordinates: we are firing right at the center of the screen
    pCam = newPerspectiveCamera(1.2, 1, trans)

# Firing ray, we need to give (u, v) coordinates as input
ray = pCam.fireRay(uv)
# Printing ray: it should have
#          ---> ray.origin = (-2, 0, 0)
#          ---> ray.dir    = (1, 0, 0)
echo ray
```

<div style="height: 40px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 28px;"> Pigments & BRDFs</span>
</div>
<div style="height: 40px;"></div>

We now need to define types that allow us to color the scenes we want to render and to evaluate how the various objects respond to the incidence of a ray. From a coding perspective, it is helpful to conceptualize the BRDF of a material as comprising two distinct types of information:

1. Properties influenced by the angle of incoming light and the observer's position.
2. Properties independent of direction, collectively referred to as pigment.

<div style="height: 25px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 20px;"> Pigments </span>
</div>
<div style="height: 25px;"></div>

Pigments typically illustrate the variation of a BRDF across a surface: according to this view, it's not the entire BRDF that changes from point to point, but only the pigment.
In PhotoNim code three different pigment choices are available: 


1. Uniform, which corresponds to an uniform color
2. Texture, which enables the user to renderer the earth
3. Checkered, which creates a color checkerboard

We implemented them as enum kinds, as you can see in the following code block.

```nim
type
    PigmentKind* = enum
        pkUniform, pkTexture, pkCheckered

    Pigment* = object
        case kind*: PigmentKind
        of pkUniform: 
            color*: Color

        of pkTexture: 
            texture*: ptr HDRImage

        of pkCheckered:
            grid*: tuple[color1, color2: Color, nsteps: int]
```

You can initialize a new pigment variable by means of ```new``` proc depending on which one you are willing to use.
The following procedure enables you to determine pigment at a specific (u, v) location and is crucial in the image rendering process:

```nim
proc getColor*(pigment: Pigment; uv: Point2D): Color =
    case pigment.kind: 
    of pkUniform: 
        return pigment.color

    of pkTexture: 
        var (col, row) = (floor(uv.u * pigment.texture.width.float32).int, floor(uv.v * pigment.texture.height.float32).int)
        if col >= pigment.texture.width: col = pigment.texture.width - 1
        if row >= pigment.texture.height: row = pigment.texture.height - 1

        return pigment.texture[].getPixel(col, row)

    of pkCheckered:
        let (col, row) = (floor(uv.u * pigment.grid.nsteps.float32).int, floor(uv.v * pigment.grid.nsteps.float32).int)
        return (if (col mod 2) == (row mod 2): pigment.grid.color1 else: pigment.grid.color2)
```

<div style="height: 25px;"></div>
<div style="text-align: center;">
    <span style="color: blue; font-size: 20px;"> BRDF </span>
</div>
<div style="height: 25px;"></div>

BRDF explains how a surface interacts with light by assuming that the light exits the surface at the same point where it initially struck.
In PhotoNim we focused on two different BRDF kinds:

1. Ideal diffusive surface
2. Reflective surface

```nim
type 
    BRDFKind* = enum 
        DiffuseBRDF, SpecularBRDF

    BRDF* = object
        pigment*: Pigment

        case kind*: BRDFKind
        of DiffuseBRDF:
            reflectance*: float32
        of SpecularBRDF:
            threshold_angle*: float32
```

All BRDF kinds have a Pigment data member which describes properties indipendent of direction: the specific parts of the two types are those linked to the direction of incidence of the ray. 
You can initialize a new BRDF variable using the ```new``` proc, depending on which one you are willing to use.
It's now crucial to determine how a surface responds to an incoming ray. To achieve this, we can utilize the "eval" procedure.

```nim
proc eval*(brdf: BRDF; normal: Normal, in_dir, out_dir: Vec3f, uv: Point2D): Color {.inline.} =
    case brdf.kind: 
    of DiffuseBRDF: 
        return brdf.pigment.getColor(uv) * (brdf.reflectance / PI)

    of SpecularBRDF: 
        if abs(arccos(dot(normal.Vec3f, in_dir)) - arccos(dot(normal.Vec3f, out_dir))) < brdf.threshold_angle: 
            return brdf.pigment.getColor(uv)
        else: return BLACK
```

<div style="height: 25px;"></div>
<div style="text-align: left;">
    <span style="color: blue; font-size: 20px;"> Example </span>
</div>
<div style="height: 25px;"></div>

```nim
#---------------------------------------#
#        Pigment types and procs        #
#---------------------------------------#
var
    image = newHdrImage(2, 2)
    unif = newUniformPigment(newColor(1, 0.5, 0.4))
    text = newTexturePigment(image)
    chec= newCheckeredPigment(newColor(0.5, 1, 0.3), newColor(1, 0.5, 0.4), 2)

# Setting image pixels different from (0, 0, 0) or black background color
image.setPixel(1, 1, newColor(1, 0.5, 0.4))
image.setPixel(0, 0, newColor(0.5, 1, 0.3))

# Using getColor procedure in order to show pigment evaluation
echo "Getting uniform pigment: "
echo getColor(unif, newPoint2D(0.2, 0.2)).Vec3f       # You should get (1, 0.5, 0.4)

echo '\n'
echo "Getting texture pigment: "
echo getColor(text, newPoint2D(0.2, 0.1)).Vec3f       # You shoulg get (0.5, 1, 0.3)
echo getColor(text, newPoint2D(0.8, 0.9)).Vec3f       # You shoulg get (1, 0.5, 0.4)
echo getColor(text, newPoint2D(0.6, 0.3)).Vec3f       # You shoulg get (0, 0, 0)
echo getColor(text, newPoint2D(0.3, 0.6)).Vec3f       # You shoulg get (0, 0, 0)

echo '\n'
echo "Getting checkered pigment: "
echo getColor(chec, newPoint2D(0.2, 0.1)).Vec3f       # You shoulg get (0.5, 1, 0.3)
echo getColor(chec, newPoint2D(0.8, 0.9)).Vec3f       # You shoulg get (0.5, 1, 0.3)
echo getColor(chec, newPoint2D(0.6, 0.3)).Vec3f       # You shoulg get (1, 0.5, 0.4)
echo getColor(chec, newPoint2D(0.3, 0.6)).Vec3f       # You shoulg get (1, 0.5, 0.4)



#---------------------------------------#
#         BRDFs types and procs         #
#---------------------------------------#
var
    # Variables needed for BRDF evaluation
    pigm = newUniformPigment(newColor(1, 1, 1))
    norm = newNormal(0, 0, 1)
    in_dir = newVec3f(0, 1, -1).normalize
    out_dir = newVec3f(0, 1, 1).normalize
    uv = newPoint2D(0.5, 0.5)

    # BRDF variables of different possible kinds
    diff = newDiffuseBRDF(pigm, 0.3)
    refl = newSpecularBRDF(pigm, 50)

echo '\n'
echo '\n'
echo "Evaluating diffusive BRDF: "
echo eval(diff, norm, in_dir, out_dir, uv).Vec3f        # You should see (0.3, 0.3, 0.3)/PI
echo eval(refl, norm, in_dir, out_dir, uv).Vec3f        # You should see (0, 0, 0)

echo '\n'
echo "Changing threshold angle value, now 35°: "
refl.threshold_angle = 35
echo eval(refl, norm, in_dir, out_dir, uv).Vec3f        # You should see (1, 1, 1)
```
