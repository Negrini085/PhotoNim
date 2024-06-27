import std/[unittest, tables, options, streams]
import PhotoNim


#-----------------------------------------------------#
#             SourceLocation test suite               #
#-----------------------------------------------------#
suite "SourceLocation":

    setup:
        let
            sl1 = newSourceLocation()
            sl2 = newSourceLocation("prova.sc", 3, 5)
    
    teardown:
        discard sl1
        discard sl2
    

    test "newSourceLocation proc (default)":
        # Checking newSourceLocation default constructor

        check sl1.filename == ""
        check sl1.lineNum == 0
        check sl1.colNum == 0


    test "newSourceLocation proc":
        # Checking newSourceLocation constructor

        check sl2.filename == "prova.sc"
        check sl2.lineNum == 3
        check sl2.colNum == 5


    test "$ proc":
        # Checking printing procedure 
        
        var
            fn1 = ""
            fn2 = "prova.sc"
        
        check $sl1 == "File: " & fn1 & ", Line: 0, Column: 0"
        check $sl2 == "File: " & fn2 & ", Line: 3, Column: 5"


#-----------------------------------------------------#
#                   Token test suite                  #
#-----------------------------------------------------#
suite "Token":

    setup:
        let
            loc = newSourceLocation("prova.txt", 2, 4)

            key = newKeywordToken(loc, PERSPECTIVE)
            ide = newIdentifierToken(loc, "prova")
            lstr = newLiteralStringToken(loc, "abc")
            lnum = newLiteralNumberToken(loc, 2.3)
            sym = newSymbolToken(loc, SYMBOLS[3])
            stop = newStopToken(loc)

    teardown:
        discard loc
        discard key
        discard ide
        discard lstr
        discard lnum
        discard sym
        discard stop

    
    test "newToken procs":
        # Checking newToken procs

        # Keyword token
        check key.location.filename == "prova.txt"
        check key.location.lineNum == 2
        check key.location.colNum == 4
        check key.keyword == PERSPECTIVE

        # Identifier token
        check ide.location.filename == "prova.txt"
        check ide.location.lineNum == 2
        check ide.location.colNum == 4
        check ide.identifier == "prova"

        # Literal string token
        check lstr.location.filename == "prova.txt"
        check lstr.location.lineNum == 2
        check lstr.location.colNum == 4
        check lstr.str == "abc"

        # Literal number token
        check lnum.location.filename == "prova.txt"
        check lnum.location.lineNum == 2
        check lnum.location.colNum == 4
        check areClose(lnum.value, 2.3)

        # Symbol token
        check sym.location.filename == "prova.txt"
        check sym.location.lineNum == 2
        check sym.location.colNum == 4
        check sym.symbol == "]"

        # Stop token
        check stop.location.filename == "prova.txt"
        check stop.location.lineNum == 2
        check stop.location.colNum == 4
        check not stop.flag == true



