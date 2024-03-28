import common

type
    Point2D {.borrow: `.`.} = distinct Vec2f
    Point3D {.borrow: `.`.} = distinct Vec3f
    Normal {.borrow: `.`.} = distinct Vec3f

proc newPoint2D*(x, y: float32): Point2D {.inline.} = 
    result.data = [x, y]

proc newPoint3D*(x, y, z: float32): Point3D {.inline.} = 
    result.data = [x, y, z]

proc newNormal*(x, y, z: float32): Normal {.inline.} = 
    result.data = [x, y, z]

proc x*(a: Point2D | Point3D | Normal): float32 {.inline.} = a.data[0]
proc y*(a: Point2D | Point3D | Normal): float32 {.inline.} = a.data[1]
proc z*(a: Point3D | Normal): float32 {.inline.} = a.data[2]

proc toVec*(a: Point2D): Vec2f {.inline.} = newVec(a.x, a.y)
proc toVec*(a: Point3D | Normal): Vec3f {.inline.} = newVec(a.x, a.y, a.z)

proc `$`*(a: Point2D): string {.borrow.}
proc `$`*(a: Point3D): string {.borrow.}
proc `$`*(a: Normal): string {.borrow.}

proc `==`*(a, b: Point2D): bool {.borrow.}
proc `==`*(a, b: Point3D): bool {.borrow.}
proc `==`*(a, b: Normal): bool {.borrow.}

proc areClose*(a, b: Point2D): bool {.borrow.}
proc areClose*(a, b: Point3D): bool {.borrow.}
proc areClose*(a, b: Normal): bool {.borrow.}

proc `-`*(a, b: Point2D): Point2D {.borrow.}
proc `-`*(a, b: Point3D): Point3D {.borrow.}

proc `-`*(a: Normal): Normal {.borrow.}
proc `*`*(a: Normal, b: float32): Normal {.borrow.}
proc `*`*(a: float32, b: Normal): Normal {.borrow.}

proc `+`*(a: Point2D, b: Vec2f): Point2D {.inline.} = newPoint2D(a.x + b[0], a.y + b[1])
proc `+`*(a: Vec2f, b: Point2D): Point2D {.inline.} = newPoint2D(a[0] + b.x, a[1] + b.y)
proc `+`*(a: Point3D, b: Vec3f): Point3D {.inline.} = newPoint3D(a.x + b[0], a.y + b[1], a.z + b[2])
proc `+`*(a: Vec3f, b: Point3D): Point3D {.inline.} = newPoint3D(a[0] + b.x, a[1] + b.y, a[2] + b.z)

proc `-`*(a: Point2D, b: Vec2f): Point2D {.inline.} = newPoint2D(a.x - b[0], a.y - b[1])
proc `-`*(a: Vec2f, b: Point2D): Point2D {.inline.} = newPoint2D(a[0] - b.x, a[1] - b.y)
proc `-`*(a: Point3D, b: Vec3f): Point3D {.inline.} = newPoint3D(a.x - b[0], a.y - b[1], a.z - b[2])
proc `-`*(a: Vec3f, b: Point3D): Point3D {.inline.} = newPoint3D(a[0] - b.x, a[1] - b.y, a[2] - b.z)

proc norm2*(a: Normal): float32 {.borrow}
proc norm*(a: Normal): float32 {.borrow}
proc normalize*(a: Normal): Normal {.borrow}

proc dist2*(a, b: Point2D): float32 {.borrow}
proc dist2*(a, b: Point3D): float32 {.borrow}
proc dist*(a, b: Point2D): float32 {.borrow}
proc dist*(a, b: Point3D): float32 {.borrow}