type PCG* = object 
    state*: uint64
    inc*: uint64


proc random*(gen: var PCG): uint32 =
    # Random number generation procedure
    var 
        oldstate = gen.state
        xorshift = uint32(((oldstate shr 18) xor oldstate) shr 27)
        rot = int32(oldstate shr 59)

    gen.state = oldstate * uint64(6364136223846793005) + gen.inc
    result = ((xorshift shr rot) or (xorshift shl ((-rot) and 31)))

proc newPCG*(in_state: uint64 = 42, in_seq: uint64 = 54): PCG = 
    # PCG type constructor
    result.state = 0; result.inc = ((in_seq shl 1) or 1)
    discard result.random
    result.state += in_state
    discard result.random

proc rand*(pcg: var PCG): float32 =
    ## Returns a new random number uniformly distributed over [0, 1]
    pcg.random.float32 / 0xffffffff.float32

proc rand*(pcg: var PCG; a, b: float32): float32 =
    a + pcg.rand * (b - a)