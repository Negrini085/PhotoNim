---
layout: home
---

# PhotoNim - a CPU RayTracer written in Nim
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Negrini085/PhotoNim/ci-action.yml)
![GitHub License](https://img.shields.io/github/license/Negrini085/PhotoNim)
![GitHub Release](https://img.shields.io/github/v/release/Negrini085/PhotoNim)
![GitHub repo size](https://img.shields.io/github/repo-size/Negrini085/PhotoNim)
![GitHub last commit](https://img.shields.io/github/last-commit/Negrini085/PhotoNim)

Welcome!!

## Usage
```bash
nimble build
```
This command generates in the root directory an executable called PhotoNim. 

```bash
./PhotoNim --help
PhotoNim: a CPU raytracer written in Nim.

Usage:
    ./PhotoNim pfm2png <input> [<output>] [--alpha=<alpha> --gamma=<gamma>]
    
Options:
    --alpha=<alpha>     Color renormalization factor. [default: 0.18]
    --gamma=<gamma>     Gamma correction factor. [default: 1.0]
    
    -h --help           Show this helper screen.
    --version           Show PhotoNim version.
```