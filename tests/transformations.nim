import std/[unittest, math]
import PhotoNim/[transformations, common, geometry]

#----------------------------------#
#     Transformation type test     #
#----------------------------------#
suite "Transformation tests":

    setup:
        var
            mat: Mat4f = [[1, 0, 0, 4], [0, 1, 0, 3], [0, 0, 1, -1], [0, 0, 0, 1]]
            inv_mat: Mat4f = [[1, 0, 0, -4], [0, 1, 0, -3], [0, 0, 1, 1], [0, 0, 0, 1]]
            t1: Transformation = newTransformation(mat, inv_mat)

    test "Transformation constructor and consistency tests":
        var t2: Transformation = newTransformation(inv_mat, mat)

        # Cheking consistency and constructor
        check is_consistent(t2)
        check areClose(t2.mat, inv_mat)
        check areClose(t2.inv_mat, mat)

        # Checking inverse method
        t2 = t2.inverse()
        check areClose(t2.mat, mat)
        check areClose(t2.inv_mat, inv_mat)

    test "Transformation product test":
        var t2, ris: Transformation
        
        # Are transformations consistent?
        t2 = newTransformation(inv_mat, mat)
        check t1.is_consistent() and t2.is_consistent()

        # Checking transformation matrix and inverse matrix
        check areClose(t1.mat, mat) and areClose(t1.inv_mat, inv_mat)
        check areClose(t2.mat, inv_mat) and areClose(t2.inv_mat, mat)

        # Checking Transformation product: we are composing inverse transformation
        # The result will be the identity transformation
        ris = t1 @ t2
        check areClose(ris.mat, Mat4f.id)
        check areClose(ris.inv_mat, Mat4f.id)
        

    test "Transformation on Vec4f":
        var
            vec: Vec4f = newVec4[float32](1, 2, 3, 0)
            point: Vec4f = newVec4[float32](1, 2, 3, 1)

        # In order to test general methods we are using translation matrices: that means that
        # transformation acts different depending on the last vector component
            
        check areClose(t1 @ vec, vec)
        check areClose(t1 @ point, newVec4[float32](5, 5, 2, 1))

        check areClose(t1.apply(vec), vec)
        check areClose(t1.apply(point), newVec4[float32](5, 5, 2, 1))
    

    test "Transformation on Point3D":
        var
            p1 = newPoint3D(0, 0, 0)
            p2 = newPoint3D(1, 2, 3) 
        
        # Testing @ overloading
        check  areClose(t1 @ p1, newPoint3D(4, 3, -1))
        check  areClose(t1 @ p2, newPoint3D(5, 5, 2))

        # Testing apply procedure
        check  areClose(apply(t1, p1), newPoint3D(4, 3, -1))
        check  areClose(apply(t1, p2), newPoint3D(5, 5, 2))
    

    test "Transformaion on Vec3f":
        var
            p1 = newVec3[float32](0, 0, 0)
            p2 = newVec3[float32](1, 2, 3) 

        # Testing @ overloading    
        check  areClose(t1 @ p1, newVec3[float32](0, 0, 0))
        check  areClose(t1 @ p2, newVec3[float32](1, 2, 3))

        # Testing apply procedure
        check  areClose(t1 @ p1, newVec3[float32](0, 0, 0))
        check  areClose(t1 @ p2, newVec3[float32](1, 2, 3))
    

    test "Transformaion on Normal":
        var
            n1 = newNormal(0, 0, 0)
            n2 = newNormal(1, 0, 0)
            n3 = newNormal(0, 3/5, 4/5)
            m1: Mat4f = [[1, 0, 0, 0], [0, 4/5, -3/5, 0], [0, 3/5, 4/5, 0], [0, 0, 0, 1]]
            m2: Mat4f = [[1, 0, 0, 0], [0, 4/5, 3/5, 0], [0, -3/5, 4/5, 0], [0, 0, 0, 1]]
            t: Transformation = newTransformation(m1, m2)

        check  areClose(apply(t1, n1), newNormal(0, 0, 0))
        check  areClose(apply(t1, n2), newNormal(1, 0, 0))
        check  areClose(apply(t, n3), newNormal(0, 0, 1))


    test "Transformation mult/div by scalar":
        var
            scal: float32 = 2.0
            m1: Mat4f = [[2, 0, 0, 8], [0, 2, 0, 6], [0, 0, 2, -2], [0, 0, 0, 2]]
            m2: Mat4f = [[2, 0, 0, -8], [0, 2, 0, -6], [0, 0, 2, 2], [0, 0, 0, 2]]
        
        t1 = scal * t1;
        check areClose(t1.mat, m1)
        check areClose(t1.inv_mat, m2)

        t1 = t1/scal
        check areClose(t1.mat, mat)
        check areClose(t1.inv_mat, inv_mat)

        t1 = t1 * scal
        check areClose(t1.mat, m1)
        check areClose(t1.inv_mat, m2)


