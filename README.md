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
To use PhotoNim you must have installed the [Nim](https://github.com/nim-lang/Nim) programming language (version 2.0 or higher) on your machine. \
To install the latest version on Unix you could run the following command:
```sh
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
```
To install it on other OSs or to install previous versions, please refer to the [Nim installation guide](https://nim-lang.org/install.html).


### Installing from Git
Choose the appropriate protocol (HTTPS or SSH) and clone the [PhotoNim repository](https://github.com/Negrini085/PhotoNim) using the command
```bash
git clone https://github.com/Negrini085/PhotoNim.git    # for HTTPS
git clone git@github.com:Negrini085/PhotoNim.git        # for SSH
```

### Installing from Tarball
Download the latest tarball from [here](https://github.com/Negrini085/PhotoNim/releases) and extract the tarball by running
```sh
tar -xzf PhotoNim-<version>.tar.gz
```

### Installing using Nimble
Install PhotoNim using [Nimble](https://github.com/nim-lang/nimble), the official Nim package manager:
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
After installing PhotoNim and its dependencies, you can verify the installation using Nimble by running PhotoNim test suites:
```sh
nimble test
```


# Usage
```bash
./PhotoNim --help
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

## Examples

### pfm2png image converter
By varying Alpha and Gamma you can produce visually different images. You can find the .pfm file to give as an input [here](https://www.pauldebevec.com/Research/HDR/PFM/).
|| $\alpha = 0.15$ | $\alpha = 0.30$ | $\alpha = 0.45$ |
| --- |--- |--- |--- |
| $\gamma = 1.0$ |![Image](https://github.com/Negrini085/PhotoNim/assets/139368862/047ab8b0-3588-4b8c-84c0-5d74ca29637c) |![Image2](https://github.com/Negrini085/PhotoNim/assets/139368862/f0cd8aef-1b6a-4d6a-9418-2c3a2dac11c0) |![Image3](https://github.com/Negrini085/PhotoNim/assets/139368862/7c836355-cad9-4977-a295-543cd296be1b)
| $\gamma = 2.0$ |![Image](https://github.com/Negrini085/PhotoNim/assets/139368862/c019dee6-f286-4b23-9693-67b169c87deb) |![Image](https://github.com/Negrini085/PhotoNim/assets/139368862/db5cdbf4-c0ea-474c-91bb-154cd80cc990) |![Image](https://github.com/Negrini085/PhotoNim/assets/139368862/b9f21c8e-2d2d-4d5b-a7c9-5e0d3b2e8534)

### demo command
By using demo mode, you can produce a complex figure of different spheres located in different spatial positions. You can specify image resolution and at which angle you want to see the scenary: in order to produce the following gif you just have to type
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
