import std/fenv

proc areClose*(x, y: SomeFloat): bool {.inline.} = abs(x - y) < epsilon(SomeFloat) ## \
   ## Check if two floats are the same up to numerical precision 