suite "Derived Transformation test":

    setup:
        var
            t1: Scaling = newScaling(2)
            t2: Scaling = newScaling(newVec3[float32](1, 2, 3))
            t3: Translation = newTranslation(newVec4[float32](2, 4, 1, 0))


    test "Scaling of Vec4f":
        # Checking scaling of a Vec4f object
        var vec: Vec4f = newVec4[float32](1, 2, 3, 1)
        
        check t1.is_consistent()
        check areClose(t1 @ vec, newVec4[float32](2, 4, 6, 1))
        check areClose(t1.apply(vec), newVec4[float32](2, 4, 6, 1))

        check t2.is_consistent()
        check areClose(t2 @ vec, newVec4[float32](1, 4, 9, 1))
        check areClose(t2.apply(vec), newVec4[float32](1, 4, 9, 1))
    

    test "Scaling of Point3D":
        # Checking scaling of a Point3D object
        var p = newPoint3D(0, 3, 1)
        
        # Checking omogeneous scaling
        check t1.is_consistent()
        check areClose(t1 @ p, newPoint3D(0, 6, 2))
        check areClose(t1.apply(p), newPoint3D(0, 6, 2))

        # Checking arbitrary scaling
        check t2.is_consistent()
        check areClose(t2 @ p, newPoint3D(0, 6, 3))
        check areClose(t2.apply(p), newPoint3D(0, 6, 3))
    

    test "Scaling of Vec3f":
        # Checking scaling of a Point3D object
        var p = newVec3[float32](0, 3, 1)
        
        # Checking omogeneous scaling
        check t1.is_consistent()
        check areClose(t1 @ p, newVec3[float32](0, 6, 2))
        check areClose(t1.apply(p), newVec3[float32](0, 6, 2))

        # Checking arbitrary scaling
        check t2.is_consistent()
        check areClose(t2 @ p, newVec3[float32](0, 6, 3))
        check areClose(t2.apply(p), newVec3[float32](0, 6, 3))


    test "Translation of Vec4f":
        var
            vec: Vec4f = newVec4[float32](1, 2, 3, 0)
            point: Vec4f = newVec4[float32](1, 0, 3, 1)
        
        check t3.is_consistent()

        # Checking @ operator
        check areClose(t3 @ vec, vec)
        check areClose(t3 @ point, newVec4[float32](3, 4, 4, 1))

        # Checking apply procedure
        check areClose(t3.apply(vec), vec)
        check areClose(t3.apply(point), newVec4[float32](3, 4, 4, 1))
    

    test "Translation of Point3D":
        var 
            p1 = newPoint3D(0, 0, 0)
            p2 = newPoint3D(0, 3, 1)
        
        check t3.is_consistent()

        # Checking @ operator
        check areClose(t3 @ p1, newPoint3D(2, 4, 1))
        check areClose(t3 @ p2, newPoint3D(2, 7, 2))

        # Checking apply procedure
        check areClose(t3.apply(p1), newPoint3D(2, 4, 1))
        check areClose(t3.apply(p2), newPoint3D(2, 7, 2))


    test "Rotation":
        var
            tx: Rotation = newRotX(180) 
            ty: Rotation = newRotY(180) 
            tz: Rotation = newRotZ(180) 
            vec: Vec4f = newVec4[float32](1, 2, 3, 1)
        
        check tx.is_consistent()
        check ty.is_consistent()
        check tz.is_consistent()

        #check areClose(tx @ vec, newVec4[float32](1.0, -2.0, -3.0, 1.0))
        #check areClose(ty @ vec, newVec4[float32](-1.0, 2.0, -3.0, 1.0))
        #check areClose(tz @ vec, newVec4[float32](-1.0, -2.0, 3.0, 1.0))