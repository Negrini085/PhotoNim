import std/unittest
from math import sqrt, cos, sin, PI
from std/sequtils import toSeq
import ../src/[geometry, hdrimage, pcg]


  
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

        let e = newVec3f(1.0, 2.0, 3.0)
        check e.N == 3 and e.V is float32

        let f = newVec4(-1, -4, 5, 2)
        check f.N == 4 and f.V is int

        let g = newVec2f(1, 2)
        check areClose(g, newVec2f(1, 2))

        let h = newVec3f(1, 2, 3)
        check areClose(h, newVec3f(1, 2, 3))

        let i = newVec4f(1, 2, 3, 4)
        check areClose(i, newVec4f(1, 2, 3, 4))


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

    test "`==` proc": 
        check BLACK.Vec3f == [float32 0, 0, 0]
        check WHITE.Vec3f == [float32 1, 1, 1]
        check RED.Vec3f == [float32 1, 0, 0]
        check GREEN.Vec3f == [float32 0, 1, 0]
        check BLUE.Vec3f == [float32 0, 0, 1]


    test "`+` proc":
        let result = x + y
        check result[0] == 4.0 and result[1] == 6.0

    test "`-` proc":
        let result = x - y
        check result[0] == -2.0 and result[1] == -2.0

    test "`-` unary proc":
        let result = -y
        check result[0] == -3.0 and result[1] == -4.0

    test "`*` proc":
        let result1 = 2.0 * x
        let result2 = x * 2.0
        check result1 == result2
        check result1[0] == 2.0 and result1[1] == 4.0

    test "`/` proc":
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
        check dot(x, y) == 11.0

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
    


suite "Points unittest":
    echo "Testing the `Point2D` and `Point3D` type and its procedures."

    setup:
        let 
            p2 = newPoint2D(1.0, 20.0)
            p3 = newPoint3D(-2.5, 1.0, 20.0)

    teardown:
        discard p2; discard p3

    test "xyz access proc":
        check p2.u == 1.0 and p2.v == 20.0
        
    test "toPoint3D proc":
        check p3.Vec3f is Vec3f
        check newVec3f(0.01, 0.02, 0.03).toPoint3D is Point3D

    test "`$` proc":
        check $p2 == "(1.0, 20.0)"
    
    # test "min proc":
    #     var
    #         a = newPoint3D(1, 2, 3)
    #         b = newPoint3D(-1, 2, 5)
    #         c = newPoint3D(1, -2, 4)
            
    #         s1 = @[a]
    #         s2 = @[a, b, c]

    #     check areClose(min(s1), newPoint3D(1, 2, 3))
    #     check areClose(min(s2), newPoint3D(-1, -2, 3))
    
    # test "max proc":
    #     var
    #         a = newPoint3D(1, 2, 3)
    #         b = newPoint3D(-1, 2, 5)
    #         c = newPoint3D(1, -2, 4)
            
    #         s1 = @[a]
    #         s2 = @[a, b, c]

    #     check areClose(max(s1), newPoint3D(1, 2, 3))
    #     check areClose(max(s2), newPoint3D(1, 2, 5))



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
        check x[0] == [1.0, 2.0]

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
        echo "to implement doc proc"


    test "T proc":
        var mat: Mat3f = newMat3([float32 1, 2, 3], [float32 4, 5, 6], [float32 7, 8, 9])

        check [[float32 1.0, 2.0, 3.0]].Tv is Vec3f
        check [float32 1.0, 2.0, 3.0].T is Mat[1, 3, float32]

        mat = mat.T
        check areClose(mat[0], newVec3f(1, 4, 7))
        check areClose(mat[1], newVec3f(2, 5, 8))
        check areClose(mat[2], newVec3f(3, 6, 9))
    



