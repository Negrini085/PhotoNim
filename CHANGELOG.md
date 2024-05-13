# Changelog

All notable changes to this project will be documented in this file.

## [unreleased]

### 🚀 Features

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

- Correct demo mode
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

- Update jekyll workflow
- New jekyll workflow
- Updated jekyll gh-pages workflow.
- Jekyll site
- Trying different gh actions for deploying the jekyll static site.
- Moved jekyll-gh action workflow from master to docs branch.
- Removed docs from master and opened a new branch only for docs.

### 🧪 Testing

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
