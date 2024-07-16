import pigment, brdf


type 
    MaterialKind* = enum mkEmissive, mkNonEmissive

    Material* = object
        brdf*: BRDF

        case kind*: MaterialKind
        of mkEmissive: eRadiance*: Pigment
        of mkNonEmissive: discard


proc newMaterial*(brdf: BRDF): Material {.inline.} =
    Material(kind: mkNonEmissive, brdf: brdf)

proc newEmissiveMaterial*(brdf: BRDF, emittedRadiance: Pigment): Material {.inline.} =
    Material(kind: mkEmissive, brdf: brdf, eRadiance: emittedRadiance)