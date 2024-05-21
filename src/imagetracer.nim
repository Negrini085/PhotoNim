import geometry, camera, shapes, pcg

type ImageTracer* = object
    image*: HdrImage
    camera*: Camera
    world*: World
    sideSamples: int
    rg: PCG


proc newImageTracer*(scenary: World, camera: Camera, width, height: int, sideSamples: int = 16, randomGenerator = newPCG()): ImageTracer {.inline.} =
    ImageTracer(image: newHdrImage(width, height), camera: camera, world: scenary, sideSamples: sideSamples, rg: randomGenerator)


proc fire_ray*(tracer: ImageTracer; x, y: int, pixel = newPoint2D(0.5, 0.5)): Ray {.inline.} =   
    tracer.camera.fire_ray(newPoint2D((x.float32 + pixel.u) / tracer.image.width.float32, 1 - (y.float32 + pixel.v) / tracer.image.height.float32))


proc fire_all_rays*(tracer: var ImageTracer, color_map: proc(ray: Ray): Color) = 
    for x in 0..<tracer.image.height:
        for y in 0..<tracer.image.width:

            if tracer.sideSamples > 0:
                var color = newColor(0, 0, 0)

                for u in 0..<tracer.sideSamples:
                    for v in 0..<tracer.sideSamples:
                        let pixelOffset = newPoint2D(
                                (u.float32 + tracer.rg.rand) / tracer.sideSamples.float32, 
                                (v.float32 + tracer.rg.rand) / tracer.sideSamples.float32
                            )

                        color += color_map(tracer.fire_ray(x, y, pixelOffset))

                tracer.image.setPixel(x, y, color / (tracer.sideSamples * tracer.sideSamples).float32)

            else:
                tracer.image.setPixel(x, y, color_map(tracer.fire_ray(x, y)))