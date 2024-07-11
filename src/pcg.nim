type 
    PCG* = tuple[state, incr: uint64]
    RandomSetUp* = tuple[inState, inSeq: uint64]


proc random*(gen: var PCG): uint64 =
    var 
        oldstate = gen.state
        xorshift = uint32(((oldstate shr 18) xor oldstate) shr 27)
        rot = int32(oldstate shr 59)

    gen.state = oldstate * uint64(6364136223846793005) + gen.incr
    result = ((xorshift shr rot) or (xorshift shl ((-rot) and 31)))

proc newPCG*(setUp: RandomSetUp): PCG = 
    (result.state, result.incr) = (0.uint64, (setUp.inSeq shl 1) or 1)
    discard result.random
    result.state += setUp.inState
    discard result.random

proc newRandomSetUp*(inState, inSeq: uint64): RandomSetUp {.inline.} = (inState, inSeq)

proc rand*(pcg: var PCG): float32 =
    ## Returns a new random number uniformly distributed over [0, 1]
    pcg.random.float32 / 0xffffffff.float32

proc rand*(pcg: var PCG; a, b: float32): float32 =
    a + pcg.rand * (b - a)