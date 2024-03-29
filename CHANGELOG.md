# Changelog

All notable changes to this project will be documented in this file.

## [unreleased]

### "feat

- *(PhotoNim)* Cli to convert an HDRImage to LDRImage using docopts."

### 🚀 Features

- *(Color)* Add constructor newColor
- *(Color)* NewColor updated
- AreClose proc for float and Color types
- *(multByScalar)* Allows multiplication of a Color variable by a float number
- *(Color)* Add multiplication of two colors
- *(Color)* Add sumCol in order to sum two colors
- *(HdrImage)* Add HdrImage constructor
- *(Types)* Add valid_coord, checks wether given coordinates are valid or not
- *(Types)* Add pixel index calculator
- *(Types)* Color: operators +, * overloaded, HdrImage: improved allocation in newHdrImage, get and set procedures.
- *(HdrImage)* Add parseFloat procedure
- *(HdrImage)* Add write float procedure
- *(HdrImage)* Add parseEndian procedure, checks whether littleEndian or bigEndian is used
- *(HdrImage)* Add parseDim procedures, finds the dimensions of pixels array
- *(Color)* Add luminosity procedure
- *(HdrImage)* Add avarage luminosity (avarageLum) procedure
- *(HdrImage)* Add image normalization function
- *(HdrImage)* Add clamping image procedure
- *(Color)* New operators +=, -=, *=, /=.
- *(Color)* Operator -
- *(PhotonNim)* It is now possible to convert PFM images to PNG by using the CLI. nimPNG is added to the .nimble requirements.
- *(PhotoNim)* Conver now can infer the LDR output if not passed explicitly.

### 🐛 Bug Fixes

- *(HDRImage)* Now writeFloat has Endiannes as last argument so that it is possible to use the default value.
- Nim dependency is now 2.0 only.
- .gitignore excluded all the src/ dir.
- Current nim required version is 2.0.
- *(common.nim)* Now only use float32
- *(HdrImage)* Fixed toVec function
- *(geometry.nim)* Now olny float32 are used!

### 🚜 Refactor

- *(Color)* Changed procedure multiplication of two colors name
- *(PhotoNim)* Change of HdrImage filename
- *(PhotoNim)* Deleted hdrImage.nim, merged with color.nim -> new name: types.nim
- *(Types & TypesTest)* Changed offset calculation procedure name
- Define different submodules for Color and HdrImage
- *(HdrImage)* HdrImage.image now named HdrImage.pixels. feat(HdrImage): parse/writePFM
- *(HdrImage)* Changed color background function
- *(Tests)* Delete types_test.nim file
- *(HdrImage)* Add one dependency & add '\n' in writePFM
- *(HdrImage)* Changed writePFM function, no '\n'
- *(HdrImage)* Changed some procedures layout
- *(HdrImageTest)* Changed writeFloat and parseFloat procedure
- *(HdrImageTest)* Changed averageLuminosity procedure test
- *(Test)* Adding files needed in order to test stuff
- *(HdrImage)* ParseEndian and parseDim are now incorporated in parsePFM, now called readPFM. imageNorm is now called normalizeImage.
- Branch now called vectorTypes.
- No more color.nim, transfered in hdrimage.nim.
- *(PhotoNim)* Better CLI.

### 📚 Documentation

- Local Just-the-Docs Jekyll site
- Normal, Point2D/3D in geometry.nim

### 🧪 Testing

- *(Color)* Color initialization
- *(multByScal)* Checks multiplication by scalar
- *(ColorTest)* Add multCol test
- *(ColorTest)* Add test of procedure sumCol, which enables to sum two color variables
- *(HdrImageTest)* Add newHdrImage test
- *(HdrImageTest)* Add test for valid coordinates procedure
- *(HdrImageTest)* Add pixel calculation test
- *(HdrImage)* Add get pixel procedure test
- *(HdrImage)* Add parseEndian test
- *(HdrImage)* Add parseDim test
- *(HdrImage)* Add writeFloat & parseFloat tests
- *(HdrImageTest)* Add writePFM() & parsePFM() tests
- *(ColorTest)* Add color luminosity calculator test
- *(HdrImageTest)* Add avarageLuminosity test
- *(HdrImageTest)* Add image normalization test
- *(HdrImage)* Change get_pixel to getPixel, set_pixel to setPixel
- *(HdrImage)* Add clampImage testing procedure
- *(Vec[N, T)* Testing all the operations.
- *(HdrImage)* ColorTest suite is merged into HdrImageTest suite.

<!-- generated by git-cliff -->
