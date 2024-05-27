import std/unittest
import PhotoNim

#------------------------------------------#
#         Image Tracer type tests          #
#------------------------------------------#
suite "ImageTracer":

    setup:
        var tracer = newImageTracer(5, 5, newOrthogonalCamera(1.2, Transformation.id))

    test "ImageTracer index":
        # Checking image tracer type, we will have to open an issue
        var
            ray1 = tracer.fire_ray(0, 0, newPoint2D(2.5, 1.5))
            ray2 = tracer.fire_ray(2, 1, newPoint2D(0.5, 0.5))

        check areClose(ray1.origin, ray2.origin)


    test "Camera Orientation":

        var
            ray1 = tracer.fire_ray(0, 0, newPoint2D(0, 0))   # Ray direct to top left corner
            ray2 = tracer.fire_ray(4, 4, newPoint2D(1, 1))   # Ray direct to bottom right corner
        
        check areClose(ray1.at(1.0), newPoint3D(0, 1.2, 1))
        check areClose(ray2.at(1.0), newPoint3D(0, -1.2, -1))


#--------------------------------------------#
#         Renderer kinds test suite          #
#--------------------------------------------#

suite "Renderer":

    setup:
        var 
            world = newWorld(@[
                newSphere(newPoint3D(1, 0, 0), 0.5),
                newSphere(newPoint3D(1, 2, -1), 0.2)
            ])
            oftrace = newOnOffRenderer(world, newColor(1, 2, 3), newColor(3, 2, 1))
            flatrace = newFlatRenderer(world, newColor(1, 2, 3))
            pathtr = newPathTracer(world)
    
    teardown:
        discard world
        discard oftrace
        discard flatrace

    test "constructor proc":

        #----------------------------------#
        #          On-Off Renderer         #
        #----------------------------------#
        check oftrace.kind == OnOffRenderer

        check areClose(oftrace.world.shapes[0].radius, 0.5)
        check areClose(oftrace.world.shapes[1].radius, 0.2)
        check areClose(oftrace.world.shapes[0].center, newPoint3D(1, 0, 0))
        check areClose(oftrace.world.shapes[1].center, newPoint3D(1, 2, -1))

        check areClose(oftrace.back_col, newColor(1, 2, 3))
        check areClose(oftrace.hit_col, newColor(3, 2, 1))


        #----------------------------------#
        #           Flat Renderer          #
        #----------------------------------#
        check flatrace.kind == FlatRenderer

        check areClose(flatrace.world.shapes[0].radius, 0.5)
        check areClose(flatrace.world.shapes[1].radius, 0.2)
        check areClose(flatrace.world.shapes[0].center, newPoint3D(1, 0, 0))
        check areClose(flatrace.world.shapes[1].center, newPoint3D(1, 2, -1))

        check areClose(flatrace.back_col, newColor(1, 2, 3))


        #----------------------------------#
        #            Path Tracer           #
        #----------------------------------#       
        check pathtr.kind == PathTracer

        check areClose(pathtr.world.shapes[0].radius, 0.5)
        check areClose(pathtr.world.shapes[1].radius, 0.2)
        check areClose(pathtr.world.shapes[0].center, newPoint3D(1, 0, 0))
        check areClose(pathtr.world.shapes[1].center, newPoint3D(1, 2, -1))

        check areClose(pathtr.back_col, newColor(0, 0, 0))
        check pathtr.randgen.state == uint64(1753877967969059832)
        check pathtr.randgen.inc == uint64(109)

        check areClose(pathtr.num_ray.float32, 10.float32)
        check areClose(pathtr.max_depth.float32, 10.float32)
        check areClose(pathtr.roulette_lim.float32, 3.float32)

        var pathtr1 = newPathTracer(world, newColor(1,2,3), n_ray = 15, max_depth = 12, roulette_lim = 10)

        check pathtr1.kind == PathTracer

        check areClose(pathtr1.world.shapes[0].radius, 0.5)
        check areClose(pathtr1.world.shapes[1].radius, 0.2)
        check areClose(pathtr1.world.shapes[0].center, newPoint3D(1, 0, 0))
        check areClose(pathtr1.world.shapes[1].center, newPoint3D(1, 2, -1))

        check areClose(pathtr1.back_col, newColor(1,2,3))
        check pathtr.randgen.state == uint64(1753877967969059832)
        check pathtr.randgen.inc == uint64(109)

        check areClose(pathtr1.num_ray.float32, 15.float32)
        check areClose(pathtr1.max_depth.float32, 12.float32)
        check areClose(pathtr1.roulette_lim.float32, 10.float32)


    test "call proc":

        var
            ray1 = newRay(newPoint3D(-2, 0, 0), newVec3f(1, 0, 0))
            ray2 = newRay(newPoint3D(-2, 0, 0), newVec3f(-1, 0, 0))

        # Here we expect to have hit while using ray1, but ray2 will not
        # give rise to an intersection

        #----------------------------------#
        #          On-Off Renderer         #
        #----------------------------------#
        check areClose(oftrace.call(ray1), newColor(3, 2, 1))
        check areClose(oftrace.call(ray2), newColor(1, 2, 3))
    

        #----------------------------------#
        #           Flat Renderer          #
        #----------------------------------#
        check areClose(flatrace.call(ray1), newColor(2, 2, 2))
        check areClose(flatrace.call(ray2), newColor(1, 2, 3))


        #----------------------------------#
        #            Path Tracer           #
        #----------------------------------#
        ray1.depth = 12
        check areClose(pathtr.call(ray1), newColor(0, 0, 0))
    


    test "Furnace test":
        # Here we are actually testing the path tracer we previously implemented
        # We are doing the so-called furnace test: we don't want to use russian roulette

        # We will use random number for emitted radiance and reflectance
        var 
            randgen = newPCG()
            radiance: float32
            reflectance: float32
            mat: Material
            col: Color
            ray: Ray

        for i in 0 ..< 100:
            world.shapes = @[]

            radiance = randgen.rand()
            reflectance = randgen.rand()

            # Randomic chosen material
            mat = newMaterial(
                newDiffuseBRDF(pigment = newUniformPigment(newColor(1,1,1) * reflectance)),
                newUniformPigment(newColor(1,1,1) * radiance)
                )
            world.shapes.add(newUnitarySphere(newPoint3D(0, 0, 0), material = mat))
            
            pathtr = newPathTracer(world, randgen = randgen, n_ray = 1, max_depth = 9100, roulette_lim = 10001)
            
            ray = newRay(newPoint3d(0, 0, 0), newVec3f(1, 0, 0))
            col = pathtr.call(ray)


            # Checking wether call method work or not, we know that we should have:
            #           exp = radiance/(1 - reflectance)
            check areClose(radiance/(1 - reflectance), col.r, eps = 1e-2)
            check areClose(radiance/(1 - reflectance), col.g, eps = 1e-2)
            check areClose(radiance/(1 - reflectance), col.b, eps = 1e-2)