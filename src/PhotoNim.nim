import strutils

let doc = """
PhotoNim, a simple CPU raytracer written in Nim.

Usage: 
    ./PhotoNim convert <HDR> [<LDR>] [--alpha=<alpha> --gamma=<gamma>]

Options:
    --alpha=<alpha>     Color renormalization factor [default: 0.18]
    --gamma=<gamma>     LDR factor [default: 1.0]
    -h --help     
    --version     
"""


import docopt

let args = docopt(doc, version = "PhotoNim 0.1")

if args["convert"]:
    let 
        ifile = args["<HDR>"]
        ofile = args["<LDR>"]
    var alpha, gamma: float32

    if args["--alpha"]: 
        try: alpha = parseFloat($args["--alpha"]) 
        except: echo "Warning: alpha flag must be a float. Default value is used."

    if args["--gamma"]: 
        try: gamma = parseFloat($args["--gamma"]) 
        except: echo "Warning: gamma flag must be a float. Default value is used."

    echo "Converting an HDRImage to a LDRImage."

    echo "ifile ", ifile
    echo "ofile ", ofile   
    echo "alpha ", alpha
    echo "gamma ", gamma   

    quit()

elif args["render"]:
    quit()

else: 
    echo "No other commands are availables!"
    quit()