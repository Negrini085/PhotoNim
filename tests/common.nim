import std/[unittest, math]
import PhotoNim/common


#--------------------------------------#
#           Vec type tests             #
#--------------------------------------#
suite "Vec-UnitTest":

    test "VecVecToVecOp":
        var 
            a2 = newVec2(1.0, 2.0)
            b2 = newVec2(3.0, 4.0)
            a3 = newVec3(1.0, 2.0, 3.0)
            b3 = newVec3(4.0, 5.0, 6.0)
            a4 = newVec4(1.0, 2.0, 3.0, 4.0)
            b4 = newVec4(5.0, 6.0, 7.0, 8.0)

        ## Addition
        var 
            resultAdd2 = a2 + b2
            resultAdd3 = a3 + b3
            resultAdd4 = a4 + b4
        check resultAdd2[0] == 4.0 and resultAdd2[1] == 6.0
        check resultAdd3[0] == 5.0 and resultAdd3[1] == 7.0 and resultAdd3[2] == 9.0
        check resultAdd4[0] == 6.0 and resultAdd4[1] == 8.0 and resultAdd4[2] == 10.0 and resultAdd4[3] == 12.0

        ## Subtraction
        var
            resultSub2 = a2 - b2
            resultSub3 = a3 - b3
            resultSub4 = a4 - b4
        check resultSub2[0] == -2.0 and resultSub2[1] == -2.0
        check resultSub3[0] == -3.0 and resultSub3[1] == -3.0 and resultSub3[2] == -3.0
        check resultSub4[0] == -4.0 and resultSub4[1] == -4.0 and resultSub4[2] == -4.0 and resultSub4[3] == -4.0

    test "ScalVecToVecOp and VecScalToVecOp":
        var 
            a2 = newVec2(1.0, 2.0)
            a3 = newVec3(1.0, 2.0, 3.0)
            a4 = newVec4(1.0, 2.0, 3.0, 4.0)
        var scalar: float = 2.0

        ## Multiplication (Scalar * Vector)
        var 
            resultMulScal2 = scalar * a2
            resultMulScal3 = scalar * a3
            resultMulScal4 = scalar * a4
        check resultMulScal2[0] == 2.0 and resultMulScal2[1] == 4.0
        check resultMulScal3[0] == 2.0 and resultMulScal3[1] == 4.0 and resultMulScal3[2] == 6.0
        check resultMulScal4[0] == 2.0 and resultMulScal4[1] == 4.0 and resultMulScal4[2] == 6.0 and resultMulScal4[3] == 8.0

        ## Multiplication (Vector * Scalar)
        var 
            resultMulVecScal2 = a2 * scalar
            resultMulVecScal3 = a3 * scalar
            resultMulVecScal4 = a4 * scalar
        check resultMulVecScal2[0] == 2.0 and resultMulVecScal2[1] == 4.0
        check resultMulVecScal3[0] == 2.0 and resultMulVecScal3[1] == 4.0 and resultMulVecScal3[2] == 6.0
        check resultMulVecScal4[0] == 2.0 and resultMulVecScal4[1] == 4.0 and resultMulVecScal4[2] == 6.0 and resultMulVecScal4[3] == 8.0

    test "VecToVecUnaryOp":
        var
            a4 = newVec4(1.0, -2.0, 3.0, -4.0)
            resultNegate = -a4
        check resultNegate[0] == -1.0
        check resultNegate[1] == 2.0
        check resultNegate[2] == -3.0
        check resultNegate[3] == 4.0

    test "VecVecIncrOp and VecScalIncrOp":
        var 
            a3 = newVec3(1.0, 2.0, 3.0)
            b3 = newVec3(4.0, 5.0, 6.0)
            scalar: float = 2.0

        ## Addition assignment
        a3 += b3
        check a3[0] == 5.0 and a3[1] == 7.0 and a3[2] == 9.0

        ## Subtraction assignment
        a3 -= b3
        check a3[0] == 1.0 and a3[1] == 2.0 and a3[2] == 3.0

        ## Multiplication assignment (Vector *= Scalar)
        a3 *= scalar
        check a3[0] == 2.0 and a3[1] == 4.0 and a3[2] == 6.0

        ## Division assignment (Vector /= Scalar)
        a3 /= scalar
        check a3[0] == 1.0 and a3[1] == 2.0 and a3[2] == 3.0

    test "VecVecToBoolOp":
        var 
            a3 = newVec3(1.0, 2.0, 3.0)
            b3 = newVec3(1.0, 2.0, 4.0)

        ## Equality comparison
        var isEqual = a3 == b3
        check isEqual == false



#--------------------------------------#
#           Mat type tests             #
#--------------------------------------#
suite "Vec-UnitTest":

    var
        m2x2: Mat2[float32] = [[1, 2], [0, 1]]
        m3x3: Mat3f = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
        m4x4: Mat4f = [[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12], [13, 14, 15, 16]]

    test "Constructor type":
        # Squared 2x2 matrix constructor test
        check areClose(m2x2[0][1], 2.0)
        check areClose(m2x2[1][1], 1.0)

        # Squared 3x3 matrix constructor test
        check areClose(m3x3[0][1], 2.0)
        check areClose(m3x3[1][1], 5.0)
        check areClose(m3x3[2][1], 8.0)

        # Squared 3x3 matrix constructor test
        check areClose(m4x4[0][1], 2.0)
        check areClose(m4x4[1][1], 6.0)
        check areClose(m4x4[2][3], 12.0)
        check areClose(m4x4[3][1], 14.0)
        
