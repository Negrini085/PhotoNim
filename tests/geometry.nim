import std/unittest

from PhotoNim/geometry import 
    `+`, `-`, `*`, `/`, `+=`, `-=`, `*=`, `/=`, areClose,
    Vec, newVec, newVec2, newVec3, newVec4,
    Mat, newMat, newMat2, newMat3, newMat4,
    cross, dot, dot2, norm, norm2, dist2, normalize


suite "Vec unittest":
    echo "Testing the `Vec` type and its procedures."

    test "newVec proc":
        let a = newVec([3.0, 3.0])
        check a.N == 2 and a.V is float

        let b = newVec([float32 3.0, 3.0])
        check b.N == 2 and b.V is float32

        let c = newVec([1, 2, 5, -30])
        check c.N == 4 and c.V is int

        let d = newVec2(1.0, 2.0)
        check d.N == 2 and d.V is float

        let e = newVec3(float32 1.0, 2.0, 3.0)
        check e.N == 3 and e.V is float32

        let f = newVec4(-1, -4, 5, 2)
        check f.N == 4 and f.V is int


    setup:
        let 
            x = newVec2(1.0, 2.0)
            y = newVec2(3.0, 4.0)

    teardown:
        discard x; discard y
    
    test "`[]` access proc":
        check x[0] == 1.0 and x[1] == 2.0 and y[1] == 4.0

    test "`[]=` assign proc": 
        var a = newVec3(1.0, 2.0, 3.0)
        a[2] = -3.0
        check a[0] == 1.0 and a[1] == 2.0 and a[2] == -3.0


    test "`+` binary proc":
        let result = x + y
        check result[0] == 4.0 and result[1] == 6.0

    test "`-` binary proc":
        let result = x - y
        check result[0] == -2.0 and result[1] == -2.0

    test "`-` unary proc":
        let result = -y
        check result[0] == -3.0 and result[1] == -4.0

    test "`*` binary proc":
        let result1 = 2.0 * x
        let result2 = x * 2.0
        check result1 == result2
        check result1[0] == 2.0 and result1[1] == 4.0

    test "`/` binary proc":
        let result = y / 2.0
        check result[0] == 1.5 and result[1] == 2.0

    test "`+=` incr proc":
        var a = x
        a += y
        check a[0] == 4.0 and a[1] == 6.0

    test "`-=` incr proc":
        var a = x
        a -= y
        check a[0] == -2.0 and a[1] == -2.0

    test "`*=` incr proc":
        var a = x
        a *= 2.0
        check a[0] == 2.0 and a[1] == 4.0

    test "`/=` incr proc":
        var a = x
        a /= 2.0
        check a[0] == 0.5 and a[1] == 1.0


    test "cross proc":
        let a = newVec3(1.0, 2.0, 3.0)
        let b = newVec3(4.0, 5.0, 6.0)
        let c = cross(a, b)
        check c[0] == -3.0 and c[1] == 6.0 and c[2] == -3.0

    test "dot proc":
        check dot2(x, y) == 11.0

    test "norm proc":
        check x.norm2 == 5.0
        check y.norm == 5.0 

    test "dist proc":
        let b = newVec2(4.0, 6.0)
        check dist2(x, b) == 25.0

    test "normalize proc":
        let a = normalize(y)
        check a.norm == 1.0
        check areClose(a[0], 0.6) and areClose(a[1], 0.8)


suite "Mat unittest":
    echo "Testing the `Mat` type and its procedures."

    test "newMat proc":
        let a = newMat([[1.0, 20.0, 3.0], [1.02, 30.0, -1.0]])
        check a.M == 2 and a.N == 3 and a.V is float

        let b = newMat2([1, 2], [3, 4])
        check b.M == b.N and b.N == 2 and b.V is int

        let c = newMat3([1, 2, 3], [4, 5, 6], [7, 8, 9])
        check c.M == c.N and c.N == 3 and c.V is int

        let d = newMat4([float32 1, 2, 3, 4], [float32 5, 6, 7, 8], [float32 9, 10, 11, 12], [float32 13, 14, 15, 16])
        check d.M == d.N and d.N == 4 and d.V is float32

    setup:
        let
            x = newMat2([1.0, 2.0], [3.0, 4.0])
            y = newMat2([5.0, 6.0], [7.0, 8.0])

    teardown:
        discard x; discard y


    test "`[]` access proc":
        check x[0][0] == 1.0 and x[1][0] == 3.0 and y[1][1] == 8.0

    test "`[]=` assign proc": 
        var a = x
        a[0][0] = -1.0
        check a[0][0] == -1.0 and a[0][1] == 2.0

    test "`+` binary proc":
        let result = x + y
        check result[0][0] == 6.0 and result[1][1] == 12.0 

    test "`-` binary proc":
        let result = x - y
        check result[0][0] == -4.0 and result[1][1] == -4.0 

    test "`-` unary proc":
        let result = -x
        check result[0][1] == -2.0 and result[1][0] == -3.0 

    test "`*` binary proc":
        let a = 2.0 * x
        let b = x * 2.0
        check a == b and a[0][1] == 4.0 and b[1][1] == 8.0

    test "`/` binary proc":
        let result = y / 2.0
        check result[1][1] == 4.0 and result[0][1] == 3.0

    test "`+=` incr proc":
        var result = x
        result += y
        check result[0][0] == 6.0 and result[1][1] == 12.0 

    test "`-=` incr proc":
        var result = x
        result -= y
        check result[0][0] == -4.0 and result[1][1] == -4.0 

    test "`*=` incr proc":
        var result = x
        result *= 2.0
        check result[0][1] == 4.0 and result[1][1] == 8.0


    test "`/=` incr proc":
        var result = y
        result /= 4.0
        check result[1][1] == 2.0 and result[0][1] == 1.5


    test "dot proc":
        echo dot(x, y)