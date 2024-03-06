import std/fenv

proc areClose*(x, y: SomeFloat): bool = abs(x - y) < epsilon(SomeFloat)