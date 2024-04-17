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
    quit "to overload"
    
proc `@`*(a: Transformation, b: Vec4f): Vec4f =
    quit "to overload"

proc `*`*(T: Transformation, scal: float32): Transformation {.inline.} = newTransformation(scal * T.mat, scal * T.inv_mat)
proc `*`*(scal: float32, T: Transformation): Transformation {.inline.} = newTransformation(scal * T.mat, scal * T.inv_mat)
proc `/`*(T: Transformation, scal: float32): Transformation {.inline.} = newTransformation(T.mat / scal, T.inv_mat / scal)

proc newScaling(vec: Vec3f): Scaling =
    quit "to overload"

method apply(T: Transformation, a: Vec4f): Vec4f {.base, inline.} = T @ a
method apply(T: Scaling, a: Vec4f): Vec4f {.inline.} = 
    quit "to overload"

var T1 = Scaling()
echo T1.apply(newVec4[float32](1.0, 12.0, 2.0, 1.0))