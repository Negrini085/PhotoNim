type Pcg* = object 
    state*: uint64
    inc*: uint64

proc newPcg*(in_state: uint64 = 42, in_seq: uint64 = 54): Pcg = 
    # Pcg type constructor
    result.state = 0; result.inc = ((in_seq shl 1) or 1)
    discard result.random()
    result.state += in_state
    discard result.random()

