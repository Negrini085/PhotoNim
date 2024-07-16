import std/unittest
from math import sqrt, cos, sin, PI
import PhotoNim



#------------------------------------------#
#              Vec test suite              #
#------------------------------------------# 
suite "Vec":

    setup:
        let 
            x = newVec2(1.0, 2.0)
            y = newVec2(3.0, 4.0)

    teardown:
        discard x; discard y
    

    test "newVec proc":
        let d = newVec2(1.0, 2.0)
        check d.N == 2 and d[0] is float32

        let e = newVec3(1.0, 2.0, 3.0)
        check e.N == 3 and e[0] is float32

    test "`[]` access proc":
        check x[0] == 1.0 and x[1] == 2.0 and y[1] == 4.0

    test "`[]=` assign proc": 
        var a = newVec3(1.0, 2.0, 3.0)
        a[2] = -3.0
        check a[0] == 1.0 and a[1] == 2.0 and a[2] == -3.0

    test "`==` proc": 
        check BLACK.Vec3 == [float32 0, 0, 0]
        check WHITE.Vec3 == [float32 1, 1, 1]
        check RED.Vec3 == [float32 1, 0, 0]
        check GREEN.Vec3 == [float32 0, 1, 0]
        check BLUE.Vec3 == [float32 0, 0, 1]


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
        let 
            a = newPoint3D(1, 2, 0)
            b = newPoint3D(4.0, 6.0, 0.0)
        
        check areClose(dist2(a, b), 25.0)

    test "normalize proc":
        let a = normalize(y)
        check a.norm == 1.0
        check areClose(a[0], 0.6) and areClose(a[1], 0.8)
    


#---------------------------------------#
#           Point test suite            #
#---------------------------------------#
suite "Point":

    setup:
        let 
            p2 = newPoint2D(1.0, 20.0)
            p3 = newPoint3D(-2.5, 1.0, 20.0)

    teardown:
        discard p2; discard p3

    test "xyz access proc":
        check p2.u == 1.0 and p2.v == 20.0


