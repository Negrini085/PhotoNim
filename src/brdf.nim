import geometry, pcg, pigment

from std/math import pow, sqrt, exp, ln, sin, cos, arctan, PI


type
    CookTorranceNDF* = enum ndfGGX, ndfBeckmann

    BRDFKind* = enum DiffuseBRDF, SpecularBRDF, CookTorranceBRDF

    BRDF* = ref object
        pigment*: Pigment
        case kind*: BRDFKind
        of DiffuseBRDF: reflectance*: float32
        of SpecularBRDF: discard
        of CookTorranceBRDF:
            ndf*: CookTorranceNDF
            diffuseCoeff*: float32
            specularCoeff*: float32
            roughness*: float32
            refractionIndex*: float32


proc newDiffuseBRDF*(pigment: Pigment, reflectance = 1.0): BRDF {.inline.} = 
    BRDF(kind: DiffuseBRDF, pigment: pigment, reflectance: reflectance)

proc newSpecularBRDF*(pigment: Pigment): BRDF {.inline.} = 
    BRDF(kind: SpecularBRDF, pigment: pigment) 

proc newCookTorranceBRDF*(diffuseCoeff: float32 = 0.3, specularCoeff: float32 = 0.7, roughness: float32 = 0.5, refractionIndex: float32 = 1.0, ndf: CookTorranceNDF = CookTorranceNDF.ndfGGX): BRDF =
    assert (diffuseCoeff + specularCoeff <= 1.0)
    BRDF(
        kind: CookTorranceBRDF, ndf: ndf, 
        diffuseCoeff: diffuseCoeff, 
        specularCoeff: specularCoeff, 
        roughness: roughness, refractionIndex: refractionIndex 
    )


proc BeckmannDistribution(normal, midDir: Vec3, roughness: float32): float32 =
    let (roughness2, cos2) = (pow(roughness, 2), pow(dot(normal, midDir), 2))
    exp((cos2 - 1) / (roughness2 * cos2)) / (PI * roughness2 * pow(cos2, 2))
    

proc GGXDistribution(normal, midDir: Vec3, roughness: float32): float32 =
    let roughness2 = pow(roughness, 2)
    return roughness2 / (PI * pow(pow(dot(normal, midDir), 2) * (roughness2 - 1) + 1, 2))
    

proc FresnelSchlick(normal, midDir: Vec3, refractionIndex: float32): float32 = 
    let F0 = pow((refractionIndex - 1) / (refractionIndex + 1), 2)
    return F0 + (1 - F0) * pow(1.0 - dot(normal, midDir), 5.0)

proc GeometricAttenuation(normal, inDir, outDir, midDir: Vec3): float32 {.inline.} =
    min(1, 2 * dot(normal, midDir) * min(dot(normal, inDir), dot(normal, outDir)) / dot(inDir, midDir))


proc eval*(brdf: BRDF; normal, inDir, outDir: Vec3): float32 {.inline.} =
    case brdf.kind: 
    of DiffuseBRDF: return brdf.reflectance # / PI

    of SpecularBRDF: return 1.0

    of CookTorranceBRDF: 
        let
            midDir = inDir + outDir
            D = case brdf.ndf
                of ndfBeckmann: BeckmannDistribution(normal, midDir, brdf.roughness)
                of ndfGGX: GGXDistribution(normal, midDir, brdf.roughness)

            F = FresnelSchlick(normal, midDir, brdf.refractionIndex)
            G = GeometricAttenuation(normal, inDir, outDir, midDir)

        return brdf.diffuseCoeff / PI + 0.25 * brdf.specularCoeff * D * F * G / (dot(normal, inDir) * dot(normal, outDir))


proc scatterDir*(brdf: BRDF, hitNormal: Normal, hitDir: Vec3, rg: var PCG): Vec3 =
    case brdf.kind
    of DiffuseBRDF:
        let 
            (cos2, phi) = (rg.rand, 2 * PI.float32 * rg.rand)
            cos = sqrt(cos2)
            base = newONB(hitNormal)
        
        return cos * cos(phi) * base[0] + cos * sin(phi) * base[1] + sqrt(1 - cos2) * base[2]

    of SpecularBRDF: return hitDir - 2 * dot(hitNormal.Vec3, hitDir) * hitNormal.Vec3

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