type 
    PCG* = tuple[state, incr: uint64] ##\
    ## The `PCG` type represents the state of a Permuted Congruential Generator (PCG), 
    ## a family of simple fast space-efficient statistically good algorithms for random number generation.
    
    RandomSetUp* = tuple[inState, inSeq: uint64] ##\
    ## The `RandomSetUp` type is used to initialize a `PCG` generator.


proc random*(gen: var PCG): uint64 =
    ## Get a random uint64 from a `PCG`.

    var 
        oldstate = gen.state
        xorshift = uint32(((oldstate shr 18) xor oldstate) shr 27)
        rot = int32(oldstate shr 59)

    gen.state = oldstate * uint64(6364136223846793005) + gen.incr
    result = ((xorshift shr rot) or (xorshift shl ((-rot) and 31)))


proc newRandomSetUp*(rg: var PCG): RandomSetUp {.inline.} = 
    ## Create a new `RandomSetUp` from a `PCG`.
    (rg.random, rg.random)


proc newPCG*(setUp: RandomSetUp): PCG = 
    ## Create a new `PCG` with the given `RandomSetUp`.

    (result.state, result.incr) = (0.uint64, (setUp.inSeq shl 1) or 1)
    discard result.random
    result.state += setUp.inState
    discard result.random


proc rand*(pcg: var PCG): float32 =
    ## Get a random float32 uniformly distributed over the interval (0, 1)
    pcg.random.float32 / 0xffffffff.float32

proc rand*(pcg: var PCG; a, b: float32): float32 =
    ## Get a random float32 uniformly distributed over the interval (a, b)
    a + pcg.rand * (b - a)