suite "Transformation unittest":
    echo "Testing the `Transformation` types and their methods and procs."

    setup:
        let
            mat: Mat4f = [[1.0, 0.0, 0.0, 4.0], [0.0, 1.0, 0.0, 3.0], [0.0, 0.0, 1.0, -1.0], [0.0, 0.0, 0.0, 1.0]]
            inv_mat: Mat4f = [[1.0, 0.0, 0.0, -4.0], [0.0, 1.0, 0.0, -3.0], [0.0, 0.0, 1.0, 1.0], [0.0, 0.0, 0.0, 1.0]]
        var t1 = newTransformation(mat, inv_mat)

    teardown:
        discard mat; discard inv_mat; discard t1

    test "newTransformation proc":
        let t2 = newTransformation(inv_mat, mat)
        check areClose(t2.mat, inv_mat)
        check areClose(t2.inv_mat, mat)
        
    test "inverse proc":
        let t2 = t1.inverse()
        check areClose(t2.mat, t1.inv_mat)
        check areClose(t2.inv_mat, t1.mat)


    test "`*` proc":
        let 
            scal: float32 = 2.0
            t2 = scal * t1
            t3 = t1 * scal

        check areClose(t2.mat, mat * scal)
        check areClose(t2.inv_mat, inv_mat / scal)
        check areClose(t3.mat, mat * scal)
        check areClose(t3.inv_mat, inv_mat / scal)

    test "`/` proc":
        let 
            scal: float32 = 2.0
            t2 = t1 / scal

        check areClose(t2.mat, mat / scal)
        check areClose(t2.inv_mat, inv_mat * scal)


    test "apply on Vec4f":
        var
            vec: Vec4f = newVec4f(1, 2, 3, 0)
            point: Vec4f = newVec4f(1, 2, 3, 1)

        # In order to test general methods we are using translation matrices: that means that
        # transformation acts different depending on the last vector component
            
        check areClose(apply(t1, vec), vec)
        check areClose(apply(t1, point), newVec4f(5, 5, 2, 1))


    test "apply on Point3D":
        var
            p1 = ORIGIN3D
            p2 = newPoint3D(1, 2, 3) 
        
        check areClose(apply(t1, p1), newPoint3D(4, 3, -1))
        check areClose(apply(t1, p2), newPoint3D(5, 5, 2))
    

    test "apply on Vec3f":
        var
            p1 = newVec3f(0, 0, 0)
            p2 = newVec3f(1, 2, 3) 

        # Testing apply procedure
        check areClose(apply(t1, p1), newVec3f(0, 0, 0))
        check areClose(apply(t1, p2), newVec3f(1, 2, 3))
    

    test "apply on Normal":
        var
            n2 = newNormal(1, 0, 0)
            n3 = newNormal(0, 3/5, 4/5)
            m1: Mat4f = [[1, 0, 0, 0], [0, 4/5, -3/5, 0], [0, 3/5, 4/5, 0], [0, 0, 0, 1]]
            m2: Mat4f = [[1, 0, 0, 0], [0, 4/5, 3/5, 0], [0, -3/5, 4/5, 0], [0, 0, 0, 1]]
            t: Transformation = newTransformation(m1, m2)

        check areClose(apply(t1, n2), newNormal(1, 0, 0))
        check areClose(apply(t, n3), newNormal(0, 0, 1))



suite "Derived Transformation test":
    echo "Testing the `Scaling`, `Translation`, `Rotation` types and their methods."

    setup:
        var
            t1 = newScaling(2.0)
            t2 = newScaling(newVec3f(1, 2, 3))
            t3 = newTranslation(newVec3f(2, 4, 1))

    teardown:
        discard t1; discard t2; discard t3
    
    test "Scaling of Vec4f":
        # Checking scaling of a Vec4f object
        let vec = newVec4f(1, 2, 3, 1)

        check areClose(apply(t1, vec), newVec4f(2, 4, 6, 1))
        check areClose(apply(t2, vec), newVec4f(1, 4, 9, 1))
    

    test "Scaling of Point3D":
        # Checking scaling of a Point3D object
        var p = newPoint3D(0, 3, 1)
        
        # Checking omogeneous scaling
        check areClose(apply(t1, p), newPoint3D(0, 6, 2))

        # Checking arbitrary scaling
        check areClose(apply(t2, p), newPoint3D(0, 6, 3))
    

    test "Scaling of Vec3f":
        # Checking scaling of a Point3D object
        var p = newVec3f(0, 3, 1)
        
        # Checking omogeneous scaling
        check areClose(apply(t1, p), newVec3f(0, 6, 2))

        # Checking arbitrary scaling
        check areClose(apply(t2, p), newVec3f(0, 6, 3))


    test "Translation of Vec3f":
        var 
            v1 = newVec3f(0, 0, 0)
            v2 = newVec3f(0, 3, 1)

        # Checking apply procedure
        check areClose(apply(t3, v1), newVec3f(0, 0, 0))
        check areClose(apply(t3, v2), newVec3f(0, 3, 1))


    test "Translation of Vec4f":
        var
            vec: Vec4f = newVec4f(1, 2, 3, 0)
            vec1: Vec4f = newVec4f(1, 2, 3, 1)

        # Checking apply procedure
        check areClose(apply(t3, vec), vec)
        check areClose(apply(t3, vec1), newVec4f(3, 6, 4, 1))
    

    test "Translation of Point3D":
        var 
            p1 = ORIGIN3D
            p2 = newPoint3D(0, 3, 1)

        # Checking apply procedure
        check areClose(apply(t3, p1), newPoint3D(2, 4, 1))
        check areClose(apply(t3, p2), newPoint3D(2, 7, 2))
    

    test "Translation of Normal":
        var 
            n1 = newNormal(1, 2, 3)

        # Checking apply procedure
        check areClose(apply(t3, n1), newNormal(1, 2, 3))


    test "Rotation of Vec4f":
        var
            tx = newRotX(180) 
            ty = newRotY(180) 
            tz = newRotZ(180) 
            vec = newVec4f(1, 2, 3, 0)
            vec1 = newVec4f(1, 2, 3, 1)

        check areClose(apply(tx, vec), newVec4f(1, -2, -3, 0), 1e-6)
        check areClose(apply(ty, vec), newVec4f(-1, 2, -3, 0), 1e-6)
        check areClose(apply(tz, vec), newVec4f(-1, -2, 3, 0), 1e-6)
        
        check areClose(apply(tx, vec1), newVec4f(1, -2, -3, 1), 1e-6)
        check areClose(apply(ty, vec1), newVec4f(-1, 2, -3, 1), 1e-6)
        check areClose(apply(tz, vec1), newVec4f(-1, -2, 3, 1), 1e-6)
    
    
    test "Rotation of Point3D":
        var
            tx = newRotX(180) 
            ty = newRotY(180) 
            tz = newRotZ(180) 
            p = newPoint3D(1, 2, 3)
        
        check areClose(apply(tx, p), newPoint3D(1.0, -2.0, -3.0), 1e-6)
        check areClose(apply(ty, p), newPoint3D(-1.0, 2.0, -3.0), 1e-6)
        check areClose(apply(tz, p), newPoint3D(-1.0, -2.0, 3.0), 1e-6)



