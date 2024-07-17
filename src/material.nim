import geometry, color, hdrimage, pcg

from std/streams import newFileStream
from std/math import pow, sqrt, exp, ln, sin, cos, arctan, PI, floor


type 
    PigmentKind* = enum pkUniform, pkTexture, pkCheckered
    Pigment* = object
        case kind*: PigmentKind
        of pkUniform: color*: Color
        of pkTexture: texture*: HDRImage
        of pkCheckered: grid*: tuple[c1, c2: Color, nRows, nCols: int]

    BRDFKind* = enum DiffuseBRDF, SpecularBRDF
    BRDF* = ref object
        pigment*: Pigment
        case kind*: BRDFKind
        of DiffuseBRDF: reflectance*: float32
        of SpecularBRDF: discard

    MaterialKind* = enum mkEmissive, mkNonEmissive
    Material* = object
        brdf*: BRDF

        case kind*: MaterialKind
        of mkEmissive: eRadiance*: Pigment
        of mkNonEmissive: discard


proc newUniformPigment*(color: Color): Pigment {.inline.} = Pigment(kind: pkUniform, color: color)
proc newTexturePigment*(texture: HDRImage): Pigment {.inline.} = Pigment(kind: pkTexture, texture: texture)

proc newTexturePigment*(fname: string): Pigment = 
    var stream =
        try: newFileStream(fname, fmRead)
        except: quit "Error: something happend while trying to read a texture. " & getCurrentExceptionMsg()

    Pigment(kind: pkTexture, texture: stream.readPFM.img)  

proc newCheckeredPigment*(color1, color2: Color, nRows, nCols: int): Pigment {.inline.} = Pigment(kind: pkCheckered, grid: (color1, color2, nRows, nCols))


proc getColor*(pigment: Pigment; uv: Point2D): Color =
    case pigment.kind: 
    of pkUniform: pigment.color

    of pkTexture: 
        var (col, row) = (floor(uv.u * pigment.texture.width.float32).int, floor(uv.v * pigment.texture.height.float32).int)
        if col >= pigment.texture.width: col = pigment.texture.width - 1
        if row >= pigment.texture.height: row = pigment.texture.height - 1

        return pigment.texture.getPixel(col, row)

    of pkCheckered:
        let (col, row) = (floor(uv.u * pigment.grid.nCols.float32).int, floor(uv.v * pigment.grid.nRows.float32).int)
        return (if (col mod 2) == (row mod 2): pigment.grid.c1 else: pigment.grid.c2)



proc newDiffuseBRDF*(pigment: Pigment, reflectance = 1.0): BRDF {.inline.} = 
    BRDF(kind: DiffuseBRDF, pigment: pigment, reflectance: reflectance)

proc newSpecularBRDF*(pigment: Pigment): BRDF {.inline.} = 
    BRDF(kind: SpecularBRDF, pigment: pigment) 


proc scatterDir*(brdf: BRDF, hitNormal: Normal, hitDir: Vec3, rg: var PCG): Vec3 =
    case brdf.kind
    of DiffuseBRDF:
        let 
            (cos2, phi) = (rg.rand, 2 * PI.float32 * rg.rand)
            cos = sqrt(cos2)
            base = newONB(hitNormal)
        
        return cos * cos(phi) * base[0] + cos * sin(phi) * base[1] + sqrt(1 - cos2) * base[2]

    of SpecularBRDF: return hitDir - 2 * dot(hitNormal.Vec3, hitDir) * hitNormal.Vec3


proc newMaterial*(brdf: BRDF): Material {.inline.} =
    Material(kind: mkNonEmissive, brdf: brdf)

proc newEmissiveMaterial*(brdf: BRDF, emittedRadiance: Pigment): Material {.inline.} =
    Material(kind: mkEmissive, brdf: brdf, eRadiance: emittedRadiance)