import geometry, pcg, hdrimage

from std/math import floor, sqrt, sin, cos, PI, degToRad
from std/streams import newFileStream, close
from std/strformat import fmt

type
    PigmentKind* = enum pkUniform, pkTexture, pkCheckered

    Pigment* = object
        case kind*: PigmentKind
        of pkUniform: 
            color*: Color
        of pkTexture: 
            texture*: HDRImage
        of pkCheckered:
            grid*: tuple[c1, c2: Color, nRows, nCols: int]

    BRDFKind* = enum DiffuseBRDF, SpecularBRDF

    BRDF* = object
        pigment*: Pigment

        case kind*: BRDFKind
        of DiffuseBRDF:
            reflectance*: float32
        of SpecularBRDF:
            thresholdAngle*: float32

    Material* = tuple[brdf: BRDF, radiance: Pigment]


proc newUniformPigment*(color: Color): Pigment {.inline.} = Pigment(kind: pkUniform, color: color)

proc newTexturePigment*(texture: HDRImage): Pigment {.inline.} = Pigment(kind: pkTexture, texture: texture)

proc newTexturePigment*(textureSrc: string): Pigment {.inline.} = 
    var stream = newFileStream(textureSrc)
    let textureImage =
        try: stream.readPFM.img 
        except: quit fmt"Error! An error happend while trying to read texture {textureSrc}!" 
        finally: stream.close

    Pigment(kind: pkTexture, texture: textureImage)


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


proc newDiffuseBRDF*(pigment = newUniformPigment(WHITE), reflectance = 1.0): BRDF {.inline.} =
    BRDF(kind: DiffuseBRDF, pigment: pigment, reflectance: reflectance)

proc newSpecularBRDF*(pigment = newUniformPigment(WHITE), angle = 180.0): BRDF {.inline.} =
    BRDF(kind: SpecularBRDF, pigment: pigment, thresholdAngle: (0.1 * degToRad(angle)).float32) 


# proc eval*(brdf: BRDF; normal: Normal, in_dir, out_dir: Vec3f, uv: Point2D): Color {.inline.} =
#     case brdf.kind: 
#     of DiffuseBRDF: 
#         return brdf.pigment.getColor(uv) * (brdf.reflectance / PI)

#     of SpecularBRDF: 
#         if abs(arccos(dot(normal.Vec3f, in_dir.normalize)) - arccos(dot(normal.Vec3f, out_dir.normalize))) <= brdf.threshold_angle: 
#             return brdf.pigment.getColor(uv)
        # else: return BLACK


proc scatterDir*(brdf: BRDF, hitDir: Vec3f, hitNormal: Normal, rg: var PCG): Vec3f =
    case brdf.kind:
    of DiffuseBRDF:
        let 
            (cos2, phi) = (rg.rand, 2 * PI.float32 * rg.rand)
            c = sqrt(cos2)
            base = newONB(hitNormal)
        
        return c * cos(phi) * base[0] + c * sin(phi) * base[1] + sqrt(1 - cos2) * base[2]

    of SpecularBRDF: hitDir - 2 * dot(hitNormal.Vec3f, hitDir) * hitNormal.Vec3f


proc newMaterial*(brdf = newDiffuseBRDF(), pigment = newUniformPigment(WHITE)): Material {.inline.} = (brdf: brdf, radiance: pigment)
