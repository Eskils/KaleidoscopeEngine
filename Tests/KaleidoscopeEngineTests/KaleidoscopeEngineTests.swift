import XCTest
@testable import KaleidoscopeEngine

final class KaleidoscopeEngineTests: XCTestCase {
    
    let kaleidoscopeEngine = KaleidoscopeEngine()
    
    let bundle = Bundle.module
    
    static let projectDirectory = URL(fileURLWithPath: #filePath + "/../../../").standardizedFileURL.path + "/"
    let projectDirectory = KaleidoscopeEngineTests.projectDirectory
    
    let inputImagePath = "Inputs/lines.png"
    let expectedOutputsPath = "ExpectedOutputs"
    static let producedOutputsPath = "Tests/KaleidoscopeEngineTests/ProducedOutputs"
    let producedOutputsPath = KaleidoscopeEngineTests.producedOutputsPath
    
    override class func setUp() {
        var producedDirectoryExists = FileManager.default.fileExists(atPath: projectDirectory + producedOutputsPath)

        if producedDirectoryExists {
            try? FileManager.default.removeItem(atPath: projectDirectory + producedOutputsPath)
            producedDirectoryExists = false
        }

        if !producedDirectoryExists {
            try? FileManager.default.createDirectory(atPath: projectDirectory + producedOutputsPath, withIntermediateDirectories: true)
        }
    }
    
    func testKaleidoscopeCount1() throws {
        XCTAssertTrue(
            try isEqual(expectedImageName: "lines-kaleidoscope-1-0.00rad-tile") { input in
                try kaleidoscopeEngine.kaleidoscope(image: input, count: 1)
            }
        )
    }
    
    func testKaleidoscopeCount3WithTileFillMode() throws {
        XCTAssertTrue(
            try isEqual(expectedImageName: "lines-kaleidoscope-3-0.00rad-tile") { input in
                try kaleidoscopeEngine.kaleidoscope(image: input, count: 3)
            }
        )
    }
    
    func testKaleidoscopeCount3WithAngle() throws {
        XCTAssertTrue(
            try isEqual(expectedImageName: "lines-kaleidoscope-3-0.80rad-tile") { input in
                try kaleidoscopeEngine.kaleidoscope(image: input, count: 3, angle: 0.8)
            }
        )
    }
    
    func testKaleidoscopeCount3WithBlankFillMode() throws {
        XCTAssertTrue(
            try isEqual(expectedImageName: "lines-kaleidoscope-3-0.00rad-blank") { input in
                try kaleidoscopeEngine.kaleidoscope(image: input, count: 3, fillMode: .blank)
            }
        )
    }
    
    func testKaleidoscopeCount5WithAngleAndBlankFillMode() throws {
        XCTAssertTrue(
            try isEqual(expectedImageName: "lines-kaleidoscope-5-0.40rad-blank") { input in
                try kaleidoscopeEngine.kaleidoscope(image: input, count: 5, angle: 0.4, fillMode: .blank)
            }
        )
    }
    
    func testTriangleKaleidoscopeSize200() throws {
        XCTAssertTrue(
            try isEqual(expectedImageName: "lines-triangle-kaleidoscope-200-0.00rad-tile") { input in
                try kaleidoscopeEngine.triangleKaleidoscope(image: input, size: 200)
            }
        )
    }
    
    func testPerformanceTriangleKaleidoscope200Metal() throws {
        let input = try provideInputImage()
        
        measure {
            _ = try! kaleidoscopeEngine.triangleKaleidoscope(image: input, size: 200)
        }
    }
}

extension KaleidoscopeEngineTests {
    
    private func provideInputImage() throws -> CGImage {
        let inputImage = try image(atPath: projectDirectory + inputImagePath)
        return inputImage
    }
    
    private func isEqual(expectedImageName: String, afterPerformingImageOperations block: (CGImage) throws -> CGImage) throws -> Bool {
        let inputImage = try provideInputImage()
        let transformedImage = try block(inputImage)
        
        let producedOutputsPath = projectDirectory + producedOutputsPath + "/\(expectedImageName).png"
        try write(image: transformedImage, toPath: producedOutputsPath)
        let producedOutputImage = try image(atPath: producedOutputsPath)
        
        let expectedImagePath = projectDirectory + expectedOutputsPath + "/\(expectedImageName).png"
        let expectedImage = try image(atPath: expectedImagePath)
        
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let convertedTransformed = convertColorspace(ofImage: producedOutputImage, toColorSpace: colorspace)
        let convertedExpected = convertColorspace(ofImage: expectedImage, toColorSpace: colorspace)
        
        let isEqual = convertedTransformed?.dataProvider?.data == convertedExpected?.dataProvider?.data
        
        if !isEqual {
            print("Image \(String(describing: convertedTransformed)) does not match expected \(String(describing: convertedExpected))")
        }
        
        return isEqual
    }
}
