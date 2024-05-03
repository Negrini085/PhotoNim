import common, geometry
import std/math


type Transformation* = object of RootObj
    mat*: Mat4f
    inv_mat*: Mat4f

proc newTransformation*(mat, inv_mat: Mat4f): Transformation = 
    ## New transformation constructor
    (result.mat, result.inv_mat) = (mat, inv_mat)


type Translation* = object of Transformation
type Scaling* = object of Transformation
type Rotation* = object of Transformation

proc `@`*(a, b: Transformation): Transformation =
    ## Procedure to compose transformations
    result.mat = dot(a.mat, b.mat)
    result.inv_mat = dot(b.inv_mat, a.inv_mat)
    

proc `@`*(a: Transformation, b: Vec4f): Vec4f =
    ## Procedure to apply a transformation
    result = dot(a.mat, b)

proc `@`*(a: Transformation, b: Point3D): Point3D =
    ## Procedure to apply a transformation to a Point3D
    result = toPoint3D(dot(a.mat, toVec4(b)))

proc `@`*(a: Transformation, b: Vec3f): Vec3f =
    ## Procedure to apply a transformation to a Vec3f
    result = toVec3(dot(a.mat, toVec4(b)))


proc `*`*(T: Transformation, scal: float32): Transformation {.inline.} = newTransformation(scal * T.mat, scal * T.inv_mat)
proc `*`*(scal: float32, T: Transformation): Transformation {.inline.} = newTransformation(scal * T.mat, scal * T.inv_mat)
## Multiplication by a scalar procedure
proc `/`*(T: Transformation, scal: float32): Transformation {.inline.} = newTransformation(T.mat / scal, T.inv_mat / scal)
## Division by a scalar procedure


proc inverse*(T: Transformation): Transformation {.inline.} =
    ## Procedure to get the inverse Transformation
    result.mat = T.inv_mat; result.inv_mat = T.mat


proc is_consistent*(t1: Transformation): bool = 
    ## Checks whether the transformation is consistent or not: product within matrix and inverse gives identity??
    result = areClose(dot(t1.mat, t1.inv_mat), Mat4f.id)


proc newScaling*(scal: float32): Scaling =
    ## Procedure to define a new scaling transformation
    result.mat = scal * Mat4f.id; 
    result.inv_mat = Mat4f.id / scal
    result.mat[3][3] = 1.0
    result.inv_mat[3][3] = 1.0


proc newScaling*(vec: Vec4f): Scaling =
    ## Procedure to define a new scaling transformation
    result.mat = [
        [vec[0], 0, 0, 0], 
        [0, vec[1], 0, 0], 
        [0, 0, vec[2], 0], 
        [0, 0, 0, 1]
    ]
    result.inv_mat = [
        [1/vec[0], 0, 0, 0], 
        [0, 1/vec[1], 0, 0], 
        [0, 0, 1/vec[2], 0], 
        [0, 0, 0, 1]   
    ]


proc newTranslation*(v: Vec4f): Translation  = 
    ## Procedure to define a new scaling transformation
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


proc newRotX*(angle: float32): Rotation = 
    ## Procedure that creates a new rotation around x axis: angle is given in degrees
    var theta = degToRad(angle)
    let
        c = cos(theta)
        s = sin(theta)

    result.mat = [
        [1, 0, 0, 0], 
        [0, c, -s, 0], 
        [0, s, c, 0], 
        [0, 0, 0, 1]
    ]
    result.inv_mat = [
        [1, 0, 0, 0], 
        [0, c, s, 0], 
        [0, -s, c, 0], 
        [0, 0, 0, 1]
    ]


proc newRotY*(angle: float32): Rotation = 
    ## Procedure that creates a new rotation around y axis: angle is given in degrees
    var theta = degToRad(angle)
    let
        c = cos(theta)
        s = sin(theta)

    result.mat = [
        [c, 0, s, 0], 
        [0, 1, 0, 0], 
        [-s, 0, c, 0], 
        [0, 0, 0, 1]
    ]
    result.inv_mat = [
        [c, 0, -s, 0], 
        [0, 1, 0, 0], 
        [s, 0, c, 0], 
        [0, 0, 0, 1]
    ]


proc newRotZ*(angle: float32): Rotation = 
    ## Procedure that creates a new rotation around z axis: angle is given in degrees
    var theta = degToRad(angle)
    let
        c = cos(theta)
        s = sin(theta)

    result.mat = [
        [c, -s, 0, 0], 
        [s, c, 0, 0], 
        [0, 0, 1, 0], 
        [0, 0, 0, 1]
    ]
    result.inv_mat = [
        [c, s, 0, 0], 
        [-s, c, 0, 0], 
        [0, 0, 1, 0], 
        [0, 0, 0, 1]
    ]


proc id*(_: typedesc[Transformation]): Transformation {.inline} = 
    ## Procedure to have identity transformation
    result.mat = Mat4f.id; result.inv_mat = Mat4f.id


#-----------------------------------------------#
#                  Base methods                 #
#-----------------------------------------------#   
method apply*(T: Transformation, a: Vec4f): Vec4f {.base, inline.} = T @ a
    ## Method to apply a generic transformation

method apply*(T: Transformation, a: Point3D): Point3D {.base, inline.} = T @ a
    ## Method to apply a generic transformation to a Point3D

method apply*(T: Transformation, a: Vec3f): Vec3f {.base, inline.} = T @ a
    ## Method to apply a generic transformation to a Vec3f



#-----------------------------------------------#
#                Scaling methods                #
#-----------------------------------------------#
method apply*(T: Scaling, a: Vec4f): Vec4f {.inline.} = 
    ## Method to perform scaling on a Vec4f
    result = newVec4[float32](T.mat[0][0] * a[0], T.mat[1][1] * a[1], T.mat[2][2] * a[2], a[3])

method apply*(T: Scaling, a: Point3D): Point3D {.inline.} = 
    ## Method to perform scaling on a Point3D
    result = newPoint3D(T.mat[0][0] * a.x, T.mat[1][1] * a.y, T.mat[2][2] * a.z)

method apply*(T: Scaling, a: Vec3f): Vec3f {.inline.} = 
    ## Method to perform scaling on a Vec3f
    result = newVec3[float32](T.mat[0][0] * a[0], T.mat[1][1] * a[1], T.mat[2][2] * a[2])



#-----------------------------------------------#
#             Translation methods               #
#-----------------------------------------------#
method apply*(T: Translation, a: Vec4f): Vec4f =
    ## Method to apply a translation transformation
    result[0] = a[0] + T.mat[0][3] * a[3]; result[1] = a[1] + T.mat[1][3] * a[3]; 
    result[2] = a[2] + T.mat[2][3] * a[3]; result[3] = a[3];

method apply*(T: Translation, a: Point3D): Point3D {.inline.} =
    ## Method to apply a translation transformation to a Point3D element
    result = newPoint3D(a.x + T.mat[0][3], a.y + T.mat[1][3], a.z + T.mat[2][3])

