import common
import std/math
import geometry

const identity4x4: array[16, float32] = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0 ,1, 0, 0, 0, 0, 1]

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

template TranTrantoTranOp(op: untyped) =
    ## Template for element-wise operations between a scalar and a transformation resulting in a new transformation.
    proc op*[N: static[int], T](a, b: Transform[N, T]): Transform[N, T] =
        for i in 0..<N: 
            result.matrix[i] = op(a.matrix[i], b.matrix[i])
            result.inverse[i] = op(a.inverse[i], b.inverse[i])

template Matrix_prod4x4(op:untyped) =
    ## Template for 4x4 matrix product
    proc op*[T](a, b: array[16, T]): array[16, T] =
        var
            appo: float32 = 0.0

        for i in 0..<16: 
            for j in 0..<4:
                appo += op(a[j + 4 * (i div 4)], b[4 * j + (i mod 4)])

            result[i] = appo
            appo = 0.0

template M4x4_vecProd(op:untyped) =
    ## Template for 
    proc op*[T](a: array[16, T], b: Vec4[T]): Vec4[T] =
        var appo: float32 = 0.0

        for i in 0..<len(b.data): 
            for j in 0..<4:
                appo += op(a[j + 4 * i], b[j])

            result[i] = appo
            appo = 0.0
    

template TTtoTranOp(op: untyped) =
    ## Template for element-wise operations between a scalar and a transformation resulting in a new transformation.
    proc op*[T](a, b: Transformation[T]): Transformation[T] =       
            result.matrix= a.matrix * b.matrix
            result.inverse = b.inverse * a.inverse


template TranVecToVec(op: untyped) =
    ## Template for element wise operations between a transformation and a size 4 vector: gives a vector back
    proc op*[T](a: Transformation[T], b: Vec4[T]): Vec4[T] {.inline}=       
            result = a.matrix * b



ScalTranToTranOp(`*`)
TranScalToTranOp(`*`)
TranScalToTranOp(`/`)

TranTranToTranOp(`+`)
TranTranToTranOp(`-`)
Matrix_prod4x4(`*`)
M4x4_vecProd(`*`)

TTtoTranOp(`*`)
TranVecToVec(`*`)



#-----------------------------------------------#
#           Tranformation procedures            #
#-----------------------------------------------#

proc is_consistent*(t1: Transformation): bool = 
    ## Checks whether the transformation is consistent or not: product within matrix and inverse gives identity??
    result = areClose(t1.matrix * t1.inverse, identity4x4)

proc inverse_tranf(t1: Transform): Transform =
    ## Enables the user to access to the inverse transformation 
    result.matrix = t1.inverse
    result.inverse = t1.matrix


type
    Translation*{.borrow: `.`.} = distinct Transformationf

proc newTranslation*(mat1, mat2: array[16, float32]): Translation {.inline.} = 
    ## Creates a translation matrix with desired direct and inverse transformation
    result.matrix = mat1; result.inverse = mat2;

proc `*`*(a: Translation, b: float32): Translation {.borrow.}
proc `/`*(a: Translation, b: float32): Translation {.borrow.}
proc `*`*(a: float32, b: Translation): Translation {.borrow.}

proc `+`*(a, b: Translation): Translation {.borrow.}
proc `-`*(a, b: Translation): Translation {.borrow.}
proc `*`*(a, b: Translation): Translation {.borrow.}

proc `*`*(a: Translation, b: Vec4f): Vec4f {.inline} =
    result = a.matrix * b

proc is_consistent*(a: Translation): bool {.borrow.}
    ## Checks if a.matrix * a.inverse operation gives the identity matrix

proc inverse_tranf(t1: Translation): Translation {.borrow.}
    ## Enables the user to access to the inverse translation

