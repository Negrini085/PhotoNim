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


task demo, """Run the `PhotoNim` demo

    Usage: 
            nimble demo (OnOff|Flat|Path)

    Options:
            persp | ortho          Camera kind: Perspective or Orthogonal
            OnOff | Flat | Path    Renderer kind: OnOff (only shows hit), Flat (flat renderer), Path (path tracer)
""":

    var 
        demoCommand = "nim c -d:release --hints:off -r PhotoNim.nim"
        commands: seq[string]

    for i in 0..paramCount(): commands.add paramStr(i)

    for i in commands.find("demo")..<commands.len: 

      if i == commands.find("demo"):
        demoCommand.add(" " & "rend")

      elif i == (commands.find("demo") + 1):
        demoCommand.add(" " & paramStr(i))
        demoCommand.add(" " & "examples/sceneFiles/demo.txt")

      else:
        demoCommand.add(" " & paramStr(i))
      
    if commands[(commands.len - 1)] == "demo":
      echo "Need to specify renderer kind, choose between (OnOff|Flat|Path)"
      return

    if not (commands[(commands.len - 1)] in ["Path", "OnOff", "Flat"]):
      echo "Usage: nimble demo (OnOff|Flat|Path)"
      return

    exec demoCommand
    exec "open examples/sceneFiles/demo**.png"


task examples, "Run the `PhotoNim` examples":
  exec "nim c -d:release --hints:off -r examples/shapes/triangle.nim"
  exec "nim c -d:release --hints:off -r examples/shapes/box.nim"
  exec "nim c -d:release --hints:off -r examples/shapes/cylinder.nim"
  exec "nim c -d:release --hints:off -r examples/shapes/bvh.nim"
  exec "rm examples/shapes/triangle examples/shapes/box examples/shapes/cylinder examples/shapes/bvh"


task test, "Run the `PhotoNim` tests":
  withDir "tests":   
    exec "nim c -d:release --hints:off -r pcg.nim"
    exec "nim c -d:release --hints:off -r geometry.nim" 
    exec "nim c -d:release --hints:off -r color.nim" 
    exec "nim c -d:release --hints:off -r hdrimage.nim"    
    exec "nim c -d:release --hints:off -r scene.nim"
    exec "nim c -d:release --hints:off -r shape.nim"
    exec "nim c -d:release --hints:off -r csg.nim"
    exec "nim c -d:release --hints:off -r ray.nim"
    exec "nim c -d:release --hints:off -r hitrecord.nim"
    exec "nim c -d:release --hints:off -r brdf.nim"
    exec "nim c -d:release --hints:off -r pigment.nim"
    exec "nim c -d:release --hints:off -r camera.nim"
    exec "rm pcg geometry hdrimage scene shape csg ray hitrecord brdf pigment camera"
