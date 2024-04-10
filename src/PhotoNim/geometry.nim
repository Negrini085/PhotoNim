import common
import std/[fenv, math]

## =================================================
## Point2D, Point3D and Normal Type
## =================================================

type
    Point2D {.borrow: `.`.} = distinct Vec2f
    Point3D {.borrow: `.`.} = distinct Vec3f
    Normal {.borrow: `.`.} = distinct Vec3f

proc newPoint2D*(x, y: float32): Point2D {.inline.} = 
    ## Create a new 2D point with the specified coordinates.
    result.data = [x, y]

proc newPoint3D*(x, y, z: float32): Point3D {.inline.} = 
    ## Create a new 3D point with the specified coordinates.
    result.data = [x, y, z]

proc newNormal*(x, y, z: float32): Normal {.inline.} = 
    ## Create a new normal vector with the specified components.
    result.data = [x, y, z]

proc x*(a: Point2D | Point3D | Normal): float32 {.inline.} = a.data[0]
proc y*(a: Point2D | Point3D | Normal): float32 {.inline.} = a.data[1]
proc z*(a: Point3D | Normal): float32 {.inline.} = a.data[2]

proc toVec*(a: Point2D): Vec2f {.inline.} = newVec2(a.x, a.y)
proc toVec*(a: Point3D | Normal): Vec3f {.inline.} = newVec3(a.x, a.y, a.z)

proc `$`*(a: Point2D): string {.borrow.}
proc `$`*(a: Point3D): string {.borrow.}
proc `$`*(a: Normal): string {.borrow.}

proc `==`*(a, b: Point2D): bool {.borrow.}
proc `==`*(a, b: Point3D): bool {.borrow.}
proc `==`*(a, b: Normal): bool {.borrow.}

proc areClose*(a, b: Point2D): bool {.borrow.}
    ## Check if two 2D points are close to each other within a small tolerance.

proc areClose*(a, b: Point3D): bool {.borrow.}
    ## Check if two 3D points are close to each other within a small tolerance.

proc areClose*(a, b: Normal): bool {.borrow.}
    ## Check if two normal vectors are close to each other within a small tolerance.

proc `-`*(a, b: Point2D): Point2D {.borrow.}
proc `-`*(a, b: Point3D): Point3D {.borrow.}

proc `-`*(a: Normal): Normal {.borrow.}
proc `*`*(a: Normal, b: float32): Normal {.borrow.}
proc `*`*(a: float32, b: Normal): Normal {.borrow.}

proc `+`*(a: Point2D, b: Vec2f): Point2D {.inline.} =
    ## Adds a 2D vector to a 2D point and returns a new 2D point.
    newPoint2D(a.x + b[0], a.y + b[1])

proc `+`*(a: Vec2f, b: Point2D): Point2D {.inline.} =
    ## Adds a 2D point to a 2D vector and returns a new 2D point.
    newPoint2D(a[0] + b.x, a[1] + b.y)

proc `+`*(a: Point3D, b: Vec3f): Point3D {.inline.} =
    ## Adds a 3D vector to a 3D point and returns a new 3D point.
    newPoint3D(a.x + b[0], a.y + b[1], a.z + b[2])

proc `+`*(a: Vec3f, b: Point3D): Point3D {.inline.} =
    ## Adds a 3D point to a 3D vector and returns a new 3D point.
    newPoint3D(a[0] + b.x, a[1] + b.y, a[2] + b.z)

proc `-`*(a: Point2D, b: Vec2f): Point2D {.inline.} =
    ## Subtracts a 2D vector from a 2D point and returns a new 2D point.
    newPoint2D(a.x - b[0], a.y - b[1])

proc `-`*(a: Vec2f, b: Point2D): Point2D {.inline.} =
    ## Subtracts a 2D point from a 2D vector and returns a new 2D point.
    newPoint2D(a[0] - b.x, a[1] - b.y)

proc `-`*(a: Point3D, b: Vec3f): Point3D {.inline.} =
    ## Subtracts a 3D vector from a 3D point and returns a new 3D point.
    newPoint3D(a.x - b[0], a.y - b[1], a.z - b[2])

proc `-`*(a: Vec3f, b: Point3D): Point3D {.inline.} =
    ## Subtracts a 3D point from a 3D vector and returns a new 3D point.
    newPoint3D(a[0] - b.x, a[1] - b.y, a[2] - b.z)


proc norm2*(a: Normal): float32 {.borrow.}
    ## Calculate the squared norm (length) of a normal vector.
    
proc norm*(a: Normal): float32 {.borrow.}
    ## Calculate the norm (length) of a normal vector.
    
proc normalize*(a: Normal): Normal {.borrow.}
    ## Normalize a normal vector.

proc dist2*(a, b: Point2D): float32 {.borrow.}
    ## Calculate the squared distance between two 2D points.
    
proc dist2*(a, b: Point3D): float32 {.borrow.}
    ## Calculate the squared distance between two 3D points.
    
proc dist*(a, b: Point2D): float32 {.borrow.}
    ## Calculate the distance between two 2D points.
    
proc dist*(a, b: Point3D): float32 {.borrow.}
    ## Calculate the distance between two 3D points.