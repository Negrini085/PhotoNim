# PhotoNim - a CPU RayTracer written in Nim
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Negrini085/PhotoNim/ci-action.yml)
![GitHub License](https://img.shields.io/github/license/Negrini085/PhotoNim)
![GitHub Release](https://img.shields.io/github/v/release/Negrini085/PhotoNim)
![GitHub repo size](https://img.shields.io/github/repo-size/Negrini085/PhotoNim)

## Installing
### Dependencies
- [nim](https://github.com/nim-lang/Nim) >= 2.0
- [nimble](https://github.com/nim-lang/nimble) >= 0.14
- [docopt](https://github.com/docopt/docopt.nim) >= 0.6
- [nimPNG](https://github.com/jangko/nimPNG) >= 0.3

### From source
```bash
git clone https://github.com/Negrini085/PhotoNim.git
cd PhotoNim
nimble build
```
This will produce an executable `PhotoNim` at the base of the project directory.

## Usage
```bash
./PhotoNim --help
PhotoNim: a CPU raytracer written in Nim.

Usage:
    ./PhotoNim convert <input> [<output>] [--alpha=<alpha> --gamma=<gamma>]
    
Options:
    --alpha=<alpha>     Color renormalization factor. [default: 0.18]
    --gamma=<gamma>     Gamma correction factor. [default: 1.0]
    
    -h --help           Show this helper screen.
    --version           Show PhotoNim version.
```

## Examples
By varying Alpha and Gamma you can produce visually different images. You can find the .pfm file to give as an input [here](https://www.pauldebevec.com/Research/HDR/PFM/).
<p align="center">
  <img src="https://github.com/Negrini085/PhotoNim/assets/139368862/047ab8b0-3588-4b8c-84c0-5d74ca29637c" alt="Alpha = 0.15    Gamma = 1.0" width="200" />
  <img src="https://github.com/Negrini085/PhotoNim/assets/139368862/f0cd8aef-1b6a-4d6a-9418-2c3a2dac11c0" alt="Alpha = 0.30  Gamma = 1.0" width="200" /> 
  <img src="https://github.com/Negrini085/PhotoNim/assets/139368862/7c836355-cad9-4977-a295-543cd296be1b" alt="Alpha = 0.45  Gamma = 1.0" width="200" /> 
  <br>
  <em>Gamma = 1.0      Alpha = 0.15, 0.30, 0.45 left to right</em>
</p>

 <p align="center">
  <img src="https://github.com/Negrini085/PhotoNim/assets/139368862/c019dee6-f286-4b23-9693-67b169c87deb" alt="Alpha = 0.15    Gamma = 2.0" width="200" />
  <img src="https://github.com/Negrini085/PhotoNim/assets/139368862/db5cdbf4-c0ea-474c-91bb-154cd80cc990" alt="Alpha = 0.30  Beta = 1.0" width="200" /> 
  <img src="https://github.com/Negrini085/PhotoNim/assets/139368862/b9f21c8e-2d2d-4d5b-a7c9-5e0d3b2e8534" alt="Alpha = 0.45  Beta = 1.0" width="200" /> 
  <br>
  <em>Gamma = 2.0      Alpha = 0.15, 0.30, 0.45 left to right</em>
</p>

## Contributing
If you want to contribute to the project, you can open a [pull requests](https://github.com/Negrini085/PhotoNim/pulls) or use the [issue tracker](https://github.com/Negrini085/PhotoNim/issues/) to suggest any code implementations or report bugs. 
Any contributions are welcome! 

## License
The code is released under the terms of the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html), see the [LICENSE](https://github.com/Negrini085/PhotoNim/blob/master/LICENSE).
