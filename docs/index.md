---
layout: home
title: Home
nav_order: 0
---

# PhotoNim - a CPU RayTracer written in Nim
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Negrini085/PhotoNim/ci-action.yml)
![GitHub License](https://img.shields.io/github/license/Negrini085/PhotoNim)
![GitHub Release](https://img.shields.io/github/v/release/Negrini085/PhotoNim)
![GitHub last commit](https://img.shields.io/github/last-commit/Negrini085/PhotoNim)
![GitHub repo size](https://img.shields.io/github/repo-size/Negrini085/PhotoNim)

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

## Contributing
If you want to contribute to the project, you can open a [pull requests](https://github.com/Negrini085/PhotoNim/pulls) or use the [issue tracker](https://github.com/Negrini085/PhotoNim/issues/) to suggest any code implementations or report bugs. 
Any contributions are welcome! 

## License
The code is released under the terms of the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html), see the [LICENSE](https://github.com/Negrini085/PhotoNim/blob/master/LICENSE).