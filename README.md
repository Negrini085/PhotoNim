# PhotoNim - a CPU RayTracer written in Nim
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Negrini085/PhotoNim/ci-action.yml)
![GitHub License](https://img.shields.io/github/license/Negrini085/PhotoNim)
![GitHub Release](https://img.shields.io/github/v/release/Negrini085/PhotoNim)
![GitHub repo size](https://img.shields.io/github/repo-size/Negrini085/PhotoNim)
![GitHub last commit](https://img.shields.io/github/last-commit/Negrini085/PhotoNim)

# Installation
PhotoNim is available and tested for Linux, MacOSX and Windows machines.
To install it you can choose which approach you find the most fitting for you. 

## Prerequisites
To use PhotoNim you must have installed the [Nim](https://github.com/nim-lang/Nim) programming language (version 2.0 or higher) on your machine.
To install the latest version on Unix you could run the following command:
```sh
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
```
To install it on other OSs or to install previous versions, please refer to the [Nim installation guide](https://nim-lang.org/install.html).
Most of Nim installation already install the official Nim package manager [Nimble](https://github.com/nim-lang/nimble). You can verify it by running:
```sh
which nimble
```

### Installing from Git
Choose the appropriate protocol (HTTPS or SSH) and clone the [PhotoNim repository](https://github.com/Negrini085/PhotoNim) using the command
```bash
git clone https://github.com/Negrini085/PhotoNim.git    # for HTTPS
git clone git@github.com:Negrini085/PhotoNim.git        # for SSH
```

### Installing from Tarball
Download the latest tarball from [here](https://github.com/Negrini085/PhotoNim/releases) and extract the tarball by running the command
```sh
tar -xzf PhotoNim-<version>.tar.gz
```

### Installing using Nimble
Install PhotoNim using nimble by running
```sh
nimble install PhotoNim
```

## Dependencies
PhotoNim depends on the following packages
- [docopt](https://github.com/docopt/docopt.nim) >= 0.6
- [nimPNG](https://github.com/jangko/nimPNG) >= 0.3

which can be installed using Nimble
```sh
cd PhotoNim && nimble install
```

Other dependencies are used to generate animations:
- [GNU Parallel](https://www.gnu.org/software/parallel/)
- [FFmpeg](https://ffmpeg.org/download.html)


## Verifying the Installation
After installing PhotoNim and its dependencies, you can verify the installation by running PhotoNim test suites using Nimble:
```sh
nimble test
```

# Usage

## PhotoNim CLI
To use PhotoNim CLI you will first need to build the project executable. \
You can do it from the root directory in different ways:
- using nimble build command
```sh
nimble build
```
- or explicitly compiling the source code
```sh
nim c -d:release PhotoNim.nim
```

Both these commands will generate an executable, called `PhotoNim` and located in the root directory. 
You are now ready to use PhotoNim CLI: run the executable to see displayed the list of all commands
```sh
./PhotoNim
```
```sh
Usage:
    ./PhotoNim help [<command>]
    ./PhotoNim pfm2png <input> [<output>] [--a=<alpha> --g=<gamma> --lum=<avlum>]
    ./PhotoNim demo (persp | ortho) [<output>] [--w=<width> --h=<height> --angle=<angle>]
```

### The `help` command
You can use the `help` command to inspect a specific command helper screen:
```sh
./PhotoNim help demo
```

```sh
PhotoNim CLI `demo` command:

Usage:
    ./PhotoNim demo (persp | ortho) [<output>] [--w=<width> --h=<height> --angle=<angle>]

Options:
    persp | ortho       Perspective or Orthogonal Camera kinds.
    <output>            Path to the output HDRImage. [default: "images/demo.pfm"]
    --w=<width>         Image width. [default: 1600]
    --h=<height>        Image height. [default: 900]
    --angle=<angle>     Rotation angle around z axis. [default: 10]
```

You can also use `help` without passing any command to see displayed the full PhotoNim CLI helper screen 
(this works in the same ways as passing `(-h | --help)` flags).

### The `pfm2png` command
Using the `pfm2png` command it is possible to convert an High Dynamic Range (HDR) image stored in a [PFM](https://www.pauldebevec.com/Research/HDR/PFM/) (Portable Float Map) format to an Low Dynamic Range (LDR) in the widely-used [PNG](https://en.wikipedia.org/wiki/PNG) (Portable Network Graphics) format. This conversion process involves the application of a tone mapping algorithm, a technique used to compresses the dynamic range while preserving important visual details. This process makes the HDR image viewable on standard displays without losing the essence of its high dynamic range.

```sh
./PhotoNim help pfm2png
```

```sh
PhotoNim CLI `pfm2png` command:

Usage: 
    ./PhotoNim pfm2png <input> [<output>] [--a=<alpha> --g=<gamma> --lum=<avlum>]

Options:
    <input>             Path to the HDRImage to be converted from PFM to PNG. 
    <output>            Path to the LDRImage. [default: "input_dir/" & "input_name" & "alpha_gamma" & ".png"]
    --a=<alpha>         Color renormalization factor. [default: 0.18]
    --g=<gamma>         Gamma correction factor. [default: 1.0]
    --lum=<avlum>       Average image luminosity. 
```

For this example we will use the [memorial.pfm](https://www.pauldebevec.com/Research/HDR/PFM/) image and convert it with `pfm2png`:
```sh
wget https://www.pauldebevec.com/Research/HDR/memorial.pfm
./PhotoNim pfm2png memorial.pfm --a=0.30 --g=2.0
```
By varying the parameters alpha and gamma, you can produce visually different images without having to render them again:
|-| $\alpha = 0.15$ | $\alpha = 0.30$ | $\alpha = 0.45$ |
|--- | --- | --- | ---|
| $\gamma = 1.0$ | ![ImageA](assets/images/pfm2png/memorial_a0.15_g1.0.png) | ![ImageB](assets/images/pfm2png/memorial_a0.3_g1.0.png) | ![ImageC](assets/images/pfm2png/memorial_a0.45_g1.0.png) |
| $\gamma = 2.0$ | ![ImageD](assets/images/pfm2png/memorial_a0.15_g2.0.png) | ![ImageE](assets/images/pfm2png/memorial_a0.3_g2.0.png) | ![ImageF](assets/images/pfm2png/memorial_a0.45_g2.0.png) |


### demo command
By using demo mode, you can produce a complex figure of different spheres located in different spatial positions. You can specify image resolution and at which angle you want to see the scenery: in order to produce the following gif you just have to type
```bash
for angle in $(seq 0 359); do
    # Angle with three digits, e.g. angle="1" → angleNNN="001"
    angleNNN=$(printf "%03d" $angle)
    ./PhotoNim demo perspective img$angleNNN.png --angle $angle
done

ffmpeg -r 25 -f image2 -s 1600x1000 -i img%03d.png \
    -vcodec libx264 -pix_fmt yuv420p \
    spheres-perspective.mp4
```

[](https://github.com/Negrini085/PhotoNim/assets/139368862/6eb06aeb-eba3-4343-ac1f-96366d666894)

# Contributing
If you want to contribute to the project, you can open a [pull requests](https://github.com/Negrini085/PhotoNim/pulls) or use the [issue tracker](https://github.com/Negrini085/PhotoNim/issues/) to suggest any code implementations or report bugs. 
Any contributions are welcome! 

# License
The code is released under the terms of the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html), see the [LICENSE](https://github.com/Negrini085/PhotoNim/blob/master/LICENSE).
