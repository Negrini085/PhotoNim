import std/unittest
import PhotoNim/common
import PhotoNim/color

suite "ColorTest":
    setup:
        let col1 = newColor(1.0, 2.0, 3.0)
        let col2 = Color()

    test "newColor":
        check areClose(col1.r, 1.0) 
        check areClose(col1.g, 2.0) 
        check areClose(col1.b, 3.0)
        check areClose(col2, newColor(0.0, 0.0, 0.0))