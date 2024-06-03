---
layout: page
title: PCG
parent: Roadmap
permalink: /roadmap/pcg/
nav_order: 3
---

<div style="text-align: center;">
    <span style="color: black; font-size: 40px;"> PCG submodule </span>
</div>

To solve the rendering equation we need a random number generator that can be used to make the Monte Carlo estimates necessary for image reconstruction. 
In PhotoNim we use [_O'Neill algorithm_](https://www.pcg-random.org/paper.html) in order to generate random number: it requires to do calculations with bit masks. We implemented a PCG type such as following:

```nim
type PCG* = object 
    state*, incr*: uint64
```

As you can see PCG stores its actual state and increment: if two random generator variables will be initialized exactly with the same numbers, they will produce the same sequence of pseudo-casual numbers. 
The actual [_O'Neill algorithm_](https://www.pcg-random.org/paper.html) is:

```nim
proc random*(gen: var PCG): uint32 =
    var 
        oldstate = gen.state
        xorshift = uint32(((oldstate shr 18) xor oldstate) shr 27)
        rot = int32(oldstate shr 59)

    gen.state = oldstate * uint64(6364136223846793005) + gen.incr
    result = ((xorshift shr rot) or (xorshift shl ((-rot) and 31)))
```

You can initialize a new variable via ```newPCG``` procedure: 

proc newPCG*(inState: uint64 = 42, inSeq: uint64 = 54): PCG = 
    result = PCG(state: 0, incr: (inSeq shl 1) or 1)
    discard result.random
    result.state += inState
    discard result.random

You could get float random number by means of ```rand``` procedure: you can also specify the limiting values of the interval from which you want to extract random number.

<div style="height: 25px;"></div>
<div style="text-align: left;">
    <span style="color: blue; font-size: 20px;"> Example </span>
</div>
<div style="height: 25px;"></div>

```nim

var randgen = newPCG()          # Using default values

echo "Randgen state: ", randgen.state              # You should get 1753877967969059832
echo "Randgen inc: ", randgen.inc                  # You should get 109


echo "Random number: ", randgen.random()                # You ehould get 2707161783
echo "Random number in (0, 1): ", randgen.rand()        # You should get a number in (0, 1)
echo "Random number in (4, 8): ", randgen.rand(4, 8)    # You should get a number in (4, 8)

```
