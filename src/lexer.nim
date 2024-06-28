import std/[streams, tables, options, sets]
from std/strformat import fmt
from std/sequtils import mapIt
from std/strutils import isDigit, parseFloat, isAlphaNumeric, join

import scene, material, camera, geometry, hdrimage

const 
    WHITESPACE* = ['\t', '\n', '\r', ' '] 
    SYMBOLS* = ['(', ')', '[', ']', '<', '>', ',', '*']

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
    # Different kinds of key
    
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
    FLOAT = 24,
    IMAGE = 25


const KEYWORDS* = {
    "new": KeywordKind.NEW,
    "translation": KeywordKind.TRANSLATION,
    "rotationX": KeywordKind.ROTATION_X,    
    "rotationY": KeywordKind.ROTATION_Y,
    "rotationZ": KeywordKind.ROTATION_Z,
    "scaling": KeywordKind.SCALING,
    "composition": KeywordKind.COMPOSITION,
    "identity": KeywordKind.IDENTITY,
    "camera": KeywordKind.CAMERA,
    "orthogonal": KeywordKind.ORTHOGONAL,
    "perspective": KeywordKind.PERSPECTIVE,
    "plane": KeywordKind.PLANE,
    "sphere": KeywordKind.SPHERE,
    "aabox": KeywordKind.AABOX,
    "triangle": KeywordKind.TRIANGLE,
    "cylinder": KeywordKind.CYLINDER,
    "triangularMesh": KeywordKind.TRIANGULARMESH,
    "material": KeywordKind.MATERIAL,
    "diffuse": KeywordKind.DIFFUSE,
    "specular": KeywordKind.SPECULAR,
    "uniform": KeywordKind.UNIFORM,
    "checkered": KeywordKind.CHECKERED,
    "texture": KeywordKind.TEXTURE,
    "float": KeywordKind.FLOAT,
    "image": KeywordKind.IMAGE
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


proc unreadChar*(inStr: var InputStream, ch: char) = 
    # Procedure to push a character back to the stream
   
    assert inStr.savedChar == '\0'
    inStr.savedChar = ch
    inStr.location = inStr.savedLocation


proc skipWhitespaceComments*(inStr: var InputStream) = 
    # We just want to avoid whitespace and comments 
    var ch: char

    ch = inStr.readChar()
    while (ch in WHITESPACE) or (ch == '#'):

        # Dealing with comments
        if ch == '#':
            while not (inStr.readChar() in ['\r','\n','\0']):
                discard
            
        ch = inStr.readChar()
        if ch == '\0':
            return

    # Unreading non whitespace or comment char read
    inStr.unreadChar(ch)


proc parseStringToken*(inStr: var InputStream, tokenLocation: SourceLocation): Token = 
    # Procedure to parse a string token
    var 
        ch: char
        str = ""
    
    # Here we just want to read a string (break condition will be an inverted comma ")
    while true:
        ch = inStr.readChar()
        if ch == '"': break

        if ch == '\0':
            let e = fmt"Unterminated string starting at (Line: {tokenLocation.lineNum}, Column: {tokenLocation.colNum}), missing closing inverted commas."
            raise newException(GrammarError, e)
        
        str = str & ch

    return newLiteralStringToken(tokenLocation, str)


proc parseNumberToken*(inStr: var InputStream, firstCh: char, tokenLocation: SourceLocation): Token = 
    # Procedure to parse a number, the output will be a LiteralNumberToken with value field float32
    var 
        ch: char
        numStr = ""
        val: float32
    numStr = numStr & firstCh
    
    # Number reading proc ends if we get a non-digit as char
    while true:
        ch = inStr.readChar()

        if not (ch.isDigit() or (ch == '.') or (ch in ['e', 'E'])):
            inStr.unreadChar(ch)
            break
        
        numStr = numStr & ch
    
    try:
        val = parseFloat(numStr)
    except ValueError:
        let e = fmt"{numStr} is an invalid floating-point number"
        raise newException(GrammarError, e)

    return newLiteralNumberToken(tokenLocation, val)


proc parseKeywordOrIdentifierToken*(inStr: var InputStream, firstCh: char, tokenLocation: SourceLocation): Token = 
    # Procedure to read wether a keyword token or an identifier token
    var
        ch: char
        tokStr = ""
    tokStr = tokStr & firstCh

    while true:
        ch = inStr.readChar()

        if not (ch.isAlphaNumeric or ch == '_'):
            inStr.unreadChar(ch)
            break
        
        tokStr = tokStr & ch
    
    try:
        return newKeywordToken(tokenLocation, KEYWORDS[tokStr])
    except KeyError:
        return newIdentifierToken(tokenLocation, tokStr)


proc readToken*(inStr: var InputStream): Token =
    # Procedure to read a token from input stream
    var
        ch: char
        tokenLocation: SourceLocation

    # Checking wether we already have a saved token or not
    if inStr.savedToken.isSome:
        result = inStr.savedToken.get
        inStr.savedToken = none Token
        return result

    inStr.skipWhitespaceComments()
    
    # Reading a char that we know is not a whitespace or part of a comment line
    # We first need to check wether we are in eof condition
    ch = inStr.readChar()
    if ch == '\0':
        return newStopToken(inStr.location, true)
    
    # We now have to chose between five possible different token
    tokenLocation = inStr.location

    if ch in SYMBOLS:
        # Symbol token
        return newSymbolToken(tokenLocation, $ch)

    elif ch == '"':
        # Literal string token
        return inStr.parseStringToken(tokenLocation)

    elif ch.isDigit or (ch in ['+', '-', '.']):
        # Literal number token
        return inStr.parseNumberToken(ch, tokenLocation)

    elif ch.isAlphaNumeric() or (ch == '_'):
        # Keyword or identifier token
        return inStr.parseKeywordOrIdentifierToken(ch, tokenLocation)
    
    else:
        # Error condition, something wrong is happening
        let msg = fmt"Invalid character: {ch} in: " & $inStr.location
        raise newException(GrammarError, msg)


proc unreadToken*(inStr: var InputStream, token: Token) =
    # Procedure to unread a whole token from stream file
    assert inStr.savedToken.isNone
    inStr.savedToken = some token



#----------------------------------------------------------------#
#       DefScene type: everything needed to define a scene       #
#----------------------------------------------------------------#
type DefScene* = object
    scene*: Scene
    materials*: Table[string, material.Material]
    camera*: Option[camera.Camera]
    numVariables*: Table[string, float32]
    overriddenVariables*: HashSet[string]


proc newDefScene*(sc: Scene, mat: Table[string, material.Material], cam: Option[camera.Camera], numV: Table[string, float32], ovV: HashSet[string]): DefScene {.inline.} = 
    # Procedure to initialize a new DefScene variable, needed at the end of the parsing proc
    DefScene(scene: sc, materials: mat, camera: cam, numVariables: numV, overriddenVariables: ovV)



#---------------------------------------------------------------#
#                        Expect procedures                      #
#---------------------------------------------------------------#
proc expectSymbol*(inStr: var InputStream, sym: char) =
    # Read a token and checks wheter is a Symbol or not
    let tok = inStr.readToken()
    if (tok.kind != SymbolToken) or (tok.symbol != $sym):
        let e_msg = fmt"Error: got {tok.symbol} instead of " & sym & ". Error in: " & $inStr.location
        raise newException(GrammarError, e_msg)


proc expectKeywords*(inStr: var InputStream, keys: seq[KeywordKind]): KeywordKind =
    # Read a token and checks wether there is in the key kind list 
    var tok: Token

    tok = inStr.readToken()
    if tok.kind != KeywordToken:
        let msg = fmt"Expected a KeywordToken instead of {tok.kind}. Error in: " & $inStr.location
        raise newException(GrammarError, msg)
    
    if not (tok.keyword in keys):
        let msg = fmt"Keywords expected where: [" & join(keys.mapIt(it), ", ") &  "] instead of {tok.keyword}"
        raise newException(GrammarError, msg)

    return tok.keyword


proc expectNumber*(inStr: var InputStream, dSc: var DefScene): float32 =
    # Procedure to read a LiteralNumberToken and check if is a literal number or a variable
    var 
        tok: Token
        varName: string
    
    tok = inStr.readToken()
    # If it's a literal number token i want to return its value
    if tok.kind == LiteralNumberToken:
        return tok.value
    # If it's an IdentifierToken, we just have to check if it's a variable name
    elif tok.kind == IdentifierToken:
        varName = tok.identifier
        if not (varName in dSc.numVariables):
            let msg = fmt"Unknown variable {varName}. Error in " & $inStr.location
            raise newException(GrammarError, msg) 
        return dSc.numVariables[varName]

    let msg = fmt"Got {tok.kind} instead of LiteralNumberToken or IdentifierToken. Error in: " & $inStr.location
    raise newException(GrammarError, msg)


proc expectString*(inStr: var InputStream): string = 
    # Procedure to read a LiteralStringToken
    var tok: Token

    tok = inStr.readToken()
    # Error condition is just token kind, here we just accept a LiteralStringToken
    if tok.kind != LiteralStringToken:
        let msg = fmt"Got {tok.kind} instead of LiteralStringToken. Error in: " & $inStr.location
        raise newException(GrammarError, msg)
    
    return tok.str


proc expectIdentifier*(inStr: var InputStream): string = 
    # Procedure to read an IdentifierToken
    var tok: Token

    tok = inStr.readToken()
    # Error condition is just token kind, here we just accept an IdentifierToken
    if tok.kind != IdentifierToken:
        let msg = fmt"Got {tok.kind} instead of IdentifierToken. Error in: " & $inStr.location
        raise newException(GrammarError, msg)
    
    return tok.identifier



#------------------------------------------------------------------#
#                           Parse procs                            #
#------------------------------------------------------------------#
proc parseVec*(inStr: var InputStream, dSc: var DefScene): Vec3f = 
    # Procedure to parse a Vec3f, remeber that it's between square brakets
    var x, y, z: float32

    inStr.expectSymbol('[')
    x = inStr.expectNumber(dSc)
    inStr.expectSymbol(',')
    y = inStr.expectNumber(dSc)
    inStr.expectSymbol(',')
    z = inStr.expectNumber(dSc)
    inStr.expectSymbol(']')

    return newVec3f(x, y, z)


proc parseColor*(inStr: var InputStream, dSc: var DefScene): Color = 
    # Procedure to parse a Color, remeber that it's between <>
    var r, g, b: float32

    inStr.expectSymbol('<')
    r = inStr.expectNumber(dSc)
    inStr.expectSymbol(',')
    g = inStr.expectNumber(dSc)
    inStr.expectSymbol(',')
    b = inStr.expectNumber(dSc)
    inStr.expectSymbol('>')

    return newColor(r, g, b)


proc parsePigment*(inStr: var InputStream, dSc: var DefScene): Pigment = 
    # Procedure to parse a specific Pigment
    var 
        col1, col2: Color
        nRows, nCols: int
        key = inStr.expectKeywords(@[KeywordKind.UNIFORM, KeywordKind.CHECKERED, KeywordKind.TEXTURE])
    
    inStr.expectSymbol('(')
    if key == KeywordKind.UNIFORM:
        # Uniform pigment kind
        col1 = inStr.parseColor(dSc)
        result = newUniformPigment(col1)

    elif key == KeywordKind.CHECKERED:
        # Checkered pigment kind
        col1 = inStr.parseColor(dSc)
        inStr.expectSymbol(',')
        col2 = inStr.parseColor(dSc)
        inStr.expectSymbol(',')
        nRows = inStr.expectNumber(dSc).int
        inStr.expectSymbol(',')
        nCols = inStr.expectNumber(dSc).int

        result = newCheckeredPigment(col1, col2, nRows, nCols)
    
    elif key == KeywordKind.TEXTURE:
        # Texture pigment kind
        var
            img: HDRImage
            fname: string
            str: FileStream
        fname = inStr.expectString()
        
        try:
            str = newFileStream(fname)
        except:
            let msg = "Error in stream opening procedure. Error in: " & $inStr.location
            raise newException(CatchableError, msg)
        
        img = str.readPFM().img        
        result = newTexturePigment(img)

    else:
        assert false, "Something went wrong in parsePigment, this line should be unreachable."

    inStr.expectSymbol(')')


proc parseBRDF*(inStr: var InputStream, dSc: var DefScene): BRDF = 
    # Procedure to parse a BRDF variable
    var
        key = inStr.expectKeywords(@[KeywordKind.DIFFUSE, KeywordKind.SPECULAR])
        pig: Pigment

    # Parsing pigment first
    inStr.expectSymbol('(')
    pig = inStr.parsePigment(dSc)
    inStr.expectSymbol(')')

    # Selecting desired BRDF kind
    if key == KeywordKind.DIFFUSE:
        # Diffusive BRDF kind
        return newDiffuseBRDF(pig)
    elif key == KeywordKind.SPECULAR:
        # Specular BRDF kind
        return newSpecularBRDF(pig)
    
    assert false, "Something went wrong in parseBRDF, this line should be unreachable"


proc parseMaterial*(inStr: var InputStream, dSc: var DefScene): tuple[name: string, mat: Material] = 
    # Procedure to parse a material
    var
        brdf: BRDF
        emRad: Pigment 
        varName = inStr.expectIdentifier()

    inStr.expectSymbol('(')
    brdf = inStr.parseBRDF(dSc)
    inStr.expectSymbol(',')
    emRad = inStr.parsePigment(dSc)
    inStr.expectSymbol(')')

    return (varName, newMaterial(brdf, emRad))


proc parseTransformation*(inStr: var InputStream, dSc: var DefScene): Transformation = 
    # Procedure to parse a transformation
    let
        allowedK = @[
            KeywordKind.IDENTITY, 
            KeywordKind.TRANSLATION, 
            KeywordKind.ROTATION_X, 
            KeywordKind.ROTATION_Y, 
            KeywordKind.ROTATION_Z, 
            KeywordKind.SCALING, 
            ]
    
    var
        tok: Token
        key: KeywordKind
        count: int = 0

    result = Transformation.id

    # We keep reading until we are sure there is not a following transformation
    while true:
        key = inStr.expectKeywords(allowedK)

        if key == KeywordKind.IDENTITY:
            # Identity transformation, we just have nothing to do
            discard
        
        elif key == KeywordKind.TRANSLATION:
            # Translation, we just want to check count value 
            # in order to understand if we have to return a tkComposition or a tkTranslation
            inStr.expectSymbol('(')
            
            if count == 0: 
                result = newTranslation(inStr.parseVec(dSc))
            else: 
                result = result @ newTranslation(inStr.parseVec(dSc))
            
            count += 1
            inStr.expectSymbol(')') 

        elif key in [KeywordKind.ROTATION_X, KeywordKind.ROTATION_Y, KeywordKind.ROTATION_Z]:
            # Rotation, we just don't have different kinds
            # Also here we have to check for count value
            inStr.expectSymbol('(')

            if count == 0:
                if key == KeywordKind.ROTATION_X:
                    result = newRotX(inStr.expectNumber(dSc))
                elif key == KeywordKind.ROTATION_Y:
                    result = newRotY(inStr.expectNumber(dSc))
                elif key == KeywordKind.ROTATION_Z:
                    result = newRotZ(inStr.expectNumber(dSc))

            else:
                if key == KeywordKind.ROTATION_X:
                    result = result @ newRotX(inStr.expectNumber(dSc))
                elif key == KeywordKind.ROTATION_Y:
                    result = result @ newRotY(inStr.expectNumber(dSc))
                elif key == KeywordKind.ROTATION_Z:
                    result = result @ newRotZ(inStr.expectNumber(dSc))

            count += 1  
            inStr.expectSymbol(')')
        
        elif key == KeywordKind.SCALING:
            # Scaling, also here we have to check for count value
            inStr.expectSymbol('(')
            
            if count == 0: 
                result = newScaling(inStr.parseVec(dSc))
            else: 
                result = result @ newScaling(inStr.parseVec(dSc))
            
            count += 1
            inStr.expectSymbol(')') 
        
        # We must see the next token in order to know if we ought to stop or not
        tok = inStr.readToken()
        if (tok.kind != SymbolToken) or (tok.symbol != $'*'):
            # Here we want to break the transformation parsing proc
            inStr.unreadToken(tok)
            break
        
    return result
