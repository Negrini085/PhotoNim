import geometry, hdrimage

from std/streams import newFileStream
from std/math import floor


type 
    PigmentKind* = enum pkUniform, pkTexture, pkCheckered
    Pigment* = object
        case kind*: PigmentKind
        of pkUniform: color*: Color
        of pkTexture: texture*: HDRImage
        of pkCheckered: grid*: tuple[c1, c2: Color, nRows, nCols: int]


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