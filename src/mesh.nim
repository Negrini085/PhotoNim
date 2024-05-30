import std/streams
import std/strutils

import geometry

var 
    istream = newFileStream("../gourd.obj", fmRead)
    line: string
    appo: seq[string]

    vert: seq[Point3D] = @[]
    tri: seq[Vec3f] = @[]

# Entering reading proc
while not istream.atEnd:

    # Reading first line of obj file
    line = istream.readLine 

    # I want to do further check only if we actually got something
    if not line.isEmptyOrWhitespace:
        
        for item in line.splitWhitespace():
            appo.add item
        
        if appo[0] == "v": vert.add newPoint3D(appo[1].parseFloat, appo[2].parseFloat, appo[3].parseFloat)
        elif appo[0] == "f": tri.add newVec3f(appo[1].parseFloat, appo[2].parseFloat, appo[3]. parseFloat)

        appo = @[]
