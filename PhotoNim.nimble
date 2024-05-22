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
task build, "Build the PhotoNim executable":
  exec "nim c PhotoNim.nim"

task test, "Run the PhotoNim tests!":
  withDir "tests":
    exec "nim c -r geometry.nim"    
    exec "nim c -r camera.nim"
    exec "nim c -r shapes.nim"
    exec "nim c -r pcg.nim"
    exec "rm geometry camera shapes pcg"

task triangle, "Run the triangle example":
  exec "nim c -r examples/triangle.nim"
  exec "rm examples/triangle"
  exec "./PhotoNim pfm2png images/triangle.pfm images/triangle.png --avlum 0.1"
  exec "open images/triangle.png"

task csg, "Run the csg example":
  exec "nim c -r examples/csg.nim"
  exec "rm examples/csg"
  exec "./PhotoNim pfm2png images/CSGUnion.pfm images/CSGUnion.png --avlum 0.1"
  exec "open images/CSGUnion.png"