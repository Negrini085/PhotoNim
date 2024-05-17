---
layout: page
title: Camera
parent: Roadmap
permalink: /roadmap/camera/
nav_order: 1
---

The ray tracing code "PhotoNim" facilitates the conversion of images from .pfm to .png format and the rendering of intricate scenes composed of geometric figures. Consequently, it is essential to implement types and functionalities that enable efficient image processing. Within this code, we employ RGB color encoding: Color type is a ```distinct Vec3f``` because we need to store the triplet of numbers that defines the color of a pixel. 
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
