import std/streams
import std/strutils

import geometry

var
    istream: FileStream
    line: string
    appo: seq[string]

    vert: seq[Point3D] = @[]
    tri: seq[Vec3f] = @[]

istream = newFileStream("../gourd.obj", fmRead)

if isNil(istream):
    echo "Error during file opening procedure!"
    echo "Quitting program execution!"
    quit()


# Entering reading proc
while not istream.atEnd:

    try:
        # Reading first line of obj file
        line = istream.readLine 
    except:
        echo "Error during file reading procedure"
        echo "Quitting program execution"
        quit()



    # I want to do further check only if we actually got something
    if not line.isEmptyOrWhitespace:
        
        for item in line.splitWhitespace():
            appo.add item

        if appo[0] == "v": vert.add newPoint3D(appo[1].parseFloat, appo[2].parseFloat, appo[3].parseFloat)
        elif appo[0] == "f": 
            # We have only three indeces, so that we are defining only one triangular face
            if appo.len == 4: 
                # We want to have infos only regarding faces (we are going to discard normals and additional stuff)
                tri.add newVec3f(
                            appo[1].rsplit('/')[0].parseFloat, 
                            appo[2].rsplit('/')[0].parseFloat, 
                            appo[3].rsplit('/')[0].parseFloat
                        )
            else:
                # Here we are triangulating non triangular meshes
                for i in 0..appo.len-4:
                    tri.add newVec3f(
                                appo[1].rsplit('/')[0].parseFloat, 
                                appo[2+i].rsplit('/')[0].parseFloat, 
                                appo[3+i].rsplit('/')[0].parseFloat
                            )

        appo = @[]
