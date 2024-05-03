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

    test "Scaling":
        var
            t: Scaling = newScaling(2)
            vec: Vec4f = newVec4[float32](1, 2, 3, 1)
        
        check t.is_consistent()
        check areClose(t @ vec, newVec4[float32](2, 4, 6, 1))
        check areClose(t.apply(vec), newVec4[float32](2, 4, 6, 1))

        t = newScaling(vec)
        check t.is_consistent()
        check areClose(t @ vec, newVec4[float32](1, 4, 9, 1))
        check areClose(t.apply(vec), newVec4[float32](1, 4, 9, 1))

    test "Translation":
        var
            t: Translation = newTranslation(newVec4[float32](2, 4, 1, 0))
            vec: Vec4f = newVec4[float32](1, 2, 3, 0)
            point: Vec4f = newVec4[float32](1, 0, 3, 1)
        
        check t.is_consistent()

        check areClose(t @ vec, vec)
        check areClose(t @ point, newVec4[float32](3, 4, 4, 1))

        check areClose(t.apply(vec), vec)
        check areClose(t.apply(point), newVec4[float32](3, 4, 4, 1))

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