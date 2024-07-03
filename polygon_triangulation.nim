from std/algorithm import reversed

type Point3D = tuple[x, y, z: float32]


proc orientation(vertices: seq[Point3D]): float32 =
	for i in 0..<vertices.len:
		let j = (i + 1) mod vertices.len
		result += 0.5 * (vertices[i].x * vertices[j].y - vertices[j].x * vertices[i].y)

proc isEar(vertices: seq[Point3D], i: int): bool =
	let
		(prevIdx, nextIdx) = ((i - 1 + vertices.len) mod vertices.len, (i + 1) mod vertices.len)
		(prev, curr, next) = (vertices[prevIdx], vertices[i], vertices[nextIdx])

	for point in vertices:
		if point != prev and point != curr and point != next:
			let
				(v00, v01) = (next.x - prev.x, next.y - prev.y)
				(v10, v11) = (curr.x - prev.x, curr.y - prev.y)
				(v20, v21) = (point.x - prev.x, point.y - prev.y)

				dot00 = v00 * v00 + v01 * v01
				dot01 = v00 * v10 + v01 * v11
				dot02 = v00 * v20 + v01 * v21
				dot11 = v10 * v10 + v11 * v11
				dot12 = v10 * v20 + v11 * v21

				invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
				u = (dot11 * dot02 - dot01 * dot12) * invDenom
				v = (dot00 * dot12 - dot01 * dot02) * invDenom

			if (u >= 0) and (v >= 0) and (u + v < 1): return false

	return true


proc triangulate(vertices: seq[Point3D]): seq[array[3, Point3D]] =
	var poly = if vertices.orientation < 0: vertices.reversed else: vertices

	while poly.len > 3:
		for i in 0..<poly.len:
			if poly.isEar(i):
				let (prevIdx, nextIdx) = ((i - 1 + poly.len) mod poly.len, (i + 1) mod poly.len)
				result.add([poly[prevIdx], poly[i], poly[nextIdx]])
				poly.del(i)
				break

	result.add([poly[0], poly[1], poly[2]])


proc main() =
	# please note that this only works by assuming the z-component is 0
	let vertices = @[
		Point3D(x: 0, y: 0, z: 0),
		Point3D(x: 1, y: 0, z: 0),
		Point3D(x: 1, y: 1, z: 0),
		Point3D(x: 0, y: 1, z: 0)
	]

	let triangles = triangulate(vertices)
	for triangle in triangles:
		echo triangle

main()
