import std/[streams, tables]

#----------------------------------------------------#
#                SourceLocation type                 #
#----------------------------------------------------#
type SourceLocation* = object
    filename*: string = ""
    line_num*: int = 0
    col_num*: int = 0

proc newSourceLocation*(name = "", line: int = 0, col: int = 0): SourceLocation {.inline.} = 
    # SourceLocation variable constructor
    SourceLocation(filename: name, line_num: line, col_num: col)


proc `$`*(location: SourceLocation): string {.inline.} =
    # Procedure that prints SourceLocation contents, useful for error signaling
    result = "File: " & location.filename & ", Line: " & $location.line_num & ", Column: " & $location.col_num



#---------------------------------------------------#
#                    Token type                     #
#---------------------------------------------------#
type KeywordKind* = enum
    # Different kinds of keyword
    
    NEW = 1,
    TRANSLATION = 2,
    ROTATION_X = 3,
    ROTATION_Y = 4,
    ROTATION_Z = 5,
    SCALING = 6,
    COMPOSITION = 7,
    IDENTITY = 8,
    CAMERA = 9,
    ORTHOGONAL = 10,
    PERSPECTIVE = 11,
    PLANE = 12,
    SPHERE = 13,
    AABOX = 14,
    TRIANGLE = 15,
    CYLINDER = 16,
    TRIANGULARMESH = 17, 
    MATERIAL = 18,
    DIFFUSE = 19,
    SPECULAR = 20,
    UNIFORM = 21,
    CHECKERED = 22,
    TEXTURE = 23,
    FLOAT = 24


const KEYWORD* = {
    KeywordKind.NEW: "new",
    KeywordKind.TRANSLATION: "translation",
    KeywordKind.ROTATION_X: "rotationX",    
    KeywordKind.ROTATION_Y: "rotationY",
    KeywordKind.ROTATION_Z: "rotationZ",
    KeywordKind.SCALING: "scaling",
    KeywordKind.COMPOSITION: "composition",
    KeywordKind.IDENTITY: "identity",
    KeywordKind.CAMERA: "camera",
    KeywordKind.ORTHOGONAL: "orthogonal",
    KeywordKind.PERSPECTIVE: "perspective",
    KeywordKind.PLANE: "plane",
    KeywordKind.SPHERE: "sphere",
    KeywordKind.AABOX: "aabox",
    KeywordKind.TRIANGLE: "triangle",
    KeywordKind.CYLINDER: "cylinder",
    KeywordKind.TRIANGULARMESH: "triangularMesh",
    KeywordKind.MATERIAL: "material",
    KeywordKind.DIFFUSE: "diffuse",
    KeywordKind.SPECULAR: "specular",
    KeywordKind.UNIFORM: "uniform",
    KeywordKind.CHECKERED: "checkered",
    KeywordKind.TEXTURE: "texture",
    KeywordKind.FLOAT: "float",
}.toTable


type 
    
    TokenKind* = enum
        # Defining possible token kinds

        KeywordToken,
        IdentifierToken,
        LiteralStringToken,
        LiteralNumberToken,
        SymbolToken,
        StopToken

    Token* = object
        # Token type 
        location*: SourceLocation

        case kind*: TokenKind
        of KeywordToken: 
            keyword*: KeywordKind
        of IdentifierToken:
            identifier*: string
        of LiteralStringToken:
            str*: string
        of LiteralNumberToken:
            value*: float32
        of SymbolToken: 
            symbol*: string
        of StopToken: 
            flag*: bool
