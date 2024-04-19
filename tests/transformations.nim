import std/[unittest, math]
import PhotoNim/[transformations, common]

#----------------------------------#
#     Transformation type test     #
#----------------------------------#
suite "Transformation tests":

    test "Transformation product test":
        var
            t1, t2, ris: Transformation
            mat: Mat4f = [[1, 0, 0, 4], [0, 1, 0, 3], [0, 0, 1, -1], [0, 0, 0, 1]]
            inv_mat: Mat4f = [[1, 0, 0, -4], [0, 1, 0, -3], [0, 0, 1, 1], [0, 0, 0, 1]]
        
        # Are transformations consistent?
        t1 = newTransformation(mat, inv_mat)
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
        
    test "Transformation application test"

