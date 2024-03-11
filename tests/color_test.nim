import std/unittest
import PhotoNim/common
import PhotoNim/color

suite "ColorTest":
    setup:
        let col1 = newColor(1.0, 2.0, 3.0)
        var col2 = Color()

    test "newColor":
        ## Constructor test
        check areClose(col1.r, 1.0) 
        check areClose(col1.g, 2.0) 
        check areClose(col1.b, 3.0)
        check areClose(col2, newColor(0.0, 0.0, 0.0))

    test "multByScal":
        ## Multiplication by a scalar test
        col2 = col1.multByScal(2)
        check areClose(col2.r, 2.0)
        check areClose(col2.g, 4.0)
        check areClose(col2.b, 6.0)

    test "multCol":
        ## Multiplication of two colors test
        col2 = col1.multByScal(2)
        var col3: Color = col1.multCol(col2)

        check areClose(col3.r, 2.0)
        check areClose(col3.g, 8.0)
        check areClose(col3.b, 18.0)