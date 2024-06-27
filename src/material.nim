import geometry, pcg, hdrimage

from std/math import floor, pow, sqrt, exp, ln, sin, cos, arccos, PI, degToRad
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

    CookTorranceNDF* = enum ndfGGX, ndfBeckmann, ndfBlinn

    BRDFKind* = enum DiffuseBRDF, SpecularBRDF, CookTorranceBRDF

    BRDF* = object
        pigment*: Pigment

        case kind*: BRDFKind
        of DiffuseBRDF:
            reflectance*: float32
        of SpecularBRDF:
            thresholdAngle*: float32
    
        of CookTorranceBRDF:
            ndf*: CookTorranceNDF
            diffuseCoeff*: float32
            specularCoeff*: float32
            roughness*: float32
            albedo*: float32
            metallic*: float32
        
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
    BRDF(kind: SpecularBRDF, pigment: pigment, thresholdAngle: degToRad(angle)) 


proc newCookTorranceBRDF*(pigment = newUniformPigment(WHITE), diffuseCoeff: float32 = 0.3, specularCoeff: float32 = 0.7, roughness: float32 = 0.5, albedo: float32 = 0.5, metallic: float32 = 0.1, ndf: CookTorranceNDF = CookTorranceNDF.ndfGGX): BRDF =
    assert (diffuseCoeff + specularCoeff <= 1.0)
    BRDF(
        kind: CookTorranceBRDF, ndf: ndf, pigment: pigment, 
        diffuseCoeff: diffuseCoeff, 
        specularCoeff: specularCoeff, 
        roughness: roughness, albedo: albedo, metallic: metallic
    )


proc distBeckmann(normal, inDir, outDir: Vec3f, roughness: float32): float32 =
    let 
        cos2 = pow(dot(normal, inDir + outDir), 2)
        roughness2 = pow(roughness, 2)
    
    exp((cos2 - 1) / (roughness2 * cos2)) / (PI * roughness2 * pow(cos2, 2))

proc FresnelSchlick(normal, inDir, outDir: Vec3f, refractionIndex: float32): float32 = 
    let F0 = pow(refractionIndex - 1, 2.0) / pow(refractionIndex + 1, 2.0)
    return F0 + (1 - F0) * pow(1.0 - dot(normal, inDir + outDir), 5.0)

proc geometricAttenuation(normal, inDir, outDir: Vec3f): float32 =
    let 
        halfVector = inDir + outDir
        dot1 = dot(normal, halfVector)
        dot2 = min(dot(normal, inDir), dot(normal, outDir))
    
    min(1, 2 * dot1 * dot2 / dot(inDir, halfVector))


proc eval*(brdf: BRDF; surfacePoint: Point2D, normal, inDir, outDir: Vec3f): float32 {.inline.} =
    case brdf.kind: 
    of DiffuseBRDF: return brdf.reflectance / PI

    of SpecularBRDF: 
        # assert areClose(normal.norm, 1.0, 1e-2), fmt"{normal.norm}"
        # assert areClose(inDir.norm, 1.0, 1e-2), fmt"{inDir.norm}"
        # assert areClose(outDir.norm, 1.0, 1e-2), fmt"{outDir.norm}"
        let (angleIn, angleOut) = (PI - arccos(dot(normal, inDir)), arccos(dot(normal, outDir)))
        # echo (angleIn, angleOut, angleIn - angleOut, angleIn + angleOut)
        # assert areClose(angleIn + angleOut, PI, 0.1)
        return if angleIn + angleOut <= brdf.thresholdAngle: 1.0 else: 0.0
        # return if abs(arccos(dot(inDir, outDir))) <= brdf.thresholdAngle: 1.0 else: 0.0

    of CookTorranceBRDF: 
        let
            D = distBeckmann(normal, inDir, outDir, brdf.roughness)
            F = FresnelSchlick(normal, inDir, outDir, 1.5)
            G = geometricAttenuation(normal, inDir, outDir)
            kSpec = 0.25 * D * F * G / (dot(normal, inDir) * dot(normal, outDir))

        return brdf.diffuseCoeff / PI + brdf.specularCoeff * kSpec


proc scatterDir*(brdf: BRDF, hitNormal: Normal, hitDir: Vec3f, rg: var PCG): Vec3f =
    case brdf.kind
    of DiffuseBRDF:
        let 
            (cos2, phi) = (rg.rand, 2 * PI.float32 * rg.rand)
            c = sqrt(cos2)
            base = newONB(hitNormal)
        
        return c * cos(phi) * base[0] + c * sin(phi) * base[1] + sqrt(1 - cos2) * base[2]

    of SpecularBRDF: 
        return hitDir - 2 * dot(hitNormal.Vec3f, hitDir) * hitNormal.Vec3f

    of CookTorranceBRDF:
        let
            base = newONB(hitNormal)
            rough2 = pow(brdf.roughness, 2.0)

            theta = 
                case brdf.ndf
                of ndfGGX: arccos(sqrt(rough2 / (rg.rand * (rough2 - 1) + 1)))
                of ndfBeckmann: arccos(sqrt(1 / (1 - rough2 * ln(1 - rg.rand))))
                of ndfBlinn: arccos(1.0 / pow(rg.rand, brdf.roughness + 1))

            phi = rg.rand

        return base[0] * sin(theta) * cos(phi) + base[1] * sin(theta) * sin(phi) + base[2] * cos(theta)


proc newMaterial*(brdf = newDiffuseBRDF(), pigment = newUniformPigment(BLACK)): Material {.inline.} = (brdf: brdf, radiance: pigment)
