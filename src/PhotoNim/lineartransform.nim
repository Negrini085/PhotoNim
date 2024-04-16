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

template TranTrantoTranOp(op: untyped) =
    ## Template for element-wise operations between a scalar and a transformation resulting in a new transformation.
    proc op*[N: static[int], T](a, b: Transform[N, T]): Transform[N, T] =
        for i in 0..<N: 
            result.matrix[i] = op(a.matrix[i], b.matrix[i])
            result.inverse[i] = op(a.inverse[i], b.inverse[i])

template TTtoTranOp(op: untyped) =
    var
        appo: array[2, float32] = [0, 0]
    ## Template for element-wise operations between a scalar and a transformation resulting in a new transformation.
    proc op*[T](a, b: Transformation[T]): Transformation[T] =
        for i in 0..<16: 
            for j in 0..<4:
                appo[0] += op(a.matrix[j + 4 * (i div 4)], b.matrix[4 * j + (i mod 4)])
                appo[1] += op(b.matrix[j + 4 * (i div 4)], a.matrix[4 * j + (i mod 4)])

            result.matrix[i] = appo[0]
            result.inverse[i] = appo[1]
            appo = [0, 0]

ScalTranToTranOp(`*`)
TranScalToTranOp(`*`)
TranScalToTranOp(`/`)

TranTranToTranOp(`+`)
TranTranToTranOp(`-`)
TTtoTranOp(`*`)





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

var
    mat1: array[16, float32]
    mat2: array[16, float32]

#for i in 0..<len(mat1):
#    mat1[i] = float32(i)
#    mat2[i] = float32(len(mat2) - i)

mat1 = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0 ,1, 0, 0, 0, 0, 1]
mat2 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]

var 
    prova: Translation = newTranslation(mat1, mat2)
    prova1: Translation = newTranslation(mat2, mat1)

prova = prova * prova1

echo prova.matrix
echo 3 div 4
