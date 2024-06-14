import std/unittest
import ../src/pcg

suite "PCG":

    setup:
        var gen = newPCG(42, 54)

    test "newPCG proc":
        # Checking PCG constructor
        
        check gen.state == uint64(1753877967969059832)
        check gen.incr == uint64(109)
    

    test "random proc":
        # Checking PCG rand procedure
        var test = [uint32(2707161783), uint32(2068313097), uint32(3122475824), uint32(2211639955), uint32(3215226955), uint32(3421331566)]

        for i in test:
            check gen.random == i