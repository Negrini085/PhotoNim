import std/[unittest, math]
import PhotoNim/[transformations, common]

#----------------------------------#
#     Transformation type test     #
#----------------------------------#
suite "Transformation tests":
    var
            mat: Mat4f = [[1, 0, 0, 4], [0, 1, 0, 3], [0, 0, 1, -1], [0, 0, 0, 1]]
            inv_mat: Mat4f = [[1, 0, 0, -4], [0, 1, 0, -3], [0, 0, 1, 1], [0, 0, 0, 1]]
            t1: Transformation = newTransformation(mat, inv_mat)

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
        

    test "Transformation application test":
        var
            vec: Vec4f = newVec4[float32](1, 2, 3, 0)
            point: Vec4f = newVec4[float32](1, 2, 3, 1)
            ris: Vec4f

        # In order to test general methods we are using translation matrices: that means that
        # transformation acts different depending on the last vector component
            
        ris = t1 @ vec; point = t1 @ point
        check areClose(ris, vec)
        check areClose(point, newVec4[float32](5, 5, 2, 1))
    

    test "Transformation mult/div by scalar":
        var
            scal: float32 = 2.0
            m1: Mat4f = [[2, 0, 0, 8], [0, 2, 0, 6], [0, 0, 2, -2], [0, 0, 0, 2]]
            m2: Mat4f = [[2, 0, 0, -8], [0, 2, 0, -6], [0, 0, 2, 2], [0, 0, 0, 2]]
        
        t1 = 2 * t1;
        check areClose(t1.mat, m1)
        check areClose(t1.inv_mat, m2)

        t1 = t1/2
        check areClose(t1.mat, mat)
        check areClose(t1.inv_mat, inv_mat)

        t1 = t1 * 2
        check areClose(t1.mat, m1)
        check areClose(t1.inv_mat, m2)


        
        