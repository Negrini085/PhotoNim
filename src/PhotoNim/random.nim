type PCG* = object 
    state*: uint64
    inc*: uint64

proc rand*(gen: var PCG): uint32 =
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
    discard result.rand()
    result.state += in_state
    discard result.rand()