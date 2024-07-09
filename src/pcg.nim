type PCG* = object 
    state*, incr*: uint64


proc random*(gen: var PCG): uint32 =
    var 
        oldstate = gen.state
        xorshift = uint32(((oldstate shr 18) xor oldstate) shr 27)
        rot = int32(oldstate shr 59)

    gen.state = oldstate * uint64(6364136223846793005) + gen.incr
    result = ((xorshift shr rot) or (xorshift shl ((-rot) and 31)))

proc newPCG*(inState: uint64 = 42, inSeq: uint64 = 54): PCG = 
    (result.state, result.incr) = (0.uint64, (inSeq shl 1) or 1)
    discard result.random
    result.state += inState
    discard result.random

proc rand*(pcg: var PCG): float32 =
    ## Returns a new random number uniformly distributed over [0, 1]
    pcg.random.float32 / 0xffffffff.float32

proc rand*(pcg: var PCG; a, b: float32): float32 =
    a + pcg.rand * (b - a)