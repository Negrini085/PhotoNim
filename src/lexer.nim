import std/[streams, tables, options]

const 
    WHITESPACE* = ['\t', '\n', '\r'] 
    SYMBOLS* = ["(", ")", "[", "]", "<", ">", ",", "*"]

#----------------------------------------------------#
#                SourceLocation type                 #
#----------------------------------------------------#
type SourceLocation* = object
    filename*: string = ""
    lineNum*: int = 0
    colNum*: int = 0

proc newSourceLocation*(name = "", line: int = 0, col: int = 0): SourceLocation {.inline.} = 
    # SourceLocation variable constructor
    SourceLocation(filename: name, lineNum: line, colNum: col)


proc `$`*(location: SourceLocation): string {.inline.} =
    # Procedure that prints SourceLocation contents, useful for error signaling
    result = "File: " & location.filename & ", Line: " & $location.lineNum & ", Column: " & $location.colNum



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



                #       Token variables constructors      #

proc newKeywordToken*(location: SourceLocation, keyword: KeywordKind): Token {.inline.} =
    Token(kind: KeywordToken, location: location, keyword: keyword)

proc newIdentifierToken*(location: SourceLocation, identifier: string): Token {.inline.} =
    Token(kind: IdentifierToken, location: location, identifier: identifier)

proc newLiteralStringToken*(location: SourceLocation, str: string): Token {.inline.} =
    Token(kind: LiteralStringToken, location: location, str: str)

proc newLiteralNumberToken*(location: SourceLocation, value: float32): Token {.inline.} =
    Token(kind: LiteralNumberToken, location: location, value: value)

proc newSymbolToken*(location: SourceLocation, symbol: string): Token {.inline.} =
    Token(kind: SymbolToken, location: location, symbol: symbol)

proc newStopToken*(location: SourceLocation, flag = false): Token {.inline.} =
    Token(kind: StopToken, location: location, flag: flag)


#---------------------------------------------------#
#                InputStream type                   #
#---------------------------------------------------#
type 

    GrammarError* = object of CatchableError

    InputStream* = object
        # Necessary to parse scene files

        # Input stream variables
        tabs*: int
        stream*: FileStream
        location*: SourceLocation

        # Variables to be able to unread a character
        savedChar*: char
        savedToken*: Option[Token]
        savedLocation*: SourceLocation


proc newInputStream*(stream: FileStream, filename: string, tabs = 4): InputStream = 
    # InputStream variable constructor
    InputStream(
        tabs: tabs, stream: stream, 
        location: newSourceLocation(filename, 1, 1), savedChar: '\0', 
        savedToken: none Token, savedLocation: newSourceLocation(filename, 1, 1)
        )


proc updateLocation*(inStr: var InputStream, ch: char) = 
    # Procedure to update stream location whenever a character is ridden

    if ch == '\0': return
    elif ch == '\n':
        # Starting to read a new line
        inStr.location.colNum = 1
        inStr.location.lineNum += 1
    elif ch == '\t':
        inStr.location.colNum += inStr.tabs
    else:
        inStr.location.colNum += 1


proc readChar*(inStr: var InputStream): char =
    # Procedure to read a new char from the stream

    # What if we have an unread character?
    if inStr.savedChar != '\0':
        result = inStr.savedChar
        inStr.savedChar = '\0'
    
    # Otherwise we read a new character from the stream
    else:
        result = readChar(inStr.stream)

    inStr.savedLocation = inStr.location
    inStr.updateLocation(result)
