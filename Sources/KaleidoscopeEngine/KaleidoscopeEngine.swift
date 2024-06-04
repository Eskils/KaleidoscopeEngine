import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins

public struct KaleidoscopeEngine {
    
    private let metalEngine = KaleidoscopeEngineMetal()
    
    public init() {}
    
    /// Generates a kaleidoscope tiling pattern from the input image.
    /// - Parameters:
    ///   - image: The image to be used for tiling
    ///   - count: The number of mirrors.
    ///   - angle: The angle the image should be rotated by before tiling. In radians. Default is 0.
    ///   - position: The center of reflection. Default is image center
    ///   - fillMode: How to deal with filling the edges where the tiling would go outside the image. Default is `.tile`
    /// - Returns: The tiled kaleidoscope image.
    public func kaleidoscope(image: CGImage, count: Float, angle: Float = 0, position: CGPoint = CGPoint(x: 0.5, y: 0.5), fillMode: FillMode = .standard) throws -> CGImage {
        return try metalEngine.kaleidoscope(
            image: image,
            count: count,
            angle: angle,
            position: position,
            fillMode: fillMode
        )
    }
    
    /// Generates a triangle kaleidoscope tiling pattern from the input image.
    /// - Parameters:
    ///   - image: The image to be used for tiling
    ///   - size: The length of each mirror / size of the triangle.
    ///   - decay: How much each reflection decreases in brightness. Default is 0
    ///   - position: The center of reflection. Default is image center
    /// - Returns: The tiled triangle kaleidoscope image.
    public func triangleKaleidoscope(image: CGImage, size: Float, decay: Float = 0, position: CGPoint = CGPoint(x: 0.5, y: 0.5)) throws -> CGImage {
        return try metalEngine.triangleKaleidoscopeNoAngle(
            image: image,
            size: size,
            decay: decay,
            position: position
        )
    }
    
}
