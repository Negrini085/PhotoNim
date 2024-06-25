import std/unittest
import ../src/lexer

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
    