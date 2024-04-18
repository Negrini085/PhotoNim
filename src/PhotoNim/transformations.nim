import common

type Transformation* = object of RootObj
    mat*: Mat4f
    inv_mat*: Mat4f

proc newTransformation*(mat, inv_mat: Mat4f): Transformation = 
    (result.mat, result.inv_mat) = (mat, inv_mat)

type Translation = object of Transformation
type Scaling = object of Transformation
type Rotation = object of Transformation

proc `@`*(a, b: Transformation): Transformation =
    ## Procedure to compose transformations
    result.mat = dot(a.mat, b.mat)
    result.inv_mat = dot(b.inv_mat, a.inv_mat)
    
proc `@`*(a: Transformation, b: Vec4f): Vec4f =
    ## Procedure to apply a transformation
    result = dot(a.mat, b)

proc `*`*(T: Transformation, scal: float32): Transformation {.inline.} = newTransformation(scal * T.mat, scal * T.inv_mat)
proc `*`*(scal: float32, T: Transformation): Transformation {.inline.} = newTransformation(scal * T.mat, scal * T.inv_mat)
proc `/`*(T: Transformation, scal: float32): Transformation {.inline.} = newTransformation(T.mat / scal, T.inv_mat / scal)

proc newScaling(scal: float32): Scaling =
    result.mat = scal * Mat4f.id; 
    result.inv_mat = Mat4f.id / scal
    result.mat[3][3] = 1.0
    result.inv_mat[3][3] = 1.0

proc newTranslation*(v: Vec4f): Translation  = 
    result.mat = [
        [1, 0, 0, v[0]], 
        [0, 1, 0, v[1]], 
        [0, 0, 1, v[2]], 
        [0, 0, 0, 1   ]
    ]
    result.inv_mat = [
        [1, 0, 0, -v[0]], 
        [0, 1, 0, -v[1]], 
        [0, 0, 1, -v[2]], 
        [0, 0, 0, 1    ]   
    ]

method apply(T: Transformation, a: Vec4f): Vec4f {.base, inline.} = T @ a
method apply(T: Scaling, a: Vec4f): Vec4f {.inline.} = 
    quit "to overload"

