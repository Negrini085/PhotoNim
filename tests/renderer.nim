import std/unittest
import ../src/[camera, geometry, pcg, shape, scene, ray, color, hdrimage, renderer, material]


#-------------------------------------#
#      Renderer type test suite       #
#-------------------------------------#
suite "Renderer":
    # Here we just want to make sure that we are 
    # creating renderer variables as we want

    setup:
        let
            onOff = newOnOffRenderer(BLACK)
            flat = newFlatRenderer()
            path = newPathTracer(10, 5, 3)
        
    teardown:
        discard flat
        discard path
        discard onOff

    
    test "newOnOffRenderer proc":
        # Checking newOnOffRenderer procedure

        check onOff.kind == rkOnOff
        check areClose(onOff.hitColor, BLACK)
    

    test "newFlatRenderer proc":
        # Checking newFlatRenderer procedure

        check flat.kind == rkFlat


    test "newPathTracer proc":
        # Checking newPathTracer procedure

        check path.kind == rkPathTracer
        check path.nRays == 10 
        check path.depthLimit == 5 
        check path.rouletteLimit == 3 



#-------------------------------------#
#   Rendering algorithms test suite   #
#-------------------------------------#
suite "Rendering algorithms":

    setup:
        let rs = newRandomSetUp(42, 54)
        
        var 
            rend = newPathTracer(1, 100, 101)
            camera = newPerspectiveCamera(rend, (1600, 900), 2)
        
    teardown:
        discard rs
        discard rend
        discard camera


    test "OnOffRenderer test":
        # Here we want to check if the OnOffRenderer algorithm we
        # implemented is actually working or not 

        var pcg = newPCG(rs)

        let
            mat = newMaterial(newDiffuseBRDF(newUniformPigment(WHITE)))
            sph = newSphere(ORIGIN3D, 0.2, mat)

            scene = newScene(BLACK, @[sph], tkBinary, 1, newRandomSetUp(pcg.random, pcg.random))
        
        rend = newOnOffRenderer()
        camera.renderer = rend
        camera.viewport = (3, 3)

        let image = camera.sample(scene, newRandomSetUp(pcg.random, pcg.random))

        check areClose(image.getPixel(0, 0), BLACK)
        check areClose(image.getPixel(1, 0), BLACK)
        check areClose(image.getPixel(2, 0), BLACK)
    
        check areClose(image.getPixel(0, 1), BLACK)
        check areClose(image.getPixel(1, 1), WHITE)
        check areClose(image.getPixel(1, 2), BLACK)

        check areClose(image.getPixel(0, 2), BLACK)
        check areClose(image.getPixel(1, 2), BLACK)
        check areClose(image.getPixel(2, 2), BLACK)


    test "FlatRenderer test":
        # Here we want to check if the FlatRenderer algorithm we
        # implemented is actually working or not 

        var pcg = newPCG(rs)

        let 
            mat = newEmissiveMaterial(
                newDiffuseBRDF(newUniformPigment(newColor(0.2, 0.3, 0.5))),
                newUniformPigment(newColor(0.2, 0.3, 0.5))
            )

            sph = newSphere(ORIGIN3D, 0.2, mat)
            scene = newScene(BLACK, @[sph], tkBinary, 1, newRandomSetUp(pcg.random, pcg.random))
        
        rend = newFlatRenderer()
        camera.renderer = rend
        camera.viewport = (3, 3)

        let image = camera.sample(scene, newRandomSetUp(pcg.random, pcg.random))

        check areClose(image.getPixel(0, 0), BLACK)
        check areClose(image.getPixel(1, 0), BLACK)
        check areClose(image.getPixel(2, 0), BLACK)
    
        check areClose(image.getPixel(0, 1), BLACK)
        check areClose(image.getPixel(1, 1), newColor(0.2, 0.3, 0.5))
        check areClose(image.getPixel(1, 2), BLACK)

        check areClose(image.getPixel(0, 2), BLACK)
        check areClose(image.getPixel(1, 2), BLACK)
        check areClose(image.getPixel(2, 2), BLACK)


    test "Furnace test":
        # Here we want to check if the path tracing algorithm we
        # implemented is actually working or not 

        var 
            col: Color
            exp: float32
            pcg = newPCG(rs)
            ray = newRay(ORIGIN3D, eX)

        for _ in 0..500:
                
            let
                emiRad = pcg.rand
                refl = pcg.rand * 0.9

                mat = newEmissiveMaterial(newDiffuseBRDF(newUniformPigment(WHITE * refl)), newUniformPigment(WHITE * emiRad))
                sphere = newUnitarySphere(ORIGIN3D, mat)

                scene = newScene(BLACK, @[sphere], tkBinary, 1, newRandomSetUp(pcg.random, pcg.random))
            
            pcg = newPCG(newRandomSetUp(pcg.random, pcg.random))
            col = rend.sampleRay(scene, ray, pcg)
            exp = emiRad/(1 - refl)


            check areClose(exp, col.r, eps = 1e-3)
            check areClose(exp, col.g, eps = 1e-3)
            check areClose(exp, col.b, eps = 1e-3)