suite "Transformations":

    setup:
        var
            t1 = newScaling(2.0)
            t2 = newScaling(1, 2, 3)
            t3 = newTranslation(newVec3(2, 4, 1))

    teardown:
        discard t1
        discard t2
        discard t3
    
    
    test "Scaling of Point3D":

        var p = newPoint3D(0, 3, 1)

        # Checking omogeneous and inomogenous scaling respectively
        check areClose(apply(t1, p), newPoint3D(0, 6, 2))
        check areClose(apply(t2, p), newPoint3D(0, 6, 3))
    

    test "Scaling of Vec3":

        var p = newVec3(0, 3, 1)
        
        # Checking omogeneous and inomogenous scaling respectively
        check areClose(apply(t1, p), newVec3(0, 6, 2))
        check areClose(apply(t2, p), newVec3(0, 6, 3))


    test "Scaling of Normal":

        var p = newNormal(0, 3, 1)
        
        # Checking omogeneous scaling
        check areClose(apply(t1, p), newNormal(0, 3, 1))

        # Checking arbitrary scaling
        check areClose(apply(t2, p), newNormal(0.0, 3/2, 1/3).normalize)


    test "Translation of Vec3":
        var 
            v1 = newVec3(0, 0, 0)
            v2 = newVec3(0, 3, 1)

        # Checking apply procedure
        check areClose(apply(t3, v1), newVec3(0, 0, 0))
        check areClose(apply(t3, v2), newVec3(0, 3, 1))


    test "Translation of Point3D":
        var 
            p1 = ORIGIN3D
            p2 = newPoint3D(0, 3, 1)

        # Checking apply procedure
        check areClose(apply(t3, p1), newPoint3D(2, 4, 1))
        check areClose(apply(t3, p2), newPoint3D(2, 7, 2))
    

    test "Translation of Normal":

        var n1 = newNormal(1, 2, 3)
        check areClose(apply(t3, n1), newNormal(1, 2, 3))
    
    
    test "Rotation of Point3D":
        var
            tx = newRotation(180, axisX) 
            ty = newRotation(180, axisY) 
            tz = newRotation(180, axisZ) 
            p = newPoint3D(1, 2, 3)
        
        check areClose(apply(tx, p), newPoint3D( 1.0,-2.0,-3.0), 1e-6)
        check areClose(apply(ty, p), newPoint3D(-1.0, 2.0,-3.0), 1e-6)
        check areClose(apply(tz, p), newPoint3D(-1.0,-2.0, 3.0), 1e-6)


    test "Rotation of Vec3":
        var
            tx = newRotation(180, axisX) 
            ty = newRotation(180, axisY) 
            tz = newRotation(180, axisZ) 
            vec = newVec3(1, 2, 3)
        
        check areClose(apply(tx, vec), newVec3( 1.0,-2.0,-3.0), 1e-6)
        check areClose(apply(ty, vec), newVec3(-1.0, 2.0,-3.0), 1e-6)
        check areClose(apply(tz, vec), newVec3(-1.0,-2.0, 3.0), 1e-6)


    test "Rotation of Normal":
        var
            tx = newRotation(90, axisX) 
            ty = newRotation(90, axisY) 
            tz = newRotation(90, axisZ) 
            norm = newNormal(1, 2, 3)

        check areClose(apply(tx, norm), newNormal(1.0, -3.0, 2.0), 1e-6)
        check areClose(apply(ty, norm), newNormal(3.0, 2.0, -1.0), 1e-6)
        check areClose(apply(tz, norm), newNormal(-2.0, 1.0, 3.0), 1e-6)

    
    test "@ composition operator":
        var
            rotx = newRotation(180, axisX) 
            comp: Transformation 

        comp = t1 @ t3 @ rotx

        check comp.kind == tkComposition
        check comp.transformations.len == 3

        check comp.transformations[0].kind == tkUniformScaling
        check areClose(comp.transformations[0].factor, t1.factor)

        check comp.transformations[1].kind == tkTranslation
        check areClose(comp.transformations[1].offset, t3.offset)

        check comp.transformations[2].kind == tkRotation
        check areClose(comp.transformations[2].cos, rotx.cos)
        check areClose(comp.transformations[2].sin, rotx.sin)


    test "newComposition proc":
        var
            rotx = newRotation(180, axisX) 
            comp: Transformation 
        
        comp = newComposition(@[t1, t3, rotx])

        check comp.kind == tkComposition
        check comp.transformations.len == 3

        check comp.transformations[0].kind == tkUniformScaling
        check areClose(comp.transformations[0].factor, t1.factor)

        check comp.transformations[1].kind == tkTranslation
        check areClose(comp.transformations[1].offset, t3.offset)

        check comp.transformations[2].kind == tkRotation
        check areClose(comp.transformations[2].cos, rotx.cos)
        check areClose(comp.transformations[2].sin, rotx.sin)

    
    test "Composition on Point3D":

        var
            rotx = newRotation(90, axisX)
            rotz = newRotation(90, axisZ)

            comp: Transformation
            p = newPoint3D(1, 2, 3)

        comp = rotx @ rotz
        check areClose(apply(comp, p), newPoint3D(-2, -3, 1), eps = 1e-6)

        comp = t3 @ rotx
        check areClose(apply(comp, p), newPoint3D(3, 1, 3), eps = 1e-6)

    
    test "Composition on Vec3":

        var
            rotx = newRotation(90, axisX)
            rotz = newRotation(90, axisZ)
            
            comp: Transformation
            vec = newVec3(1, 2, 3)

        comp = rotx @ rotz
        check areClose(apply(comp, vec), newVec3(-2, -3, 1), eps = 1e-6)

        comp = t3 @ rotx
        check areClose(apply(comp, vec), newVec3(1, -3, 2),eps = 1e-6)


    test "Composition on Normal":

        var
            sc = newScaling(1.0, 1/2, 1/3)
            rotx = newRotation(90, axisX)
            rotz = newRotation(90, axisZ)
            
            comp: Transformation
            norm = newNormal(1, 2, 3)

        comp = t2 @ sc
        check areClose(apply(comp, norm), newNormal(1, 2, 3), eps = 1e-6)

        comp = t3 @ rotx
        check areClose(apply(comp, norm), newNormal(1, -3, 2),eps = 1e-6)

        comp = rotz @ rotx
        check areClose(apply(comp, norm), newNormal(3, 1, 2),eps = 1e-6)




#-------------------------------------------#
#       Orthonormal basis test suite        #
#-------------------------------------------#
suite "OrthoNormal Basis":

    setup:
        var onb = newONB(newNormal(0, 0, 1))

    teardown:
        discard onb
        
    
    test "newONB proc":
        # Checking newONB proc
        check areClose(onb[0], eX)
        check areClose(onb[1], eY)
        check areClose(onb[2], eZ)
    

    test "ONB random testing":
        # Checking Duff et al. algorithm
        # We are gonna random test it, so we will check random normals as input
        var 
            randSet = newRandomSetUp(42, 1)
            pcg = newPCG(randSet)
            normal: Normal  


        for i in 0..<1000:
            normal = newNormal(pcg.rand, pcg.rand, pcg.rand).normalize
            onb = newONB(normal)

            check areClose(onb[2], normal.Vec3)

            check areClose(dot(onb[0], onb[1]), 0, eps = 1e-6)
            check areClose(dot(onb[1], onb[2]), 0, eps = 1e-6)
            check areClose(dot(onb[2], onb[0]), 0, eps = 1e-6)

            check areClose(onb[0].norm, 1, eps = 1e-6)
            check areClose(onb[1].norm, 1, eps = 1e-6)
            check areClose(onb[2].norm, 1, eps = 1e-6)