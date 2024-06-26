import std/[unittest, tables]
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
        check sl1.line_num == 0
        check sl1.col_num == 0


    test "newSourceLocation proc":
        # Checking newSourceLocation constructor

        check sl2.filename == "prova.sc"
        check sl2.line_num == 3
        check sl2.col_num == 5


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
        check key.location.line_num == 2
        check key.location.col_num == 4
        check key.keyword == PERSPECTIVE

        # Identifier token
        check ide.location.filename == "prova.txt"
        check ide.location.line_num == 2
        check ide.location.col_num == 4
        check ide.identifier == "prova"

        # Literal string token
        check lstr.location.filename == "prova.txt"
        check lstr.location.line_num == 2
        check lstr.location.col_num == 4
        check lstr.str == "abc"

        # Literal number token
        check lnum.location.filename == "prova.txt"
        check lnum.location.line_num == 2
        check lnum.location.col_num == 4
        check areClose(lnum.value, 2.3)

        # Symbol token
        check sym.location.filename == "prova.txt"
        check sym.location.line_num == 2
        check sym.location.col_num == 4
        check sym.symbol == "]"

        # Stop token
        check stop.location.filename == "prova.txt"
        check stop.location.line_num == 2
        check stop.location.col_num == 4
        check not stop.flag == true