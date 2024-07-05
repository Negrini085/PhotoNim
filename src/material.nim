import geometry, pcg, hdrimage

from std/math import floor, pow, sqrt, exp, ln, sin, cos, arccos, arctan, PI, degToRad
from std/streams import FileStream, newFileStream, close

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

    CookTorranceNDF* = enum ndfGGX, ndfBeckmann

    BRDFKind* = enum LambertianBRDF, FresnelMetalBRDF, CookTorranceBRDF

    BRDF* = object
        pigment*: Pigment

        case kind*: BRDFKind
        of LambertianBRDF:
            reflectance*: float32

        of FresnelMetalBRDF: discard
    
        of CookTorranceBRDF:
            ndf*: CookTorranceNDF
            diffuseCoeff*: float32
            specularCoeff*: float32
            roughness*: float32
            refractionIndex*: float32

        
    Material* = tuple[brdf: BRDF, radiance: Pigment]


proc newUniformPigment*(color: Color): Pigment {.inline.} = Pigment(kind: pkUniform, color: color)

proc newTexturePigment*(texture: HDRImage): Pigment {.inline.} = Pigment(kind: pkTexture, texture: texture)


proc newTexturePigment*(fname: string): Pigment = 
    # Procedure to create a texture pigment from file
    var 
        str: FileStream
        img: HDRImage

    try:
        str = newFileStream(fname, fmRead)
    except:
        let msg = "Some problem occured in texture pigment file stream opening"
        raise newException(CatchableError, msg)

    img = str.readPFM().img
    Pigment(kind: pkTexture, texture: img)  

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


proc newLambertianBRDF*(pigment = newUniformPigment(WHITE), reflectance = 1.0): BRDF {.inline.} =
    BRDF(kind: LambertianBRDF, pigment: pigment, reflectance: reflectance)

proc newFresnelMetalBRDF*(pigment = newUniformPigment(WHITE)): BRDF {.inline.} =
    BRDF(kind: FresnelMetalBRDF, pigment: pigment) 


proc newCookTorranceBRDF*(pigment = newUniformPigment(WHITE), diffuseCoeff: float32 = 0.3, specularCoeff: float32 = 0.7, roughness: float32 = 0.5, refractionIndex: float32 = 1.0, ndf: CookTorranceNDF = CookTorranceNDF.ndfGGX): BRDF =
    assert (diffuseCoeff + specularCoeff <= 1.0)
    BRDF(
        kind: CookTorranceBRDF, ndf: ndf, pigment: pigment, 
        diffuseCoeff: diffuseCoeff, 
        specularCoeff: specularCoeff, 
        roughness: roughness, refractionIndex: refractionIndex 
    )


proc BeckmannDistribution(normal, midDir: Vec3f, roughness: float32): float32 =
    let (roughness2, cos2) = (pow(roughness, 2), pow(dot(normal, midDir), 2))
    exp((cos2 - 1) / (roughness2 * cos2)) / (PI * roughness2 * pow(cos2, 2))
    

proc GGXDistribution(normal, midDir: Vec3f, roughness: float32): float32 =
    let roughness2 = pow(roughness, 2)
    return roughness2 / (PI * pow(pow(dot(normal, midDir), 2) * (roughness2 - 1) + 1, 2))
    

proc FresnelSchlick(normal, midDir: Vec3f, refractionIndex: float32): float32 = 
    let F0 = pow((refractionIndex - 1) / (refractionIndex + 1), 2)
    return F0 + (1 - F0) * pow(1.0 - dot(normal, midDir), 5.0)

proc GeometricAttenuation(normal, inDir, outDir, midDir: Vec3f): float32 {.inline.} =
    min(1, 2 * dot(normal, midDir) * min(dot(normal, inDir), dot(normal, outDir)) / dot(inDir, midDir))


proc eval*(brdf: BRDF; surfacePoint: Point2D, normal, inDir, outDir: Vec3f): float32 {.inline.} =
    case brdf.kind: 
    of LambertianBRDF: return brdf.reflectance / PI

    of FresnelMetalBRDF: return 1.0

    of CookTorranceBRDF: 
        let
            midDir = inDir + outDir
            D = case brdf.ndf
                of ndfBeckmann: BeckmannDistribution(normal, midDir, brdf.roughness)
                of ndfGGX: GGXDistribution(normal, midDir, brdf.roughness)

            F = FresnelSchlick(normal, midDir, brdf.refractionIndex)
            G = GeometricAttenuation(normal, inDir, outDir, midDir)

        return brdf.diffuseCoeff / PI + 0.25 * brdf.specularCoeff * D * F * G / (dot(normal, inDir) * dot(normal, outDir))


proc scatterDir*(brdf: BRDF, hitNormal: Normal, hitDir: Vec3f, rg: var PCG): Vec3f =
    case brdf.kind
    of LambertianBRDF:
        let 
            (cos2, phi) = (rg.rand, 2 * PI.float32 * rg.rand)
            cos = sqrt(cos2)
            base = newONB(hitNormal)
        
        return cos * cos(phi) * base[0] + cos * sin(phi) * base[1] + sqrt(1 - cos2) * base[2]

    of FresnelMetalBRDF: 
        return hitDir - 2 * dot(hitNormal.Vec3f, hitDir) * hitNormal.Vec3f

    of CookTorranceBRDF:
        let
            base = newONB(hitNormal)
            rand = rg.rand

            phi = 2 * PI * rg.rand
            theta = 
                case brdf.ndf
                of ndfBeckmann: arctan(sqrt(-pow(brdf.roughness, 2.0) * ln(1 - rand)))
                of ndfGGX: arctan(brdf.roughness * sqrt(rand) / sqrt(1 - rand))

        return base[0] * sin(theta) * cos(phi) + base[1] * sin(theta) * sin(phi) + base[2] * cos(theta)


proc newMaterial*(brdf = newLambertianBRDF(), pigment = newUniformPigment(BLACK)): Material {.inline.} = (brdf: brdf, radiance: pigment)
