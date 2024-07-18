# Changelog

All notable changes to this project will be documented in this file.

## [unreleased]

### 🚜 Refactor

- *(PhotoNim)* Final change
- *(PhotoNim)* Correct examples in .nimble file

### PhotoNim

- Add CLI help for rend command.

## [1.0.0] - 2024-07-18

### 🚀 Features

- *(Parser)* Add parseCSGUnionSH proc
- *(Parser)* Add parseHandlerSeq proc
- *(Parser)* Add parseEllipsoidSH proc
- *(csgUnion)* Add csgUnion handler kind and example
- *(CSGDiff)* Add parseCSGDiffSH proc & test
- *(CSGInt)* Add parseCSGIntSH proc & test
- *(CSGDiff)* Add CSGDiff example
- *(CSGDiff)* Add getAllHitPayloads proc & test
- *(inShape)* Addd csgDiff case of & test
- *(CSGDiff)* Add getHitPayload case of & test
- *(CSGDiff)* Add CSGDiff type, newCSGDiff proc & test
- *(CSGInt)* Add CSGInt example
- *(CSGInt)* Add CSGInt allHitPayload proc
- *(CSGInt)* Add CSGInt hitrecord proc
- *(CSGInt)* Add inShape proc case of
- *(CSG)* Add CSGInt type, constructor & test
- *(HitPayload)* Add getAllHitPayload proc
- *(Shape)* Add inAllShapes proc & test
- *(Shape)* Add inShape proc & test
- *(CSGUnion)* Add CSGUnion example
- *(CSGUnion)* Ad parseCSGUnionSH proc
- *(CSGUnion)* Add CSGUnion getHitPayload proc & test
- *(CSGUnion)* Add getAABB proc & test
- *(CSGUnion)* Add CSGUnion type, constructor & test
- *(Ellipsoid)* Add ellipsoid example
- *(Ellipsoid)* Add getHitPayload proc & test
- *(Ellipsoid)* Add getUV proc & tests
- *(Ellipsoid)* Add getNormal proc & test
- *(Ellipsoid)* Add getABBB procs & tests
- *(Shape)* Add new shape kind Ellipsoid & Ellipsoid contructor
- *(Mesh)* Add obj file reading proc
- *(Point)* Add * proc for Point2D, Point3D type
- *(Normal)* Add toVec3 proc
- *(CSGDIff)* Add CSGDiff rayIntersection proc
- *(Shape)* Add allRayIntersections, implemented only for spherical shapes
- *(Shape)* Add in_shape procedure
- *(CSG)* New CSG example
- *(CSGUnion)* Add fastIntersection procedure
- *(CSG)* Add CSGUnion rayIntersection procedure
- *(CSG)* New skCSGInt kind
- *(CSG)* New CSGUnion and CSGDiff types
- *(Ray)* Ray is now a simple object and not a ref object.
- *(Scene)* New Light type
- *(Shape)* SkTriangle now holds a seq[Points].
- *(BVH)* New BVHTree type.
- *(BVH)* Better Scene type has now a tree of type BVHNode
- *(BVH)* GetClosestHit now has a default value for a miss, deprecating the usage of Option type.
- *(BVH)* Better nodeStack sorting.
- *(BVH)* Faster algorithm
- *(BVH)* New algorithm to traverse BVH tree and retreive the closest hit.
- *(ObjectHandler)* New type to unite Shape and Mesh types.
- *(CookTorranceBRDF)* Corrected sampling pdf.
- *(HDRImage)* HDRImage type is now a ref object.
- *(Parser)* Add parseDefScene proc & test
- *(Parser)* AddparseCamera proc & test
- *(Parse)* Add parseMeshSH proc & test
- *(Parser)* Add parseCylinderSH proc & test
- *(Parser)* Add parseTriangleSH proc & test
- *(Parser)* Add parseBoxSH proc & test
- *(Parser)* Add parsePlaneSH proc & test
- *(Parser)* Add parseSphereSH proc & test
- *(Parser)* Add parseTransformation proc & test
- *(Parser)* Add parseBRDF & parseMaterial procs & tests
- *(Parser)* Add parsePigment proc & test
- *(Pigment)* Add newTexturePigment proc, in order to create a texture pigment from file, neeeds testing
- *(Parser)* Add parseVec & parseColor procs
- *(InputStream)* Add expectIdentifier proc & test
- *(InputStream)* Add expectString proc & test
- *(InputStream)* Add expectNumber proc & test
- *(InputStream)* Add expectKeywords proc & test
- *(Parser)* Add expectSymbol proc & test
- *(DefScene)* Add DefScene type and newDefScene proc
- *(InputStream)* Add readToken & unreadToken procs
- *(InputStream)* Add parseKeywordOrIdentifierToken proc & test
- *(InputStream)* Add parseNumberToken proc & test
- *(InputStream)* Add parseLiteralToken proc & test
- *(InputStream)* Add skipWhitespaceComments proc
- *(InputStream)* Add unreadChar proc and test
- *(InputStream)* Add readChar proc
- *(InputStream)* Add updateLocation proc
- *(InputStream)* Add InputStream type and constructor
- *(Token)* Add token constructor procs
- *(Token)* Add Token kinds and different keywords
- *(SourceLocation)* Add $ proc
- *(Lexer)* Add SourceLocation type & constrctor
- *(Mesh)* It's Tour the France time, new mesh example of a bike (assets/meshes/roadBike.obj tracked with Git lfs)

### 🐛 Bug Fixes

- *(BRDF)* Removed ref object
- *(tests)* First attempt at solving windows failed CI.
- *(Cylinder)* Fix cylinder getHitPayload proc bug
- *(Scaling)* Now correct scaling proc
- *(Sphere)* Correct newSphere proc
- *(tkComposition)* Fix tkComposition inverse proc
- *(Ray)* Now ray.tSpan.min != 1, == 1e-5
- *(Composition)* Correct composition normal apply
- *(Interval)* Better newInterval proc
- *(Scaling)* Fix issue #63
- *(updateLocation)* Now it should work also on windows

