type SourceLocation* = object
    filename*: string = ""
    line_num*: int = 0
    col_num*: int = 0

proc newSourceLocation*(name = "", line: int = 0, col: int = 0): SourceLocation {.inline.} = 
    # SourceLocation variable constructor
    SourceLocation(filename: name, line_num: line, col_num: col)


