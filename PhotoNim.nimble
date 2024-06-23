# Package
version       = "0.3.0"
author        = "lorenzoliuzzo & Negrini085"
description   = "A CPU raytracer written in Nim"
license       = "GPL-3.0-or-later"
bin           = @["PhotoNim"]

# Dependencies
requires "nim >= 2.0"
requires "docopt >= 0.6"
requires "nimPNG >= 0.3"


# Tasks
task build, "Build the `PhotoNim` executable\n":
  exec "nim c -d:release PhotoNim.nim"


task demo, """Run the `PhotoNim` demo!

          Usage: 
                  nimble demo (persp | ortho) (OnOff | Flat | Path) <angle> [<output>] [<width> <height>]

          Options:

                  persp | ortho          Camera kind: Perspective or Orthogonal

                  OnOff | Flat | Path    Renderer kind: OnOff (only shows hit), Flat (flat renderer), Path (path tracer)

                  <angle>                Rotation angle around z axis. [default: 10]

                  <output>               Path to the LDRImage output. [default: "examples/demo/demo.png"]
                  
                  <width>                Image width. [default: 900]
                  <height>               Image height. [default: 900]

""":

    var 
        demoCommand = "nim c -d:release --hints:off -r examples/demo/main.nim"
        commands = newSeq[string](paramCount() + 1)

    for i in 0..paramCount(): commands[i] = paramStr(i)
    for i in commands.find("demo")..paramCount(): demoCommand.add(" " & paramStr(i))

    exec demoCommand
    

task demoAnim, "Run the `PhotoNim` demo animation":
  exec "sh examples/demo/animation.sh"
  exec "open examples/demo/demo.mp4"


# task earth, "Run the Earth animation!":
#   exec "nim c -d:release --hints:off examples/earth/main.nim"
#   exec "seq 0 359 | parallel -j 8 --eta './examples/earth/main {1}'"
#   exec "ffmpeg -framerate 30 -i examples/earth/frames/img%03d.png -c:v libx264 -pix_fmt yuv420p examples/earth/earth.mp4 -y"
#   exec "open examples/earth/earth.mp4"


task examples, "Run the PhotoNim examples":
  exec "nim c -d:release --hints:off -r examples/shapes/triangle.nim"
  exec "nim c -d:release --hints:off -r examples/shapes/box.nim"
  exec "nim c -d:release --hints:off -r examples/shapes/cylinder.nim"
  exec "nim c -d:release --hints:off -r examples/shapes/bvh.nim"
  exec "rm examples/shapes/triangle examples/shapes/box examples/shapes/cylinder examples/shapes/bvh"


task test, "Run the `PhotoNim` tests":
  withDir "tests":   
    exec "nim c -d:release --hints:off -r geometry.nim"    
    exec "nim c -d:release --hints:off -r hdrimage.nim"    
    exec "nim c -d:release --hints:off -r camera.nim"
    exec "nim c -d:release --hints:off -r scene.nim"
    exec "nim c -d:release --hints:off -r pcg.nim"
    exec "nim c -d:release --hints:off -r hitrecord.nim"
    exec "rm geometry hdrimage camera scene pcg hitrecord"