#-----------------------------------------------------#
#               InputStream test suite                #
#-----------------------------------------------------#
suite "InputStream":

    setup:
        var
            fname = "files/inStr.txt"
            fstr = newFileStream(fname, fmRead)

            inStr = newInputStream(fstr, fname, 4)
    
    teardown:
        discard inStr
        discard fname
        discard fstr

    
    test "newInputStream proc":
        # Checking InputStream variable constructor procedure

        check inStr.location.filename == fname
        check inStr.location.lineNum == 1
        check inStr.location.colNum == 1

        check areClose(inStr.tabs.float32, 4.0)
        
        check inStr.saved_char == '\0'
        check not inStr.saved_token.isSome 
        check inStr.savedLocation.filename == inStr.location.filename
        check inStr.savedLocation.lineNum == inStr.location.lineNum
        check inStr.savedLocation.colNum == inStr.location.colNum


    test "updateLocation proc":
        # Ckecking location update procedure
        var 
            ch1 = '\0'
            ch2 = '\n'
            ch3 = '\t'
            ch4 = 'a'

        # Null character, nothing should happen
        updateLocation(inStr, ch1)
        check inStr.location.colNum == 1
        check inStr.location.lineNum == 1

        # Tab character, line should upgrade by one and col should be 1
        updateLocation(inStr, ch2)
        check inStr.location.colNum == 1
        check inStr.location.lineNum == 2

        # Tab character, col should upgrade by 4
        updateLocation(inStr, ch3)
        check inStr.location.colNum == 5
        check inStr.location.lineNum == 2

        # Typical usage
        updateLocation(inStr, ch4)
        check inStr.location.colNum == 6
        check inStr.location.lineNum == 2


    test "readChar proc":
        # Checking readChar procedure, useful to read a new character from input stream

        # Checking location and savedChar at the beginning of the reading procedure
        check inStr.location.colNum == 1
        check inStr.location.lineNum == 1
        check inStr.location.filename == fname

        check inStr.savedChar == '\0'
        check inStr.savedLocation.colNum == 1
        check inStr.savedLocation.lineNum == 1
        check inStr.savedLocation.filename == fname

        # First call of readChar, it should be a normal character so not a big deal 
        check readChar(inStr) == 'a'
        check inStr.location.colNum == 2
        check inStr.location.lineNum == 1
        check inStr.location.filename == fname

        check inStr.savedChar == '\0'
        check inStr.savedLocation.colNum == 1
        check inStr.savedLocation.lineNum == 1
        check inStr.savedLocation.filename == fname

        # Second call of readChar, it should be a whitespace
        check readChar(inStr) == ' '
        check inStr.location.colNum == 3
        check inStr.location.lineNum == 1
        check inStr.location.filename == fname

        check inStr.savedChar == '\0'
        check inStr.savedLocation.colNum == 2
        check inStr.savedLocation.lineNum == 1
        check inStr.savedLocation.filename == fname

        # Third call of readChar, it should be a normal character
        check readChar(inStr) == 'b'
        check inStr.location.colNum == 4
        check inStr.location.lineNum == 1
        check inStr.location.filename == fname

        check inStr.savedChar == '\0'
        check inStr.savedLocation.colNum == 3
        check inStr.savedLocation.lineNum == 1
        check inStr.savedLocation.filename == fname

        # Fourth call of readChar, it should be a whitespace 
        check readChar(inStr) == ' '
        check inStr.location.colNum == 5
        check inStr.location.lineNum == 1
        check inStr.location.filename == fname

        check inStr.savedChar == '\0'
        check inStr.savedLocation.colNum == 4
        check inStr.savedLocation.lineNum == 1
        check inStr.savedLocation.filename == fname

        # Fifth call of readChar, it should be a '\n'
        check readChar(inStr) == '\n'
        check inStr.location.colNum == 1
        check inStr.location.lineNum == 2
        check inStr.location.filename == fname

        check inStr.savedChar == '\0'
        check inStr.savedLocation.colNum == 5
        check inStr.savedLocation.lineNum == 1
        check inStr.savedLocation.filename == fname

        # Sixth call of readChar, it should be a normal character
        check readChar(inStr) == '4'
        check inStr.location.colNum == 2
        check inStr.location.lineNum == 2
        check inStr.location.filename == fname

        check inStr.savedChar == '\0'
        check inStr.savedLocation.colNum == 1
        check inStr.savedLocation.lineNum == 2
        check inStr.savedLocation.filename == fname

        # Seventh call of readChar, it should be a whitespace
        check readChar(inStr) == ' '
        check inStr.location.colNum == 3
        check inStr.location.lineNum == 2
        check inStr.location.filename == fname

        check inStr.savedChar == '\0'
        check inStr.savedLocation.colNum == 2
        check inStr.savedLocation.lineNum == 2
        check inStr.savedLocation.filename == fname

        # Eight call of readChar, it should be a normal character
        check readChar(inStr) == 'e'
        check inStr.location.colNum == 4
        check inStr.location.lineNum == 2
        check inStr.location.filename == fname

        check inStr.savedChar == '\0'
        check inStr.savedLocation.colNum == 3
        check inStr.savedLocation.lineNum == 2
        check inStr.savedLocation.filename == fname

        # Ninth call of readChar, it should be a normal character
        check readChar(inStr) == '\n'
        check inStr.location.colNum == 1
        check inStr.location.lineNum == 3
        check inStr.location.filename == fname

        check inStr.savedChar == '\0'
        check inStr.savedLocation.colNum == 4
        check inStr.savedLocation.lineNum == 2
        check inStr.savedLocation.filename == fname

    
    test "unreadChar proc":
        # Checking procedure to unread a character
        var ch: char

        # First reading by means of readChar
        check inStr.readChar() == 'a'
        check inStr.readChar() == ' '
        ch = inStr.readChar()
        
        # Checking everything is ok, character should be a 'b'
        check ch == 'b'
        check inStr.location.colNum == 4
        check inStr.location.lineNum == 1
        check inStr.location.filename == fname

        check inStr.savedChar == '\0'
        check inStr.savedLocation.colNum == 3
        check inStr.savedLocation.lineNum == 1
        check inStr.savedLocation.filename == fname

        # Now unreading it in order to restore stream status
        inStr.unreadChar(ch)
        check inStr.savedChar == 'b'
        check inStr.location.colNum == 3
        check inStr.location.lineNum == 1
        check inStr.location.filename == fname


    test "skipWhitespaceComments proc":
        # Checking procedure to skip whitespace and tabs, useful 
        # because we don't care about them 

        fname = "files/WCtest.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check inStr.readChar() == 'a'
        check inStr.readChar() == '\n'

        # Using skipWhitespaceComments for the first time
        # Here we shouldskip a comment line and should unread 'b'
        inStr.skipWhitespaceComments()
        
        check inStr.savedChar == 'b'
        check inStr.location.colNum == 1
        check inStr.location.lineNum == 3
        check inStr.location.filename == "files/WCtest.txt"

        # Remember, if we have an unread char readChar gives it 
        # as output
        check inStr.readChar() == 'b'
        inStr.savedChar = '\0'

        # Using skipWhitespaceComments for the second time, 
        # we now should have c as savedChar because we skipped tab 
        inStr.skipWhitespaceComments()

        check inStr.savedChar == 'c'
        check inStr.location.colNum == 5
        check inStr.location.lineNum == 3
        check inStr.location.filename == "files/WCtest.txt"

        check inStr.readChar() == 'c'
        inStr.savedChar = '\0'
        check inStr.readChar() == '\n'


    test "parseStringToken proc":
        # Checking parseStringToken proc, we want to read string
        var strToken: Token

        fname = "files/Token/parseST.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check inStr.readChar() == 'a'
        check inStr.readChar() == '\n'
        check inStr.readChar() == '"'

        strToken = inStr.parseStringToken(inStr.location)
        check strToken.kind == LiteralStringToken
        check strToken.str == "Literal string token parsing test"
        
        check strToken.location.colNum == 36
        check strToken.location.lineNum == 2
        check strToken.location.filename == fname
    

    test "parseNumberToken proc":
        # Checking parseNumberToken proc, we want to read a number
        var
            ch: char
            numToken: Token

        fname = "files/Token/parseF.txt"
        fstr = newFileStream(fname, fmRead)
        inStr = newInputStream(fstr, fname, 4)

        check inStr.readChar() == 'a'
        check inStr.readChar() == '\n'

        ch = inStr.readChar()
        check ch == '4'

        numToken = inStr.parseNumberToken(ch, inStr.location)
        check numToken.kind == LiteralNumberToken
        check areClose(numToken.value, 4.567)
        
        check numToken.location.colNum == 6
        check numToken.location.lineNum == 2
        check numToken.location.filename == fname