#-------------------------------------------#
#       Orthonormal basis test suite        #
#-------------------------------------------#
suite "OrthoNormal Basis":

    setup:
        var onb = newONB(newVec3f(sqrt(2.0), sqrt(2.0), 0).normalize, 
                          newVec3f(-sqrt(2.0), sqrt(2.0), 0).normalize,
                          newVec3f(0, 0, 1))
    
    teardown:
        discard onb
    
    test "newONB proc":
        var    
            colSeq = columns(stdONB).toSeq()
            (e1, e2, e3) = (colSeq[0], colSeq[1], colSeq[2])
            
        # Checkig newONB proc
        check areClose(e1, eX)
        check areClose(e2, eY)
        check areClose(e3, eZ)


        colSeq = columns(onb).toSeq()
        (e1, e2, e3) = (colSeq[0], colSeq[1], colSeq[2])   

        check areClose(e1, newVec3f(sqrt(2.0), sqrt(2.0), 0).normalize)
        check areClose(e2, newVec3f(-sqrt(2.0), sqrt(2.0), 0).normalize)
        check areClose(e3, eZ)
    

    test "ONB random testing":
        # Checking Duff et al. algorithm
        # We are gonna random test it, so we will check random normals as input
        var 
            pcg = newPCG()
            normal: Normal  
            colSeq: seq[Vec3f]
            e1, e2, e3: Vec3f


        for i in 0..<1000:
            normal = newNormal(pcg.rand, pcg.rand, pcg.rand).normalize
            onb = createONB(normal)
   
            colSeq = columns(onb).toSeq()
            (e1, e2, e3) = (colSeq[0], colSeq[1], colSeq[2])

            check areClose(e3, normal.toVec3)

            check areClose(dot(e1, e2), 0, eps = 1e-6)
            check areClose(dot(e2, e3), 0, eps = 1e-6)
            check areClose(dot(e3, e1), 0, eps = 1e-6)

            check areClose(e1.norm, 1, eps = 1e-6)
            check areClose(e2.norm, 1, eps = 1e-6)
            check areClose(e3.norm, 1, eps = 1e-6)


    test "getComponents proc":
        var 
            appo: array[3, float32]
            vec = newVec3f(1, 4, 3)

        appo = stdONB.getComponents(vec)
        check areClose(appo[0], vec[0])
        check areClose(appo[1], vec[1])
        check areClose(appo[2], vec[2])

        appo = onb.getComponents(vec)
        check areClose(appo[0], 5 * cos(PI/4), eps = 1e-6)
        check areClose(appo[1], 3 * sin(PI/4), eps = 1e-6)
        check areClose(appo[2], vec[2])
    

    test "getVector proc":
        var
            x = 1.0.float32
            y = 2.0.float32
            z = 1.5.float32
        
        check areClose(newVec3f(1, 2, 1.5), stdONB.getVector(newVec3f(x, y, z))) 
        check areClose(newVec3f(0, 2, 1.5), onb.getVector(newVec3f(sqrt(2.float32), sqrt(2.float32), z))) 

