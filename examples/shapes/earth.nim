# import PhotoNim

# from std/times import cpuTime
# from std/streams import newFileStream
# from std/strformat import fmt
# import std/options
# from std/math import PI

# let 
#     timeStart = cpuTime()
#     (width, height) = (300, 300)
#     distance = 2.0
#     filePFM = "assets/images/examples/earth.pfm"
#     texturePFM = "assets/images/textures/earth.pfm"

# var 
#     stream = newFileStream(texturePFM, fmRead)
#     texture: HDRImage

# try:
#     texture = stream.readPFM.img
# except:
#     quit fmt"Could not read texture from {texturePFM}!"

# var
#     tracer = ImageTracer(
#         image: newHDRImage(width, height), 
#         camera: newPerspectiveCamera(width / height, distance, newTranslation(newVec3(float32 -distance, 0, 0)))
#     )

#     world = newWorld()

# world.shapes.add(newUnitarySphere(newPoint3D(0.0, 0.0, 0.0), newMaterial(newDiffuseBRDF(), newTexturePigment(texture))))

# proc col_pix(tracer: ImageTracer, scenary: World, x, y: int): Color = 
#     let dim = scenary.shapes.len
#     if dim == 0: return BLACK
#     for i in 0..<dim:
#         let intersection = rayIntersection(scenary.shapes[i], tracer.fire_ray(x, y))
#         if intersection.isSome: return intersection.get.material.radiance.getColor(newPoint2D(x.float32, y.float32)) * (intersection.get.material.brdf.reflectance / PI)
#         else: return BLACK

# tracer.fire_all_rays(world, col_pix)

# stream = newFileStream(filePFM, fmWrite)
# stream.writePFM(tracer.image)
# echo fmt"Successfully rendered image in {cpuTime() - timeStart} seconds."