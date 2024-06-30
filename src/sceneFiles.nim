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
    IMAGE = 25,
    BOX = 26


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
    "image": KeywordKind.IMAGE,
    "box": KeywordKind.BOX
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

    if ch == '\0': discard
    elif (ch == '\n'):
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
        result = inStr.stream.readChar()

        # What if we have a \r character? The problem is that 
        # we would like to know if the following char is a \n or not
        if result == '\r':
            inStr.savedLocation = inStr.location
            inStr.updateLocation(result)

            # Reading the following character
            result = inStr.readChar()

            # PhotoNim 
            if result != '\n':
                let msg = "PhotoNim doesn't run on old macOS versions."
                raise newException(CatchableError, msg)

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
    scene*: seq[ShapeHandler]
    materials*: Table[string, material.Material]
    camera*: Option[camera.Camera]
    numVariables*: Table[string, float32]
    overriddenVariables*: HashSet[string]


proc newDefScene*(sc: seq[ShapeHandler], mat: Table[string, material.Material], cam: Option[camera.Camera], numV: Table[string, float32], ovV: HashSet[string]): DefScene {.inline.} = 
    # Procedure to initialize a new DefScene variable, needed at the end of the parsing proc
    DefScene(scene: sc, materials: mat, camera: cam, numVariables: numV, overriddenVariables: ovV)



#---------------------------------------------------------------#
#                        Expect procedures                      #
#---------------------------------------------------------------#
proc expectSymbol*(inStr: var InputStream, sym: char) =
    # Read a token and checks wether is a Symbol or not
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


proc parseSphereSH*(inStr: var InputStream, dSc: var DefScene): ShapeHandler = 
    # Procedure to parse sphere shape handler 
    var 
        matName: string
        center: Point3D
        radius: float32

    # Parsing sphere center and radius
    inStr.expectSymbol('(')
    center = inStr.parseVec(dSc).Point3D
    inStr.expectSymbol(',')
    radius = inStr.expectNumber(dSc)
    inStr.expectSymbol(',')

    # Parsing material (we need to check if we already defined it)
    matName = inStr.expectIdentifier()
    if not (matName in dSc.materials):
        # If you get inside of this if condition, it's because 
        # you are pointing at the end of the wrong identifier
        let msg = fmt "Unknown material: {matName}"
        raise newException(GrammarError, msg)

    inStr.expectSymbol(')')

    return newSphere(center, radius, material = dSc.materials[matName])


proc parsePlaneSH*(inStr: var InputStream, dSc: var DefScene): ShapeHandler = 
    # Procedure to parse plane shape handler
    var 
        matName: string
        trans: Transformation

    inStr.expectSymbol('(')

    # Parsing material (we need to check if we already defined it)
    matName = inStr.expectIdentifier()
    if not (matName in dSc.materials):
        # If you get inside of this if condition, it's because 
        # you are pointing at the end of the wrong identifier
        let msg = fmt "Unknown material: {matName}"
        raise newException(GrammarError, msg)

    # Parsing transformation
    inStr.expectSymbol(',')
    trans = inStr.parseTransformation(dSc)
    inStr.expectSymbol(')')

    return newPlane(dSc.materials[matName], trans)


proc parseBoxSH*(inStr: var InputStream, dSc: var DefScene): ShapeHandler = 
    # Procedure to parse box shape handler
    var 
        minP, maxP: Point3D
        matName: string
        trans: Transformation

    # Parsing box limits
    inStr.expectSymbol('(')
    minP = inStr.parseVec(dSc).Point3D
    inStr.expectSymbol(',')
    maxP = inStr.parseVec(dSc).Point3D
    # Checking wether minP it's actually lower limit of the box
    if (minP.x > maxP.x) or (minP.y > maxP.y) or (minP.z > maxP.z):
        let msg = "Be careful, first variable is lower limit of the box. Error in: " & $ inStr.location
        raise newException(GrammarError, msg)

    inStr.expectSymbol(',')

    # Parsing material (we need to check if we already defined it)
    matName = inStr.expectIdentifier()
    if not (matName in dSc.materials):
        # If you get inside of this if condition, it's because 
        # you are pointing at the end of the wrong identifier
        let msg = fmt "Unknown material: {matName}"
        raise newException(GrammarError, msg)

    # Parsing transformation
    inStr.expectSymbol(',')
    trans = inStr.parseTransformation(dSc)
    inStr.expectSymbol(')')

    return newBox((min: minP, max: maxP), dSc.materials[matName], trans)


