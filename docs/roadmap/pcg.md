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
In PhotoNim we use _O'Neill algorithm_ in order to generate random number: it requires to do calculations with bit masks. We implemented a PCG type such as following:

```nim
type PCG* = object 
    state*, incr*: uint64
```

As you can see PCG stores its actual state and increment: if two random generator variables will be initialized exactly with the same numbers, they will produce the same sequence of pseudo-casual numbers. You can initialize a new variable via ```newPCG``` procedure. 
The actual _O'Neill algorithm_ is:

```nim
proc random*(gen: var PCG): uint32 =
    var 
        oldstate = gen.state
        xorshift = uint32(((oldstate shr 18) xor oldstate) shr 27)
        rot = int32(oldstate shr 59)

    gen.state = oldstate * uint64(6364136223846793005) + gen.incr
    result = ((xorshift shr rot) or (xorshift shl ((-rot) and 31)))
```

You could get float random number by means of ```rand``` procedure: you can also specify the limiting values of the interval from which you want to extract random number.

<div style="height: 25px;"></div>
<div style="text-align: left;">
    <span style="color: blue; font-size: 20px;"> Example </span>
</div>
<div style="height: 25px;"></div>

