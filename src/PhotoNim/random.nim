import math

type Pcg* = object 
    state*: uint64
    inc*: uint64