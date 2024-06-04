//
//  VideoKaleidoscopeEngine.swift
//
//
//  Created by Eskil Gjerde Sviggum on 04/04/2024.
//

import Foundation
import CoreImage
import KaleidoscopeEngine

public struct VideoKaleidoscopeEngine {
    
    public private(set) var frameRate: Float = 30
    
    /// Number of frames to process concurrently (per batch). Default is 5. A greater number might be faster, but will use more memory.
    public var numberOfConcurrentFrames = 5
    
    private let kaleidoscopeEngine = KaleidoscopeEngine()
    
    /// Provide the frame rate for your resulting video.
    /// The final frame rate is less than or equal to the specified value.
    /// If you specify 30, and the imported video has a framerate of 24 frames per second,
    /// Then the resulting video will have a framerate of 24 fps.
    public init(frameRate: Int) {
        self.frameRate = Float(frameRate)
    }
    
    /// Generates a kaleidoscope tiling pattern from the input video.
    /// - Parameters:
    ///   - video: URL to the video to be used for tiling
    ///   - outputURL: Where to write the resulting video on disk.
    ///   - count: The number of mirrors.
    ///   - angle: The angle the image should be rotated by before tiling. In radians. Default is 0.
    ///   - position: The center of reflection. Default is image center
    ///   - fillMode: How to deal with filling the edges where the tiling would go outside the image. Default is `.tile`
    ///   - progressHandler: A block to give updates on progress and whether to continue.
    ///   - completionHandler: A block which is called upon finish or error.
    /// - Returns: The tiled kaleidoscope video.
    public func kaleidoscope(video: URL, outputURL: URL, count: Float, angle: Float = 0, position: CGPoint = CGPoint(x: 0.5, y: 0.5), fillMode: FillMode = .standard, progressHandler: ((Float) -> Bool)? = nil, completionHandler: @escaping (Error?) -> Void) {
        genericVideoTransform(
            video: video,
            outputURL: outputURL,
            progressHandler: progressHandler,
            completionHandler: completionHandler
        ) { frame in
            try kaleidoscopeEngine.kaleidoscope(
                image: frame,
                count: count,
                angle: angle,
                position: position,
                fillMode: fillMode
            )
        }
    }
    
    /// Generates a triangle kaleidoscope tiling pattern from the input video.
    /// - Parameters:
    ///   - video: URL to the video to be used for tiling
    ///   - outputURL: Where to write the resulting video on disk.
    ///   - size: The length of each mirror / size of the triangle.
    ///   - decay: How much each reflection decreases in brightness. Default is 0
    ///   - position: The center of reflection. Default is image center.
    ///   - progressHandler: A block to give updates on progress and whether to continue.
    ///   - completionHandler: A block which is called upon finish or error.
    /// - Returns: The tiled triangle kaleidoscope video.
    public func triangleKaleidoscope(video: URL, outputURL: URL, size: Float, decay: Float = 0, position: CGPoint = CGPoint(x: 0.5, y: 0.5), progressHandler: ((Float) -> Bool)? = nil, completionHandler: @escaping (Error?) -> Void) {
        genericVideoTransform(
            video: video,
            outputURL: outputURL,
            progressHandler: progressHandler,
            completionHandler: completionHandler
        ) { frame in
            try kaleidoscopeEngine.triangleKaleidoscope(
                image: frame,
                size: size,
                decay: decay,
                position: position
            )
        }
    }
    
    private func genericVideoTransform(video: URL, outputURL: URL, progressHandler: ((Float) -> Bool)?, completionHandler: @escaping (Error?) -> Void, transformHandler: @escaping (CGImage) throws -> CGImage) {
        let videoDescription = VideoDescription(url: video)
        
        do {
            let videoFrameTransformer = try VideoFrameTransformer(
                videoDescription: videoDescription,
                frameRateCap: frameRate,
                outputURL: outputURL,
                workItems: numberOfConcurrentFrames,
                progressHandler: progressHandler,
                completionHandler: completionHandler
            )
            
            videoFrameTransformer.transformVideoFrames { pixelBuffer in
                let cgImage = try VideoFrameConverter.cvPixelBufferToCGImage(pixelBuffer)
                let transformedFrame = try transformHandler(cgImage)
                return try VideoFrameConverter.cgImageToCVPixelBuffer(transformedFrame)
            }
        } catch {
            completionHandler(error)
        }
    }
    
}
