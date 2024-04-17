import common

type Transformation = ref object of RootObj
    mat*: array[4, array[4, float32]]
    inv_mat*: array[4, array[4, float32]]

type Translation = ref object of Transformation
type Scaling = ref object of Transformation
type Rotation = ref object of Transformation

proc `@`*(a: Transformation, b: Transformation): Transformation =
    ## Implement Transformation product
    for i in 0..<4: 
        for j in 0..<4:
            for k in 0..<4: 
                result.mat[i][j] += a.mat[i][k] * b.mat[k][j]
                result.inv_mat[i][j] += b.mat[i][k] * a.mat[k][j]

proc `@`*(a: Transformation, b: Vec4f): Vec4f =
    

proc newTransformation(mat, inv_mat: array[4, array[4, float32]]): Transformation = 
    result.mat = mat; result.inv_mat = inv_mat 

proc newScaling(vec: Vec3f): Scaling =
    quit "to overload"

method apply(T: Transformation, a: Vec4f): Vec4f {.base.} = T.mat @ a

var T1 = Scaling()
echo T1.apply(newVec4[float32](1.0, 12.0, 2.0, 1.0))