### 🚜 Refactor

- *(Shape)* Correct examples
- *(PhotoNim)* Correct mesh examples, now working
- *(CSG)* Change csg example, now woring
- *(PhotoNim)* Update cornell example
- *(geometry)* Now correct
- *(PhotoNim)* Demo refactoring
- *(PhotoNim)* Once again we can define scenes via text files
- *(Parser)* Almost finished, just need to focus on parseDefScene and parseCamera
- *(PhotoNim)* Now brdf, pigment & material in only one file
- *(Parser)* Refactoring parser, need to update it to current code version
- AABB alias type instead of explicit Interval[Point3D]. invRay -> localInvRay
- *(sceneFiles)* Now split in lexer & parser, lexer tests are passing
- *(PhotoNim)* Final tests
- *(PhotoNim)* Correct geometry & hitrecord test
- *(PhotoNim)* Correct test implementation for camera, brdf & csg
- *(PhotoNim)* Correct source file
- *(PhotoNim)* Small refactor, now scene tests are passing
- *(inShape)* Add CSGUnion case of
- *(CSGUnion)* Change hitPayload ray
- *(SceneTests)* Change newCSGUnion proc test
- *(GeometryTests)* Small refactoring, now all good
- *(Mesh)* Made reading .obj files proc safer
- *(Mesh)* Add functionalities to triangulate higher dimensional meshes
- *(GeometryTest)* Add teardown enviroment
- *(GeometryTest)* Add teardown enviroment
- *(CSGUnion)* Smarter ray intersection implementation
- *(CSGExample)* Change CSG example
- *(Shape)* Delete allTimeHits proc
- *(HitRecordTesting)* Now makes tests more exhausive, it could hit more than one shape
- *(Geometry)* No more Vec4f
- *(getClosestHit)* Better ordering and readability.
- *(Scene)* BVHTree is now an object and the brdf & radiance in the OH is now reserved only for the hkShape.
- *(Geometry)* Removed Mat, Vec is now reserved for float32, better templated ops on Vec and better geometry.nim code structure.
- *(Camera)* Better parameters ordering in samplePixel.
- *(SceneTests)* Now split in half, scene passing, currently working on shape
- *(Demo)* Delete demo main, now using sceneFile
- *(Cornell)* Correct Cornell example
- *(Material)* Previous material implementation
- *(demo)* Delete demo main, this should be executable by nimble tasks
- *(Mesh)* Change mesh examples
- *(Mesh)* Cange dragon example
- *(Mesh)* Correct airplane example
- *(scenFiles)* Now compatible with geometry
- *(Geometry)* Apply no longer is a template proc, now divided
- *(Geometry)* Now not using Mat4f, 0.4 s faster
- *(HitRecord)* Better ray naming.
- Shape.nim contains now the procedure to create an ObjectHandler of kind hkShape, similar with mesh.nim (to implement better in future)
- *(DemoTask)* Now it's only possible to specify renderer kind
- *(Demo)* Change demo task, automatically using demo.txt
- *(sceneFiles)* That should be it
- *(sceneFiles)* Now it should be ok
- *(sceneFiles)* Ops, forgot source file
- *(sceneFiles)* Damn I was wrong
- *(sceneFiles)* I was kidding before, now i feel like this should be it
- *(PhotoNim)* Complete merge procedure
- *(PhotoNim)* Add rend command, now fileScene parsing is possible
- *(Mesh)* Correct trumpet example
- *(Material)* DiffuseBRDF -> LambertianBRDF; SpecularBRDF -> FresnelMetalBRDF.

### 📚 Documentation

- *(Cornell)* Update Cornell box.
- *(Geometry)* Add geometry documentation
- *(PhotoNim)* Attempt to header documentation.
- *(PCG)* Documentation and refactoring of newRandomSetUp proc.
- *(Ray)* Documentation with nimDocs
- *(examples)* Nspheres.nim updated.
- RoadBike example updated.
- *(HDRImage)* Add HDRImage definitive docs
- *(Geometry)* Final geometry documentation
- Cornell Box example

### 🧪 Testing

