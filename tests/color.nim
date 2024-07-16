import std/unittest

import ../src/[color, geometry]

#------------------------------------#
#       Color type test suite        #
#------------------------------------#
suite "Color":

    setup:
        var 
            col1 = newColor(1, 0.5, 0.3)
            col2 = newColor(0.3, 0.2, 1)
    
    teardown:
        discard col1
        discard col2
    
    test "Const":
        # Checks wether constants are well defined or not

        check areClose(BLACK, newColor(0, 0, 0))
        check areClose(WHITE, newColor(1, 1, 1))
        check areClose(RED,   newColor(1, 0, 0))
        check areClose(GREEN, newColor(0, 1, 0))
        check areClose(BLUE,  newColor(0, 0, 1))
    

    test "newColor proc":
        # Checks newColor proc
    
        check areClose(col1, newColor(1, 0.5, 0.3))
        check areClose(col2, newColor(0.3, 0.2, 1))

    
    test "r, g, b procs":
        # Checks r, g, b procs

        check areClose(col1.r, 1.0)
        check areClose(col1.g, 0.5)
        check areClose(col1.b, 0.3)

        check areClose(col2.r, 0.3)
        check areClose(col2.g, 0.2)
        check areClose(col2.b, 1.0)
    

    test "Color operations":
        # Checks operations defined on colors
        var appo = newColor(0, 0, 0)

        check areClose(col1+col2, newColor(1.3, 0.7, 1.3))
        check areClose(col1-col2, newColor(0.7, 0.3, -0.7))

        appo += col1; check areClose(appo, col1)
        appo -= col1; check areClose(appo, BLACK)

        check areClose(2 * col1, newColor(2, 1, 0.6))
        check areClose(col2 * 2, newColor(0.6, 0.4, 2))
        check areClose(col1/2, newColor(0.5, 0.25, 0.15))

        appo = col1
        appo *= 2; check areClose(appo, newColor(2, 1, 0.6))
        appo /= 2; check areClose(appo, col1)

        check areClose(col1*col2, newColor(0.3, 0.1, 0.3))


    test "luminosity proc":
        # Checks color luminosity (we will use it in order to clamp images)
        
        check areClose(col1.luminosity(), 0.65)
        check areClose(col2.luminosity(), 0.6)


