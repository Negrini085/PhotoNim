import common
import std/[fenv, math]

## =================================================
## Quat Type
## =================================================

type 
    Quat* {. borrow: `.`.} = distinct Vec4f

proc newQuat*(scal: float, vec: Vec3f): Quat {.inline} = 
    result.data = [scal, vec[0], vec[1], vec[2]]

proc newQuat*(r, i, j, k: float): Quat {.inline} = 
    result.data = [r, i, j, k]

proc r*(q: Quat): float {.inline} = q.data[0]
proc i*(q: Quat): float {.inline} = q.data[1]
proc j*(q: Quat): float {.inline} = q.data[2]
proc k*(q: Quat): float {.inline} = q.data[3]

proc scal*(q: Quat): float {.inline} = q.r
proc vec*(q: Quat): Vec3f {.inline} = newVec3(q.i, q.j, q.k)

proc `==`*(a, b: Quat): bool {.borrow.}
proc areClose*(a, b: Quat): bool {.borrow.}

proc `+`*(a, b: Quat): Quat {.borrow.}
proc `-`*(a, b: Quat): Quat {.borrow.}
proc `*`*(a: Quat, b: float): Quat {.borrow.}
proc `*`*(a: float, b: Quat): Quat {.borrow.}
proc `/`*(a: Quat, b: float): Quat {.borrow.}

proc norm*(a: Quat): float {.borrow}
proc conj*(a: Quat): Quat {.inline.} = newQuat(a.scal, -a.vec)
proc inv*(a: Quat): Quat {.inline.} = a.conj / a.norm

proc dot*(a, b: Quat): Quat {.inline.} =
    newQuat(
        a.j * b.k - a.k * b.j + a.i * b.r + a.r * b.i,
        a.k * b.i - a.i * b.k + a.j * b.r + a.r * b.j,
        a.i * b.j - a.j * b.i + a.k * b.r + a.r * b.k,
        a.r * b.r - a.i * b.i - a.j * b.j - a.k * b.k
    )

proc angle*(q: Quat): float {.inline.} = 2.0 * arccos(q.r)
proc rotateVec*(q: Quat, v: Vec3f): Vec3f {.inline.} = dot(q, dot(newQuat(0.0, v), q.inv)).vec

proc toMat4*(q: Quat): array[4, array[4, float]] =
    result[0][1] = -q.k
    result[0][2] = q.j
    result[1][2] = -q.i

    for j in 0..2:
        result[j][3] = q.data[j + 1]

    # Manually transpose the matrix
    var tmp: float
    for i in 0..3:
        for j in i + 1..3:
            tmp = result[i][j]
            result[i][j] = result[j][i]
            result[j][i] = tmp

    for i in 0..3:
        result[i][i] = q.r

proc toMat3*(q: Quat): array[3, array[3, float]] =
    let 
        sqx = q.i * q.i
        sqy = q.j * q.j
        sqz = q.k * q.k
        xy = q.i * q.j
        xz = q.i * q.k
        yz = q.j * q.k
        xw = q.i * q.r
        yw = q.j * q.r
        zw = q.k * q.r
    [
        [1 - 2 * sqy - 2 * sqz, 2 * xy - 2 * zw, 2 * xz + 2 * yw],
        [2 * xy + 2 * zw, 1 - 2 * sqx - 2 * sqz, 2 * yz - 2 * xw],
        [2 * xz - 2 * yw, 2 * yz + 2 * xw, 1 - 2 * sqx - 2 * sqy]
    ]

proc fromEulerAngles*(ang: Vec3f): Quat =
    let
        angles = ang / 2.0
        c1 = cos(angles[2])
        c2 = cos(angles[1])
        c3 = cos(angles[0])
        s1 = sin(angles[2])
        s2 = sin(angles[1])
        s3 = sin(angles[0])

    newQuat(
        c1 * c2 * s3 - s1 * s2 * c3,
        c1 * s2 * c3 + s1 * c2 * s3,
        s1 * c2 * c3 - c1 * s2 * s3,
        c1 * c2 * c3 + s1 * s2 * s3
    )

proc toEulerAngles*(q: Quat): Vec3f = 
    let 
        sqw = q.r * q.r
        sqx = q.i * q.i
        sqy = q.j * q.j
        sqz = q.k * q.k
      
    result[1] = arcsin(2.0 * (q.r * q.j - q.i * q.k))
    if 0.5 * PI - abs(result[1]) > epsilon(float):
        result[2] = arctan2(2.0 * (q.i * q.j + q.r * q.k), sqx - sqy - sqz + sqw)
        result[0] = arctan2(2.0 * (q.r * q.i + q.j * q.k), sqw - sqx - sqy + sqz)
    else:
        result[2] = arctan2(2.0 * q.j * q.k - 2 * q.i * q.r, 2 * q.i * q.k + 2 * q.j * q.r)
        result[0] = 0.0

    if result[1] < 0.0:
        result[2] = PI - result[2]