- *(Material)* Add newTextureMaterial proc test
- *(Parser)* Add parseCSGUnionSH proc test
- *(Parser)* Add parseHandlerSeq proc test
- *(Parser)* Add parseEllipsoidSH proc test
- *(PhotoNim)* All good, updated to latest refactor
- *(PhotoNim)* Final refactor
- *(PhotoNim)* Create color.nim test file, add some checks to camera.nim
- *(PhotoNim)* Ray test file
- *(FlatRenderer)* Add FlatRenderer algorithm test
- *(Renderer)* Add OnOff renderer test
- *(Renderer)* Add Furnace test, got lost in code refactoring
- *(CSGUnion)* Add getClosestHit proc test
- *(CSGUnion)* Add newCSGUnion proc test
- *(getClosestHit)* Another random testinsg, also when you are inside a shape is correct
- *(PhotoNim)* Now passing
- *(Geometry)* Now passing
- *(CSGDiff)* Add getVertices and getAABB proc tests
- *(CSGInt)* Add allHitPayload proc test
- *(CSGInt)* Add CSGInt hitpayload proc test
- *(CSGInt)* Add getAABB proc test
- *(CSGInt)* Add getVertices proc test
- *(HitPayload)* Add getAllHitPayload proc test
- *(Parser)* Add parseCSGUnionSH proc test
- *(HitPayload)* Extend CSGUnion proc test
- *(CSGUnion)* Add getVertices test
- *(Ellipsoid)* Add newEllipsoid proc test
- *(CSGUnion)* Add rayIntersection proc test
- *(Sphere)* Add non-uniform sphere tests, change newVec3( float32 in newVec3f(
- *(Sphere)* Add allRayIntersection proc test
- *(Shapes)* Makes some tests more exhaustive
- *(tkComposition)* Add @ proc test
- *(Sphere)* Add in_shape proc test
- *(CSG)* Complete newskCSG... proc
- *(CSG)* Correct skCSGInt constructor
- *(getClosestHit)* We now are looking for hits, random testing once again
- *(getClosestHit)* Add getClosestHit first random testing
- *(getClosestHit)* Add getClosestHit test
- *(PhotoNim)* Delete materials, now useless
- *(PhotoNim)* Now passing
- *(PhotoNim)* Split materialsin brdf & pigment
- *(Camera)* Now passing
- *(getLocalIntersection)* Add getLocalIntersection proc for available shape kinds
- *(HitRecord)* Add HitPayload and HitInfo tests
- *(Scene)* Now passing
- *(Shape)* Now passing
- *(Camera)* Now passing
- *(PCG)* Now passing
- *(Geometry)* Now passing
- *(Rotation)* Makes rotation tests exhaustive
- *(Geometry)* Add scaing on normal proc test
- *(PhotoNim)* Refactoring all tests, now should pass everything
- *(Material)* Add material tests
- *(Camera)* Camera tests, now passing
- *(Geometry)* Refactored and passing
- *(Scene)* Now passing
- Compatibility check and removed unused imports.
- *(Parser)* Add parseVec & parseColor proc tests
- *(DefScene)* Add newDefScene proc test
- *(InputStream)* Add unreadToken proc test
- *(InputStream)* Add readToken proc test
- *(HdrImage)* Now readFloat & writeFloat tests are back, PhotoNim tests now passing
- *(InputSteam)* Add skipWhitespaceComments proc test
- *(InputStream)* Add readChar proc test
- *(InputStream)* Add updateLocation proc test
- *(InputStream)* Add newInputStream proc test
- *(Token)* Add newToken procs test
- *(SourceLocation)* Add SourceLocation type tests

### Bug

- *(sceneFiles)* Maybe I found it

### Delete

- *(Shape)* Delete inAllShapes proc and test, pointless

### Example

- *(airplane)* Lamp light brdf is now not nil.

### Removed

- *(Material)* Cook-Torrance BRDF model #50
- *(Geometry)* Quat implementation.

## [0.3.0] - 2024-06-23

### 🚀 Features

- *(Earth)* Earth task with nimble.

### 🐛 Bug Fixes

- *(Mesh)* Fix mesh examples, now correctly working
- *(HDRImage)* ToneMap and applyToneMap proc fixed #57
- *(sampleRay)* RkFlat was not sorting the HitRecord.
- *(sampleRay)* Early return statement using isNone instead of isSome produce better indentation for the camera.rendere.kind case.
- ScatterDir for a DiffuseBRDF now project the dir to the ONB created from the hitNormal in the shape reference system.
- *(CI)* Use Nim 2.0.0 for testing.

### 🚜 Refactor

- *(HDRImage)* SavePNG now uses newStringOfCap (#52)
- Demo and demoAnim nimble tasks
- *(assets)* Now assets contains images, meshes and textures
- *(savePNG)* Avoid raising exceptions only to quit with them.
- Assets folder
- *(PhotoNim)* Removed unused imports and updated PhotoNim version to 0.2 (very soon 0.3 release)
- *(pfm2png)* Pfm2png now uses readPFM and savePNG procs.
- Ordering the imports in the src directory
- Removed ReferenceSystem from previous implementation.
- Removed renderer.nim
- *(GeometryDocs)* Change reference system docs

### 📚 Documentation

- *(README)* Add link to documentation site.
- *(README)* Updated README.md with nimble tasks.
- *(demo)* Nimble demo task updated documentation is visible running `nimble tasks`.

### 🧪 Testing

- *(PhotoNim)* Now passing
- *(PhotoNim)* Now passing
- *(Geometry)* Small refactor

### Example

- *(Mesh)* Add some fun mesh examples

## [0.2.0] - 2024-06-08

### 🚀 Features

- *(Main)* Add material to shapes to render
- *(Renderer)* Add fire_all_rays proc
- *(Renderer)* Add fire_all_ray with render type
- *(Sphere)* Add allTimesIntersection proc test
- *(PathTracer)* Add call proc
- *(Color)* Add Color multiplication proc
- *(PathTracer)* Add PathTracer constructor type
- *(FlatRenderer)* Add call proc
- *(FlatRenderer)* Add newFlatRenderer proc
- *(World)* Add rayIntersection proc
- *(OnOffTracer)* Add call proc, that gives as output shape color
- *(World)* Add fastIntersection with world
- *(Renderer)* Add newOnOffRenderer proc
- *(Renderer)* Add Renderer type
- *(SpecularBRDF)* Add scatter_ray proc
- *(DiffuseBRDF)* Add scatter_ray proc
- *(ONB)* Add Duff et al. algorithm
- *(ONB)* Add newONB proc
- *(Geometry)* Add ONB type, in order to store orthonormal base
- *(Mesh)* Better newMesh proc. ToDO: regular polygons meshes.
- *(Scene)* Use kmeans++ for centroids initialization (#41)
- *(MESHES)* Ganesh pt 10, the ultimate commit.
- Kmeans implementation
- *(BVH)* Fix wrong implementation using subscenes.
- *(Geometry)* Use mapIt.
- *(HDRImage)* Use mapIt and applyIt instead of map and apply.
- *(Shape)* Use mapIt.
- *(ReferenceSystem)* New type as ref object.
- *(HitRecord)* Use mapIt and filterIt to better code in getHitPayloads and newHitRecord procs.
- *(Scene)* Filter AABB when creating a new node, maybe it could be better implemented (follow comments).
- *(Ray)* Type Ray is now a ref object.
- *(HitRecord)* New checkIntersection for AABB and ray.
- *(Renderer)* New sampleRay proc to use BVH trees from different scenes inside of rkPathTracer.
- *(Translation)* NewTranslation accepts also a Point3D.
- *(RefSystem)* Add RefSystem type and constructor proc
- *(ONB)* Add newVector proc
- *(ONB)* Add getComponents proc
- *(Normal)* Add toVec3 proc
- DisplayProgress bool flag added to Renderer.sample proc
- *(Shape)* New uv proc for skAABox.
- *(BVH)* New fastIntersection proc for a SceneNode.
- *(BVH)* New SceneNode and SceneTree types. newBVHNode proc to create a BVH node from a list of shapes.
- *(Shape)* New procedure to get the AABox and the World AABox of a generic shape.
- *(HitRecord + Interval)* Using Interval in fastIntersection and rayIntersection procs.
- *(Ray)* Removed tmin and tmax in favor of tspan as an Interval[float32].
- *(HitRecord)* FastIntersection for skCylinder.
- *(Point3D)* `<` and `<=` procs.
- *(Vec)* `==` proc.
- *(HitRecord)* NewHitRecord proc to ease the code.
- BRDF type, BRDFKinds (DiffuseBRDF, SpecularBRDF) and eval proc implementation.
- *(Pigment)* Pigment type with PigmentKinds (pkUniform, pkTexture, pkCheckered), constructors and getColor proc.
- New texture images as pfm and png
- New demo with antialiasing
- New Transformations
- *(ImageTracer)* ImageTracer implementation moved to imagetracer.nim. ImageTracer supports now stratified sampling as MC antialias strategy.
- *(PCG)* Old rand proc is now called random, new rand proc now return a float32 in [0, 1] range.
- *(CSGDiff)* Add CSGDiff fast intersection procedure
- *(CSGDiff)* Add rayIntersection procedure
- *(Shape)* Add allHitTimes procedure
- *(Shape)* Add allRayIntersection procedure necessary to CSG Difference
- *(CSG)* Add CSGDifference kind
- *(Triangle)* Add fast intersection procedure
- *(CSGUnion)* Add CSGUnion ray intersection procedure
- *(CSGUnion)* New fast intersection method
- *(Shape)* New kind of shape CSGUnion
- *(CSG)* New example file
- *(Shape)* Add CSG union method
- *(Point3D)* Add max procedure for Point3D sequences
- *(Point3D)* Add min procedure for Point3D sequence
- *(Geometry)* Add VecNf type constructor
- *(ShapeKind)* New skMesh ShapeKind.
- *(Camera)* New CameraKind (ckOrthogonal, ckPerspective).
- Triangle example
- NewNormal procedure normalize the normal. Maybe this is only a slow proc.
- RayIntersection for skTriangle using Mat3 solve.
- Solve mat3 using Cramer's rule
- RayIntersection for Triangle. ToDo: implement solve proc for matrix equations.
- NewSphere and newUnitarySphere constructor that use Sphere attributes to define the Shape.Transformation
- *(Pcg)* Add rand procedure
- *(Pcg)* Add newPcg procedure
- *(Pcg)* Add Pcg type
- Mesh type implementation
- RayIntersection for box
- *(ImageTracer)* Add new fire_all_rays procedure
- *(ImageTracer)* Add different fire_all_rays implentation, now a procedure is given as imput
- *(World)* Add get procedure
- *(World)* Add procedure to add a shape to the scenary ro render
- *(docs)* New Jekyll static site for the official PhotoNim documentation.
- *(Plane)* Add plane fast intersection method
- *(Plane)* Add intersectionRay method
- *(Plane)* Add plane constructor
- *(Sphere)* Add fastIntersection procedure to check wether an intersection could happen or not
- *(Sphere)* Add checking
- *(Sphere)* Add procedure to compute intersection
- *(Transformation)* Add Normal transformation base method
- *(Sphere)* Add (u, v) coordinates computation
- *(Sphere)* Add Normal computation procedure
- *(Transformations)* Add apply methods for Point3D and Vec3f type
- *(Transformation)* Add @ overloading, now we can apply transformations to Point3D and Vec3f
- *(Shapes)* NewSphere procedure
- *(Shapes)* Add Shape abstract type and base method intersectionRay
- *(HitRecord)* Add areClose procedure
- *(HitRecord)* Add newHitRecord procedure
- *(HitRecord)* Add areClose procedure
- *(HitRecord)* Add HitRecord type
- *(Transformation)* Add identity transformation procedure
- *(ImageTracer)* Add fire all ray procedure
- *(ImageTracer)* Add fire_ray ImageTracer procedure
- *(ImageTracer)* Add ImageTracer constructor
- *(ImageTracer)* Add ImageTracer type
- *(Camera)* Add perspective fire_ray procedure
- *(Camera)* Add PerspectiveCamera type & constructor
- *(Camera)* Add fire_ray procedure for Orthogonal Camera
- *(Ray)* Add transformRay procedure, delete distinct procedure for different transformation types
- *(Camera)* Add OrthogonalCamera type & constructor
- *(Camera)* Add fire_ray base method
- *(Ray)* Add ray rotation procedure
- *(Geometry)* Add procedure to change between different data types
- *(Ray)* Add second ray translation procedure, using a transformation
- *(Ray)* Add ray Translation transformation
- *(Ray)* Add areClose procedure
- *(Ray)* Add determination of ray position procedure
- *(Ray)* Add ray constructor
- *(Transformation)* Add 3 constructor for X, Y and Z rotations
- *(Transformation)* Add new scaling constructor
- *(Transformation)* Add rotation constructor
- *(Translation)* Add traslation application optimized method
- *(Transformation)* Add scaling transformation application
- *(Transformation)* Add is_consistent procedure
- *(Transformation)* Add inverse procedure
- *(Transformation)* Add procedure to apply a generic transformation
- *(Transformation)* Add Transformation product
- *(Transformation)* Add transformation product
- *(Quat)* New Quaternion data structure.
- Mat identity procedure and dot products
- *(Mat)* Matrix types and simple operations defined in common.nim and used in Transformation types.
- Promotion rules from Vec3f-Point2D-Point3D to Vec4f
- *(LinearTransformation)* Add Rotation transformation
- *(LinearTransform)* Add mixed transformation product
- *(LinearOperations)* Add scaling operations
- *(LinearTransformation)* Add Scaling type, constructor and consistency procedure --> add template procedure for matrix scaling
- *(Translation)* Add Translation constructor
- *(LinearTransformation)* Add transformation vec product
- *(LinearTransformation)* Add inverse procedure
- *(LinearTransform)* Add 4x4 matrix product procedure & is_consistent
- *(Common)* Add areClore template procedure in order to check arrays
- *(LinearTransform)* Add Transformation multiplication and Transform template type sum and difference
- *(LinearTransformations)* Add template tranformation type, template constructor, template scal & transformation operations and Translation type
- *(lineartransform)* Created new package
- Last commit badge.
- *(HdrImage)* Assert are now followed by a formatted string.
- Continuous integration with GitHub Actions.

### 🐛 Bug Fixes

- *(checkIntersection)* Fix checkIntersection proc
- *(HitPayload)* Removed ptr to Shape that was causing a segmentation fault due to wrong access to a Shape tmp variable.
- *(Translation)* Fix apply error
- *(Example)* Correct bvh example implementation
- Antialiasing pixel offset calculation.
- *(Interval)* Contains proc now check for `<=` and `>=` instead of strict `>`, `<`.
- *(Shape)* SkSphere.transform is now only a translation and the skSphere.radius is correctly used in the getAABox and in ray intersection procs.
- Test newNormal(0, 0, 0) has norm 0 so it is not Normal.
- Shape child were losing their type info when passed in World's seq[Shape], thus provoking no fastIntersection calculations.
- Ignore docs update in git-cliff and github ci actions.
- *(pfm2png)* Bug #26 fixed.
- *(hdrimage)* Bug #25 fixed
- Do not use newTransformation for composition and scaling existing transformations.
- *(Transformation)* New implementation that avoids more complex abstraction layers
- *(PhotoNim)* Removed int convertion for uint index.
- *(HdrImage)* Bug in validPixel when switched from uint to int.
- *(HdrImage)* Change uint in favour of int (https://forum.nim-lang.org/t/8737).
- Removed unused module imports.
- Nim macro flags start and end with a dot: {.inline.}, {.borrow.}

### 🚜 Refactor

- *(TracerTest)* Correct Furnace Test
- *(Renderer)* Change constructor proc
- *(PathTracer)* Fix newPathTracer proc
- *(World)* Change newWorld proc
- *(GeometryTest)* Delete useless variable
- *(Geometry)* Correct project proc and test, delete getTransfomation
- Removed SubScene type.
- *(Camera)* Added scatter proc.
- Use getWorldObject proc for ReferenceSystem.
- *(ReferenceSystem)* Change project & compose procs, now accounting for frame of reference translation
- *(PhotoNim)* Changes how rays are handled
- *(PhotoNim)* Now compiling correctly
- *(BRDF & PIGMENT Unittest)* Now passing
- *(RayUnittest)* Change ray test suite, now passing
- *(Scene)* Change newBVHNode proc
- *(Scene)* Change getAABB proc
- Removed unused imports.
- *(Transformation)* Change tkComposition application proc
- *(RefSystem)* Change reference system
- *(ONB)* Change ONB, now a matrix 3x3
- *(Transformation)* Makes Vec4f translation safer
- *(CameraTest)* Change camera testing procedure, now working
- *(PCG)* Update pcg tests, now working
- *(PhotoNim)* Ready for version 0.2.0, only OnOff and Flat renderer
- *(Scene)* Change scene in order to store ptr to transformations and shapes
- *(Renderer)* Delete path tracer implementation
- *(HitRecord)* Delete allHitTimes proc
- Discard rkPathTracer
- DisplayProgress
- File structure.
- Reset stdout attributes after progress bar.
- Update nomenclature in docs.
- Include BVH and modify fire_all_rays -> fireAllRays.
- Identity const transformation is now called IDENTITY.
- Using Ray.tspan as interval to return HitRecord.
- Importing modules.
- *(HitRecord)* Changing hitrecord.nim procs according to refactoring in shapes.nim.
- *(Camera)* Camera.kind is now visible as well as ckPerspective.distance.
- New assets folder
- Removed unused fire_all_rays proc with no arguments.
- Comments removed
- Removed unused imports.
- *(CSG)* Delete all CSG types and procedures
- *(CLI)* Help command and demo proc.
- *(Shape)* Delete allRayIntersection procedures
- *(CSGUnion)* Change rayIntersection procedure
- *(csg.nim)* Correct CSG examplee
- *(Example)* Change PhotoNim, now it's possible to give avlum as option
- *(HdrImage)* Change toneMapping procedure, sometimes we need to give avlum value as external input
- *(CSGUnionEx)* Correct CSGUnion example
- *(TriangleEx)* Change triangle example
- *(triangle.nim)* Remove unnecessary PNG file handler
- *(PhotoNim.nim)* Correct sphere radius
- *(Shape)* Add aabb to skTriangularMesh
- Change skMesh in skTriangularMesh
- Stop gitignoring images
- Removed newImageTracer proc
- Hdrimage.nim is now moved to camera.nim. The PhotoNim.nim is moved to the root directory and export all the src files and usefull procs.
- RayIntersection proc
- Some ';' when the first procedure argument is the one who call the proc.
- Follow master ordering.
- More order in shapes.nim to better implement more complex shapes such as boxes, triangles and meshes.
- Pcg -> PCG, random.nim -> pcg.nim
- *(ImageTracer)* Correct fire_all_rays bug
- Correct ImageTracer fire_ray procedure
- *(Pcg)* Change random procedure to rand
- Correct demo mode
- Spelling error
- Better proc for uv, normal, rayIntersection and fastIntersection using  when statements and generic types.
- Deprecated newHitRecord proc and moved areClose proc in test file.
- Uv is now a single proc that handles the typedesc of the shape.
- Float32 better convertion
- Changes to names of procs and attributes in tests.
- ShapeNormal procs are now called normal(shape, ...).
- Renamed toUV proc to uv.
- Renamed map_pt to surface_pt
- More order in shapes.nim to better implement more complex shapes such as boxes, triangles and meshes.
- Remove duplicated std/strutils imports.
- Ray test updated after renaming starting point of the ray from start to origin
- *(Ray)* Start is now called origin, the initial tmin is set to epsilon(f32).
- *(HdrImage)* Change endiannes evaluation
- *(ShapeTests)* Correct shape test implementation
- *(camera)* NewCamera procs are now divided in newOrthogonalCamera and newPerspectiveCamera.
- Change constructor porcedure
- *(Plane)* Correct intersectionRay procedure, now using inverse transform on ray
- *(Ray)* Change ray transform procedure
- *(Sphere)* Make sphere.intersectionRay procedure public
- *(Sphere)* Correct sphere_uv implementation
- *(Transformations)* Change Scaling constructor
- *(Transformation)* Changed return types of @ operator
- *(HitRecordTest)* Changed newHitRecord procedure test
- *(HitRecordTest)* Change HitRecord constructor test
- *(ImageTracerTest)* Add correct orientation test
- *(ImageTracer)* Correct index choice
- *(ImageTracerTest)* Divide in two tests
- *(TransformationTest)* Add setup enviroment
- *(CameraTest)* Add setup enviroment
- *(Camera)* Identity transformation is default transformation
- *(CameraTest)* Identity transformation in default transform
- *(ImageTracer)* Correct fire_all_ray implementation
- *(ImageTracer)* Correct a typo in fire ray procedure
- *(CameraTest)* Change perspective fire ray procedure test
- *(CameraTest)* Change orthogonal fire ray procedure
- *(RayTest)* Change tranlateRay test
- *(RayTest)* Change at procedure test
- *(Ray)* Make some types public, correct some typos
- *(Transformation)* More efficient newRotZ constructor
- *(Transformation)* Correct RotX implemetation
- *(Transformation)* Make some procedure public
- *(TransformationTest)* Changed transformation application test
- *(Transformations)* Made some procedures public
- *(CommonTest)* Changed layout
- *(Transformation)* Correct scaling transformation apply method
- NewScaling and newTranslation.
- *(Scaling)* Change constructor, now correct implementation
- *(LinearTransformation)* Add & change some comment
- Explicit importing from std and other libs listed in PhotoNim.nimble.
- *(PhotoNim)* 'convert' command is now called 'pfm2png' and it has its own procedure.
- *(HdrImage)* Parse/writeFloat are better formatted. readPFM now returns a tuple with the image and the endianness which otherwise would be lost.
- *(HdrImage)* Delete redundant Color implementation.
- *(Color)* Removed min/max.

### 📚 Documentation

- *(PhotoNim)* Changes index & index contents
- *(Camera)* Add BRDF & Pigments doc, delete ImageTracer doc
- *(PCG)* Add pcg example, broadens doc part
- *(PCG)* Add PCG documentation
- *(Camera)* Change layout style
- *(Geometry)* Change layout style
- *(Geometry)* Change layout style
- *(Geometry)* Add ONB documentation
- *(Geometry)* Add Transformation types and procs procedure
- *(Geometry)* Add matrices types and procs doc
- *(Geometry)* Add Distinct vector types example
- *(Geometry)* Add distinct types and procs docs
- *(Geometry)* Add Vec type and procs documentations
- PhotoNim CLI in README.md
- Installation page
- Installation page
- *(camera.nim)* End camera.nim documentation
- *(ImageTracer)* Imagetracer documentation
- *(Camera)* Final camera documentation
- *(HdrImage)* Small refactor
- *(Ray)* Add ray documentation
- *(Camera)* End HdrImage documentation
- *(Camera)* Change formula
- *(Camera)* Add HdrImage beginning
- *(Camera)* Small change in text format
- *(Camera)* Small change in text format
- *(Camera)* Add Color part
- *(Camera)* Start Camera documentation
- Documenting PhotoNim CLI
- Add examples task and dir.
- New site structure with roadmap and examples.
- See if workflow starts.
- Update again jekyll gh pages workflow
- Update jekyll workflow
- New jekyll workflow
- Updated jekyll gh-pages workflow.
- Jekyll site
- Trying different gh actions for deploying the jekyll static site.
- Moved jekyll-gh action workflow from master to docs branch.
- Removed docs from master and opened a new branch only for docs.

### 🧪 Testing

- *(PathTracer)* Add Furnace test
- *(PathTracer)* Add call proc test
- *(Color)* Add * proc test
- *(PathTracer)* Add newPathTracer proc test
- *(FlatRenderer)* Add call proc test
- *(FlatRenderer)* Add newFlatRenderer proc test
- *(World)* Add rayInterection proc test
- *(OnOffRenderer)* Add call proc test
- *(World)* Add fastIntersection proc test
- *(OnOffRender)* Add newOnOffRender proc test
- *(BRDF)* Add scatter_ray proc test
- *(BRDF)* Add eval proc test
- *(BRDF)* Add newBRDF proc test
- *(ONB)* Add create_onb random testing
- *(ONB)* Add ONB proc test
- *(PhotoNim)* Small refactor
- *(Camera)* Now passing
- *(HdrImage)* Now passing
- *(HitRecord)* Now passing
- *(Camera)* Now passing
- *(Camera)* Now passing
- *(HitRecord)* Add getHitRecord proc test in specific reference system
- *(HitRecord)* Add getHitRecord proc test in stdRS
- *(HitPayload)* Add getHiPayloads proc test in general frame of reference
- *(HitPayload)* Add getHitPayloads proc test (stdRS)
- *(HitPayload)* Add getHitPayload proc test for triangle and cylinder, found a bug in cylinder
- *(HitPayload)* Add getHitPayload proc for Plane & AABox
- *(HitPayload)* Add Sphere HitPayload test
- *(HitRecord)* Correct HitRecord test, now passing
- *(Camera)* Now passing
- *(Shape)* Now passing
- *(Scene)* Now passing
- *(HitRecord)* Make tests exaustive, maybe found a bug
- *(HitRecord)* Add getHitLeafs proc test
- *(ReferenceSystem)* Makes project and getWorldObj exaustive
- *(HitRecord)* Add checkIntersection proc test
- *(Geometry)* Now passing
- *(Camera)* Now passing
- *(PCG)* Now passing
- *(HdrImage)* Now passing
- *(AABox)* Add getAABB and getVertices procs test
- *(AABox)* Add getUV proc test
- *(AABox)* Add getNormal proc test
- *(Cylinder)* Add getUV, getABB & getVertices procs test
- *(Cylinder)* Add newCylinder & getNormal proc test
- *(Triangle)* Add getAABB and getVertices proc test
- *(Triangle)* Add newTriangle, newNormal and getUV procs tests
- *(Sphere)* Add getAABB & getVertices tests
- *(Sphere)* Add getNormal and getUV proc test
- *(Sphere)* Add constructor procedure test
- *(AABB)* Add getVertices proc test
- *(AABB)* Add getTotalAABB test
- *(AABB)* Add getAABB (from points) proc test
- *(AABox)* Add newAABox proc test
- *(Material)* Add newMaterial proc test
- *(Scene)* Now passing
- *(Geometry)* Now passing
- *(Scene)* Add fromObserver procedure test
- *(Scene)* Makes newScene proc test more exhaustive
- *(Scene)* Makes test exaustive
- *(Scene)* Add another ref system, now passing
- *(Scene)* Test adjusted.
- *(Scene)* Add old tests
- *(Scene)* Add ABBB proc (with reference system)
- *(ShapeHandler)* Add getAABB (in World) proc test
- *(Scene)* Add ShapeHandler constructor procs test
- *(HDRImage)* Add newPixelMap proc test
- *(Color)* Add luminosity proc test
- *(Color)* Add color operation procs test
- *(Color)* Add r, g, b procs test
- *(Color)* Add newColor proc test
- *(ReferenceSystem)* Add getTransformation proc test
- *(ReferenceSystem)* Add fromCoeff proc test
- *(ReferenceSystem)* Add coeff proc test
- *(ReferenceSystem)* Add newReferenceSystem proc test
- *(ONB)* Add newRightHandedBase proc test
- *(Geometry)* Now passing
- *(Composition)* Add apply tkComposition tests
- *(tkComposition)* Add newComposition proc test
- *(Transformations)* Add @ proc test
- *(Scene)* Add features to Scene testing
- *(Scene)* Fix RefSystem test suite
- *(Mat)* Add T proc test
- *(ONB)* Change ONB tests
- *(RefSystem)* Add newRefSystem proc test
- *(Translation)* Add normal translation test, refactor normal translation proc
- *(Transformation)* Add Point3D rotation test, broaden Vec4f rotation test
- *(Translation)* Add Vec3f translation test
- *(Translation)* Fix Vec4f test
- *(ONB)* Add newVector proc test
- *(ONB)* Add getComponents proc test
- *(Normal)* Now random testing works, no problem with geometry tests
- Update test with current changes.
- Update examples of shapes usage.
- *(Pigment)* Tested newUniformPigment, newTexturePigment, newCheckeredPigment.
- *(Point3D)* Add max procedure test
- *(Point3D)* Add min proc test
- *(Sphere)* NewSphere and newUnitarySphere procs tested.
- *(Pcg)* Add rand procedure test
- *(Pcg)* Add newPcg procedure test
- *(World)* Get procedure test
- *(World)* Add procedure test
- *(All)* Correct test implementation
- *(Plane)* Add fast intersection test
- *(Plane)* Add intersectionRay test module 2
- *(Plane)* Add intersectionRay procedure first module test
- *(Plane)* Add new plane constructor
- *(Sphere)* Add fastIntersection procedure check
- *(Sphere)* Add intersectionRay test module 2
- *(Sphere)* Add first module intersectionRay procedure test
- *(Transformations)* Add Normal transformation base method
- *(Sphere)* Add (u, v) coordinates computation test
- *(Sphere)* Add Sphere Normal procedure test
- *(Transformations)* Add last needed test for transformation application
- *(Scaling)* Add new scaling application on Vec4f test
- *(Transformations)* Add apply base method tests
- *(Trasformations)* Add new overload @ tests
- *(Shapes)* Add newSphere procedure test
- *(HitRecord)* Add areClose procedure test
- *(HitRecord)* Add newHitRecord procedure test
- *(ImageTracer)* Add image orientation test
- *(ImageTracer)* Add ImageTracer type test
- *(Camera)* Change orthogonal camera fire ray procedure test
- *(Camera)* Add perspective fire ray procedure
- *(Camera)* Add PerspectiveCamera constructor test
- *(Camera)* Add Orthogonal Camera fire_ray procedure
- *(Ray)* Add ray transformation test (this will fail)
- *(Camera)* Add Orthogonal Camera constructor test
- *(Ray)* Add ray rotation procedure
- *(Ray)* Add second ray translation procedure test
- *(Ray)* Add ray translation test
- *(Ray)* Add ray areClose procedure test
- *(Ray)* Add at procedure test
- *(Ray)* Add ray constructor test
- *(Transformation)* Add Rotation test
- *(Scaling)* Add new constructor test
- *(Transformation)* Add Translation test
- *(Transformations)* Add Scaling test
- *(Transformations)* Add constructor, consistency and inverse test
- *(Transformation)* Add mult/div by a scalar test
- *(Transformations)* Add Transformation product test
- *(Common)* Add matrix product check
- *(Common)* Add element wise Mat operations tests
- *(Common)* Add Mat type constructor test
- Nimble Test Task.

### ToDO

- *(ReferenceSystem)* NewReferenceSystem from transformation.

### Todo

- Fix how scatterRay generates a new ray from 3 availables (invRay, localRay, worldRay).
- Add AABB to mesh by taking the min and max from the seq of Point3D. This needs boolean operators for Vec.

## [0.1.0] - 2024-03-28

### "feat

- *(PhotoNim)* Cli to convert an HDRImage to LDRImage using docopts."

### 🚀 Features

- *(PhotoNim)* Conver now can infer the LDR output if not passed explicitly.
- *(PhotonNim)* It is now possible to convert PFM images to PNG by using the CLI. nimPNG is added to the .nimble requirements.
- *(Color)* Operator -
- *(Color)* New operators +=, -=, *=, /=.
- *(HdrImage)* Add clamping image procedure
- *(HdrImage)* Add image normalization function
- *(HdrImage)* Add avarage luminosity (avarageLum) procedure
- *(Color)* Add luminosity procedure
- *(HdrImage)* Add parseDim procedures, finds the dimensions of pixels array
- *(HdrImage)* Add parseEndian procedure, checks whether littleEndian or bigEndian is used
- *(HdrImage)* Add write float procedure
- *(HdrImage)* Add parseFloat procedure
- *(Types)* Color: operators +, * overloaded, HdrImage: improved allocation in newHdrImage, get and set procedures.
- *(Types)* Add pixel index calculator
- *(Types)* Add valid_coord, checks wether given coordinates are valid or not
- *(HdrImage)* Add HdrImage constructor
- *(Color)* Add sumCol in order to sum two colors
- *(Color)* Add multiplication of two colors
- *(multByScalar)* Allows multiplication of a Color variable by a float number
- AreClose proc for float and Color types
- *(Color)* NewColor updated
- *(Color)* Add constructor newColor

### 🐛 Bug Fixes

- *(geometry.nim)* Now olny float32 are used!
- *(HdrImage)* Fixed toVec function
- *(common.nim)* Now only use float32
- Current nim required version is 2.0.
- .gitignore excluded all the src/ dir.
- Nim dependency is now 2.0 only.
- *(HDRImage)* Now writeFloat has Endiannes as last argument so that it is possible to use the default value.

### 🚜 Refactor

- *(PhotoNim)* Better CLI.
- No more color.nim, transfered in hdrimage.nim.
- Branch now called vectorTypes.
- *(HdrImage)* ParseEndian and parseDim are now incorporated in parsePFM, now called readPFM. imageNorm is now called normalizeImage.
- *(Test)* Adding files needed in order to test stuff
- *(HdrImageTest)* Changed averageLuminosity procedure test
- *(HdrImageTest)* Changed writeFloat and parseFloat procedure
- *(HdrImage)* Changed some procedures layout
- *(HdrImage)* Changed writePFM function, no '\n'
- *(HdrImage)* Add one dependency & add '\n' in writePFM
- *(Tests)* Delete types_test.nim file
- *(HdrImage)* Changed color background function
- *(HdrImage)* HdrImage.image now named HdrImage.pixels. feat(HdrImage): parse/writePFM
- Define different submodules for Color and HdrImage
- *(Types & TypesTest)* Changed offset calculation procedure name
- *(PhotoNim)* Deleted hdrImage.nim, merged with color.nim -> new name: types.nim
- *(PhotoNim)* Change of HdrImage filename
- *(Color)* Changed procedure multiplication of two colors name

### 📚 Documentation

- Normal, Point2D/3D in geometry.nim
- Local Just-the-Docs Jekyll site

### 🧪 Testing

- *(HdrImage)* ColorTest suite is merged into HdrImageTest suite.
- *(Vec[N, T)* Testing all the operations.
- *(HdrImage)* Add clampImage testing procedure
- *(HdrImage)* Change get_pixel to getPixel, set_pixel to setPixel
- *(HdrImageTest)* Add image normalization test
- *(HdrImageTest)* Add avarageLuminosity test
- *(ColorTest)* Add color luminosity calculator test
- *(HdrImageTest)* Add writePFM() & parsePFM() tests
- *(HdrImage)* Add writeFloat & parseFloat tests
- *(HdrImage)* Add parseDim test
- *(HdrImage)* Add parseEndian test
- *(HdrImage)* Add get pixel procedure test
- *(HdrImageTest)* Add pixel calculation test
- *(HdrImageTest)* Add test for valid coordinates procedure
- *(HdrImageTest)* Add newHdrImage test
- *(ColorTest)* Add test of procedure sumCol, which enables to sum two color variables
- *(ColorTest)* Add multCol test
- *(multByScal)* Checks multiplication by scalar
- *(Color)* Color initialization

<!-- generated by git-cliff -->
