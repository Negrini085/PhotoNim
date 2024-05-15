import std/unittest
import PhotoNim/random

suite "Pcg":

    setup:
        var gen: Pcg

    test "newPcg proc":
        # Checking pcg constructor
        gen = newPcg(42, 54)
        
        check gen.state == uint64(1753877967969059832)
        check gen.inc == uint64(109)