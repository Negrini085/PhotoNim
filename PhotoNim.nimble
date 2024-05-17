# Package
version       = "0.1.0"
author        = "lorenzoliuzzo & Negrini085"
description   = "A CPU raytracer written in Nim"
license       = "GPL-3.0-or-later"
srcDir        = "src"
bin           = @["PhotoNim"]

# Dependencies
requires "nim >= 2.0"
requires "docopt >= 0.6"
requires "nimPNG >= 0.3"

# Tasks
task test, "Run the PhotoNim tests!":
  withDir "tests":
    exec "nim c -r geometry.nim"    
    exec "nim c -r hdrimage.nim"
    exec "nim c -r camera.nim"
    exec "nim c -r shapes.nim"
    exec "nim c -r pcg.nim"
    exec "rm geometry hdrimage camera shapes pcg"