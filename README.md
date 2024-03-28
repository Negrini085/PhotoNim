# PhotoNim - a CPU RayTracer written in Nim

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

## Contributing
If you want to contribute to the project, you can open a [pull requests](https://github.com/Negrini085/PhotoNim/pulls) or use the [issue tracker](https://github.com/Negrini085/PhotoNim/issues/) to suggest any code implementations or report bugs. 
Any contributions are welcome! 

## License
The code is released under the terms of the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html), see the [LICENSE](https://github.com/Negrini085/PhotoNim/blob/master/LICENSE).