proc parseTriangleSH*(inStr: var InputStream, dSc: var DefScene): ShapeHandler = 
    # Procedure to parse triangle shape handler
    var 
        p1, p2, p3: Point3D
        matName: string
        trans: Transformation

    # Parsing triangle vertices
    inStr.expectSymbol('(')
    p1 = inStr.parseVec(dSc).Point3D
    inStr.expectSymbol(',')
    p2 = inStr.parseVec(dSc).Point3D
    inStr.expectSymbol(',')
    p3 = inStr.parseVec(dSc).Point3D
    inStr.expectSymbol(',')


    # Parsing material (we need to check if we already defined it)
    matName = inStr.expectIdentifier()
    if not (matName in dSc.materials):
        # If you get inside of this if condition, it's because 
        # you are pointing at the end of the wrong identifier
        let msg = fmt "Unknown material: {matName}"
        raise newException(GrammarError, msg)

    # Parsing transformation
    inStr.expectSymbol(',')
    trans = inStr.parseTransformation(dSc)
    inStr.expectSymbol(')')

    return newTriangle([p1, p2, p3], dSc.materials[matName], trans)


proc parseCylinderSH*(inStr: var InputStream, dSc: var DefScene): ShapeHandler = 
    # Procedure to parse cylinder shape handler
    var 
        r, zMin, zMax, phiMax: float32
        matName: string
        trans: Transformation

    # Parsing cylinder variables
    inStr.expectSymbol('(')
    r = inStr.expectNumber(dSc)
    inStr.expectSymbol(',')
    zMin = inStr.expectNumber(dSc)
    inStr.expectSymbol(',')
    zMax = inStr.expectNumber(dSc)
    # Checking wether z-coordinates are well inserted or not
    if zMax <  zMin:
        let msg = "Be careful, first z-coordinate must be the smaller one. Error in: " & $inStr.location
        raise newException(GrammarError, msg)
    inStr.expectSymbol(',')
    phiMax = inStr.expectNumber(dSc)
    inStr.expectSymbol(',')


    # Parsing material (we need to check if we already defined it)
    matName = inStr.expectIdentifier()
    if not (matName in dSc.materials):
        # If you get inside of this if condition, it's because 
        # you are pointing at the end of the wrong identifier
        let msg = fmt "Unknown material: {matName}"
        raise newException(GrammarError, msg)

    # Parsing transformation
    inStr.expectSymbol(',')
    trans = inStr.parseTransformation(dSc)
    inStr.expectSymbol(')')

    return newCylinder(r, zMin, zMax, phiMax, dSc.materials[matName], trans)


proc parseMeshSH*(inStr: var InputStream, dSc: var DefScene): ShapeHandler = 
    # Procedure to parse mesh shape handler
    var 
        fName: string
        trans: Transformation

    # Parsing .obj filename
    inStr.expectSymbol('(')
    fname = inStr.expectString()
    inStr.expectSymbol(',')

    # Parsing transformation
    trans = inStr.parseTransformation(dSc)
    inStr.expectSymbol(')')

    return newMesh(fName, trans, tkBinary, 3, 42, 1)


