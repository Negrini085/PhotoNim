---
layout: page
title: Installation
permalink: /install/
nav_order: 1
---

# Installation

## Prerequisites
To use PhotoNim you must have installed the [Nim](https://github.com/nim-lang/Nim) programming language (version 2.0 or higher) on your machine. \\
To install the latest version on Unix you could run the following command:
```sh
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
```
To install it on other OSs or to install previous versions, please refer to the [Nim installation guide](https://nim-lang.org/install.html).


## Installing PhotoNim
PhotoNim is available and tested for Linux, MacOSX and Windows machines.
To install it you can choose which approach you find the most fitting for you. 

### Installing from Git
Choose the appropriate protocol (HTTPS or SSH) and clone the [PhotoNim repository](https://github.com/Negrini085/PhotoNim)
```bash
git clone https://github.com/Negrini085/PhotoNim.git    # for HTTPS
git clone git@github.com:Negrini085/PhotoNim.git        # for SSH
```

### Installing from Tarball
Download the latest tarball from [here](https://github.com/Negrini085/PhotoNim/releases) and extract the tarball
```sh
tar -xzf PhotoNim-<version>.tar.gz
```

### Installing using Nimble
It is possible to install PhotoNim using [Nimble](https://github.com/nim-lang/nimble), the official Nim package manager
```sh
nimble install PhotoNim
```

## Installing Dependencies
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