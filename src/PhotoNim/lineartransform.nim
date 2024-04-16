import common
import std/math
import geometry

type
    ## Define a generic transformation type
    Transform*[N: static[int], T] = object 
        matrix*: array[N, T]
        inverse*: array[N, T]
    
    ## Defines transformations that we will use in order to change object position and orientation
    Transformation*[T] = Transform[16, T]
    Transformationf* = Transformation[float32]

## Template constructor for a Transformation[T] type
proc newTransform*[N, T](matr1, matr2: array[N, T]): Transform {.inline} =
    result.matrix = matr1; result.inverse = matr2 


#-----------------------------------------------#
#       Transformation template operations      #
#-----------------------------------------------#  

template ScalTranToTranOp(op: untyped) =
    ## Template for element-wise operations between a scalar and a transformation resulting in a new transformation.
    proc op*[N: static[int], T](a: T, b: Transform[N, T]): Transform[N, T] =
        for i in 0..<N: 
            result.matrix[i] = op(a, b.matrix[i])
            result.inverse[i] = op(a, b.inverse[i])

template TranScalToTranOp(op: untyped) =
    ## Template for element-wise operations between a transformation and a scalar resulting in a new transformation.
    proc op*[N: static[int], T](a: Transform[N, T], b: T): Transform[N, T] =
        for i in 0..<N: 
            result.matrix[i] = op(a.matrix[i], b)
            result.inverse[i] = op(a.inverse[i], b)

ScalTranToTranOp(`*`)
TranScalToTranOp(`*`)
TranScalToTranOp(`/`)



type
    Translation*{.borrow: `.`.} = distinct Transformationf

proc newTranslation*(mat1, mat2: array[16, float32]): Translation {.inline.} = 
    ## Creates a translation matrix with desired direct and inverse transformation
    result.matrix = mat1; result.inverse = mat2;

proc `*`*(a: Translation, b: float32): Translation {.borrow.}
proc `/`*(a: Translation, b: float32): Translation {.borrow.}
proc `*`*(a: float32, b: Translation): Translation {.borrow.}