proc parseCamera*(inStr: var InputStream, dSc: var DefScene): Camera = 
    # Procedure to parse a camera
    let
        allowedK = @[
            KeywordKind.PERSPECTIVE,
            KeywordKind.ORTHOGONAL 
            ]
        rend = newOnOffRenderer()   # As right now, giving an OnOff renderer as defalt renderer
    
    var 
        dist: float32
        key: KeywordKind
        width, height: int
        trans: Transformation

    # Parsing kind and image dimensions
    inStr.expectSymbol('(')
    key = inStr.expectKeywords(allowedK)
    inStr.expectSymbol(',')
    width = inStr.expectNumber(dSc).int
    inStr.expectSymbol(',')
    height = inStr.expectNumber(dSc).int
    inStr.expectSymbol(',')

    # Parsing distance (only for persepctive camera)
    if key == KeywordKind.PERSPECTIVE:
        dist = inStr.expectNumber(dSc)

        # Checking wether it's a positive value or not
        if dist <= 0:
            let msg = "Be careful, camera distance must be a positive floating-point number. Error in: " & $inStr.location
            raise newException(GrammarError, msg)
        
        inStr.expectSymbol(',')

    # Parsing transformation
    trans = inStr.parseTransformation(dSc)
    inStr.expectSymbol(')')

    if key == KeywordKind.PERSPECTIVE:
        result = newPerspectiveCamera(rend, (width, height), dist, trans)
    elif key == KeywordKind.ORTHOGONAL:
        result = newOrthogonalCamera(rend, (width, height), trans)
    
    return result


proc parseDefScene*(inStr: var InputStream): DefScene = 
    # Procedure to parse the whole file and to create the DefScene variable 
    # that will be the starting point of the rendering process
    var 
        dSc: DefScene
        tryTok: Token
        mat: Material
        varName: string
        varVal: float32

    while true:
        tryTok = inStr.readToken()
        
        # What if we are in Eof condition?
        if tryTok.kind == StopToken:
            break
        
        # The only thing that is left is reading Keywords
        if tryTok.kind != KeywordToken:
            let msg = fmt"Expected a keyword instead of {tryTok.kind}. Error in: " & $inStr.location
            raise newException(GrammarError, msg)
        
        # Just in case we are defining a float variable
        if tryTok.keyword == KeywordKind.FLOAT:

            varName = inStr.expectIdentifier()
            inStr.expectSymbol('(')
            varVal = inStr.expectNumber(dSc)
            inStr.expectSymbol(')')

            dSc.numVariables[varName] = varVal
        
        # What if we have a sphere
        elif tryTok.keyword == KeywordKind.SPHERE:
            dSc.scene.add(inStr.parseSphereSH(dSc))

        # What if we have a plane
        elif tryTok.keyword == KeywordKind.PLANE:
            dSc.scene.add(inStr.parsePlaneSH(dSc))

        # What if we have a Box
        elif tryTok.keyword == KeywordKind.BOX:
            dSc.scene.add(inStr.parseBoxSH(dSc))

        # What if we have a triangle
        elif tryTok.keyword == KeywordKind.TRIANGLE:
            dSc.scene.add(inStr.parseTriangleSH(dSc))

        # What if we have a cylinder
        elif tryTok.keyword == KeywordKind.CYLINDER:
            dSc.scene.add(inStr.parseCylinderSH(dSc))

        # What if we have a triangular mesh
        elif tryTok.keyword == KeywordKind.TRIANGULARMESH:
            dSc.scene.add(inStr.parseMeshSH(dSc))
        
        # What if we have a camera
        elif tryTok.keyword == KeywordKind.CAMERA:

            # I want to have a limit in camera number
            if dSc.camera.isSome:
                let msg = "You can't define more than one camera. Error in: " & $inStr.location
                raise newException(GrammarError, msg)
            
            dSc.camera = some inStr.parseCamera(dSc)
        
        # What if we have a material
        elif tryTok.keyword == KeywordKind.MATERIAL:
            (varName, mat) = inStr.parseMaterial(dSc)
            dSc.materials[varName] = mat

    # We get here only when file ends
    return dSc
