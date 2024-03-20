import std/unittest
import PhotoNim/[common, color]

suite "ColorTest":
    setup:
        let col1 = newColor(1.0, 2.0, 3.0)
        var col2 = Color()


    test "newColor":
        ## Test the `Color` constructor with three `float`s as RGB and the empty default constructor (`Black`)
        check col1.r == 1.0 
        check col1.g == 2.0 
        check col1.b == 3.0
        check col2 == newColor(0.0, 0.0, 0.0)


    test "sumColor":
        ## Test the sum of two `Color`s
        col2 = newColor(0.1, 0.2, 0.3)
        let sum: Color = col1 + col2

        check areClose(sum.r, 1.1)
        check areClose(sum.g, 2.2)
        check areClose(sum.b, 3.3)


    test "mulColor":
        ## Test the multiplication of two `Color`s
        col2 = newColor(10, 20, 30)
        let prod: Color = col1 * col2

        check prod.r == 10.0
        check prod.g == 40.0
        check prod.b == 90.0


    test "scaleColor":
        ## Test the multiplication of a `Color` by a scalar
        col2 = 2.0 * col1
        check col2.r == 2.0
        check col2.g == 4.0
        check col2.b == 6.0


    test "$Color": 
        check $col1 == "<1.0 2.0 3.0>"
        check areClose(col2.r, 2.0)
        check areClose(col2.g, 4.0)
        check areClose(col2.b, 6.0)

    test "luminosity":
        ## Test color luminosity calculation
        var 
            appo: float32 = col1.luminosity
            pippo: float32 = col2.luminosity
        
        check areClose(appo, 2.0)
        check areClose(pippo, 0.0)
        
