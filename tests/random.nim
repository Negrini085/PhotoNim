import std/unittest
import PhotoNim/random

suite "Pcg":

    setup:
        var gen = newPcg(42, 54)

    test "newPcg proc":
        # Checking pcg constructor
        
        check gen.state == uint64(1753877967969059832)
        check gen.inc == uint64(109)
    

    test "rand proc":
        # Checking pcg rand procedure
        var test = [uint32(2707161783), uint32(2068313097), uint32(3122475824), uint32(2211639955), uint32(3215226955), uint32(3421331566)]

        for i in test:
            check gen.rand() == i