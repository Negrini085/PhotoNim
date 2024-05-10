from std/math import exp, pow 
import geometry, hdrimage, camera, shapes


type ImageTracer* = object
        image*: HdrImage
        camera*: Camera


#--------------------------------------------------#
#        Image Tracer procedure and methods        #
#--------------------------------------------------#

proc newImageTracer*(im: HdrImage, cam: Camera): ImageTracer {.inline.} = 
    ImageTracer(image: im, camera: cam)


proc fire_ray*(im_tr: ImageTracer, row, col: int, pixel: Point2D = newPoint2D(0.5, 0.5)): Ray =
    let u = (col.toFloat + pixel.u) / im_tr.image.width.toFloat
    let v = 1 - (row.toFloat + pixel.v) / im_tr.image.height.toFloat
    
    im_tr.camera.fire_ray(newPoint2D(u, v))

proc fire_all_rays*(im_tr: var ImageTracer) = 
    for row in 0..<im_tr.image.height:
        for col in 0..<im_tr.image.width:
            discard im_tr.fire_ray(row, col)
            let 
                    col1 = (1 - exp(-float32(col + row)))
                    col2 = row/im_tr.image.height
                    col3 = pow((1 - col/im_tr.image.width), 2.5)
            im_tr.image.setPixel(row, col, newColor(col1, col2, col3))

proc fire_all_rays*(im_tr: var ImageTracer, pix_col: proc, scenary: World) = 
    # Procedure to actually render an image: we will have to give as an input
    # a function that will enable us to set the color of a pixel
    for row in 0..<im_tr.image.height:
        for col in 0..<im_tr.image.width:
            im_tr.image.setPixel(row, col, pix_col(im_tr.fire_ray(row, col), scenary))