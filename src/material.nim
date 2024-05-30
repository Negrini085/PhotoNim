import geometry, camera, pcg
from std/math import sum, pow, exp, log10, floor, arccos, degToRad, PI, sqrt, cos, sin

type
    PigmentKind* = enum
        pkUniform, pkTexture, pkCheckered

    Pigment* = object
        case kind*: PigmentKind
        of pkUniform: 
            color*: Color

        of pkTexture: 
            texture*: ptr HDRImage

        of pkCheckered:
            grid*: tuple[color1, color2: Color, nsteps: int]

proc newUniformPigment*(color: Color): Pigment {.inline.} = Pigment(kind: pkUniform, color: color)
proc newTexturePigment*(texture: HDRImage): Pigment {.inline.} = Pigment(kind: pkTexture, texture: addr texture)
proc newCheckeredPigment*(color1, color2: Color, nsteps: int): Pigment {.inline.} = Pigment(kind: pkCheckered, grid: (color1, color2, nsteps))

proc getColor*(pigment: Pigment; uv: Point2D): Color =
    case pigment.kind: 
    of pkUniform: 
        return pigment.color

    of pkTexture: 
        var (col, row) = (floor(uv.u * pigment.texture.width.float32).int, floor(uv.v * pigment.texture.height.float32).int)
        if col >= pigment.texture.width: col = pigment.texture.width - 1
        if row >= pigment.texture.height: row = pigment.texture.height - 1

        return pigment.texture[].getPixel(col, row)

    of pkCheckered:
        let (col, row) = (floor(uv.u * pigment.grid.nsteps.float32).int, floor(uv.v * pigment.grid.nsteps.float32).int)
        return (if (col mod 2) == (row mod 2): pigment.grid.color1 else: pigment.grid.color2)


type 
    BRDFKind* = enum 
        DiffuseBRDF, SpecularBRDF

    BRDF* = object
        pigment*: Pigment

        case kind*: BRDFKind
        of DiffuseBRDF:
            reflectance*: float32
        of SpecularBRDF:
            threshold_angle*: float32


proc newDiffuseBRDF*(pigment = newUniformPigment(WHITE), reflectance = 1.0): BRDF {.inline.} =
    BRDF(kind: DiffuseBRDF, pigment: pigment, reflectance: reflectance)

proc newSpecularBRDF*(pigment = newUniformPigment(WHITE), angle = 180.0): BRDF {.inline.} =
    BRDF(kind: SpecularBRDF, pigment: pigment, threshold_angle: (0.1 * degToRad(angle)).float32) 


proc eval*(brdf: BRDF; normal: Normal, in_dir, out_dir: Vec3f, uv: Point2D): Color {.inline.} =
    case brdf.kind: 
    of DiffuseBRDF: 
        return brdf.pigment.getColor(uv) * (brdf.reflectance / PI)

    of SpecularBRDF: 
        if abs(arccos(dot(normal.Vec3f, in_dir)) - arccos(dot(normal.Vec3f, out_dir))) < brdf.threshold_angle: 
            return brdf.pigment.getColor(uv)
        else: return BLACK


proc scatterRay*(brdf: BRDF, rg: var PCG, in_dir: Vec3f, hit_pt: Point3D, normal: Normal, depth: int): Ray =
    case brdf.kind:
    of DiffuseBRDF:
        let 
            ONB = newONB(normal)
            cos2 = rg.rand
            c = sqrt(cos2)
            s = sqrt(1 - cos2)
            phi = 2 * PI * rg.rand
        
        return Ray(
            origin: hit_pt,
            dir: ONB[0] * cos(phi) * c + ONB[1] * sin(phi) * c + ONB[2] * s,
            tspan: (float32 1e-3, float32 Inf), depth: depth
        )

    of SpecularBRDF: 
        let
            dir = in_dir.normalize
            norm = normal.Vec3f.normalize
        
        return Ray(
            origin: hit_pt,
            dir: dir - 2 * dot(norm, dir) * norm,
            tspan: (float32 1e-3, float32 Inf), depth: depth 
        )


type Material* = object
    brdf*: BRDF
    radiance*: Pigment

proc newMaterial*(brdf = newDiffuseBRDF(), pigment = newUniformPigment(WHITE)): Material {.inline.} = 
    Material(brdf: brdf, radiance: pigment)