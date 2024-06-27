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
#                InputStream test suite               #
#-----------------------------------------------------#
suite "Token":

    setup:
        var
            fname = "prova.txt"
            fstr = newFileStream(fname, fmRead)

            is1 = newInputStream(fstr, fname, 4)
    
    teardown:
        discard is1
        discard fname
        discard fstr

    
    test "newInputStream proc":
        # Checking InputStream variable constructor procedure

        check is1.location.filename == fname
        check is1.location.lineNum == 1
        check is1.location.colNum == 1

        check areClose(is1.tabs.float32, 4.0)
        
        check is1.saved_char == '\0'
        check not is1.saved_token.isSome 
        check is1.savedLocation.filename == is1.location.filename
        check is1.savedLocation.lineNum == is1.location.lineNum
        check is1.savedLocation.colNum == is1.location.colNum


    test "updateLocation proc":
        # Ckecking location update procedure
        var 
            ch1 = '\0'
            ch2 = '\n'
            ch3 = '\t'
            ch4 = 'a'

        # Null character, nothing should happen
        updateLocation(is1, ch1)
        check is1.location.colNum == 1
        check is1.location.lineNum == 1

        # Tab character, line should upgrade by one and col should be 1
        updateLocation(is1, ch2)
        check is1.location.colNum == 1
        check is1.location.lineNum == 2

        # Tab character, col should upgrade by 4
        updateLocation(is1, ch3)
        check is1.location.colNum == 5
        check is1.location.lineNum == 2

        # Typical usage
        updateLocation(is1, ch4)
        check is1.location.colNum == 6
        check is1.location.lineNum == 2