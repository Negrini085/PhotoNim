# Package
version       = "0.1.0"
author        = "lorenzoliuzzo & Negrini085"
description   = "A CPU raytracer written in Nim"
license       = "GPL-3.0-or-later"
bin           = @["PhotoNim"]

# Dependencies
requires "nim >= 2.0"
requires "docopt >= 0.6"
requires "nimPNG >= 0.3"


# Tasks
task build, "Build the `PhotoNim` executable":
  exec "nim c -d:release PhotoNim.nim"

task test, "Run the `PhotoNim` tests":
  withDir "tests":   
    exec "nim c -d:release --hints:off -r geometry.nim"    
    exec "nim c -d:release --hints:off -r hdrimage.nim"    
    exec "nim c -d:release --hints:off -r camera.nim"
    exec "nim c -d:release --hints:off -r scene.nim"
    exec "nim c -d:release --hints:off -r pcg.nim"
    exec "nim c -d:release --hints:off -r hitrecord.nim"
    exec "rm geometry hdrimage camera scene pcg hitrecord"


task demo, """Run the `PhotoNim` demo!

          Usage: nimble demo (persp | ortho) (OnOff | Flat | Path) [--w=<width> --h=<height> --angle=<angle>] [<output>]

          Options:
              persp | ortho           Perspective or Orthogonal Camera kinds.
              OnOff | Flat            Choosing renderer: OnOff (only shows hit), Flat (flat renderer)
              --w=<width>             Image width. [default: 1600]
              --h=<height>            Image height. [default: 900]
              --angle=<angle>         Rotation angle around z axis. [default: 10]
              <output>                Path to the output HDRImage. [default: "examples/demo/demo.pfm"]""":

    var 
        demoCommand = "nim c -d:release -r examples/demo/main.nim"
        commands = newSeq[string](paramCount() + 1)

    for i in 0..paramCount(): commands[i] = paramStr(i)
    for i in commands.find("demo")..paramCount(): demoCommand.add(" " & paramStr(i))

    exec demoCommand
    exec "rm examples/demo/main"


task demoAnim, "Run the PhotoNim demo animation":
  exec "nim c -d:release PhotoNim.nim"
  exec "sh examples/demo/animation.sh"
  
task examples, "Run the PhotoNim examples":
  exec "nim c -d:release --hints:off -r examples/shapes/triangle.nim"
  exec "nim c -d:release --hints:off -r examples/shapes/box.nim"
  exec "nim c -d:release --hints:off -r examples/shapes/cylinder.nim"
  exec "nim c -d:release --hints:off -r examples/shapes/bvh.nim"
  exec "rm examples/shapes/triangle examples/shapes/box examples/shapes/cylinder examples/shapes/bvh"