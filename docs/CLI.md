---
layout: page
title: PhotoNim CLI
permalink: /cli/
nav_order: 2
---

# PhotoNim CLI
The process to use the PhotoNim CLI is quite simple:
- First, you have to build the `PhotoNim` executable using `nimble`:
```bash
    nimble build
```
- Then you can run it to see displayed an helper screen that shows all PhotoNim CLI commands: 
```bash
    ./PhotoNim
```
```bash
    PhotoNim: a CPU raytracer written in Nim.

    Usage:
        ./PhotoNim pfm2png <input> [<output>] [--alpha=<alpha> --gamma=<gamma>]
        ./PhotoNim demo (perspective|orthogonal) [<output>] [--width=<width> --height=<height> --angle=<angle>]

    Options:
        --alpha=<alpha>     Color renormalization factor. [default: 0.18]
        --gamma=<gamma>     Gamma correction factor. [default: 1.0]
        --width=<width>     Image wisth. [default: 1600]
        --height=<height>   Image height. [default: 1000]
        --angle=<angle>     Rotation angle around z axis
        
        -h --help           Show this helper screen.
        --version           Show PhotoNim version.
```
- You can use the `help` command to inspect a specific command helper screen:
```bash
    ./PhotoNim help demo
```
```bash

```

### The `pfm2png` command
Using PhotoNim's `pfm2png` it is possible to convert an HDR image stored in a PFM format to a PNG.
This can be achieved in two ways: using PhotoNim CLI or by calling the `pfm2png` proc directly from your Nim code.

you can run it by specifing the command `pfm2png`, followed by its arguments. 

For this example we will use the [memorial.pfm](https://www.pauldebevec.com/Research/HDR/PFM/) image.
<!-- ### PhotoNim CLI -->

### The `demo` command

### The `render` command