import color

type

    HdrImage* = object
        ## An HDR image
        width*, height*: int
        image*: seq[Color]



proc newHdrImage(width: int, height: int): HdrImage = 
    ## Contructor which creates a one dimensional array of colors, whose dimension is width * height
    result.width = width
    result.height = height
    
    ## Every pixel is initialized as black (pixel.r = 0.0, pixel.g = 0.0, pixel.b = 0.0)
    for i in 0..<width*height:
        result.image.add(newColor(0.0, 0.0, 0.0))


