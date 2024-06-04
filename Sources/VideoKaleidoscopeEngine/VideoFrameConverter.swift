//
//  VideoFrameConverter.swift
//
//
//  Created by Eskil Gjerde Sviggum on 13/05/2024.
//

import CoreGraphics
import VideoToolbox
import CoreVideo

struct VideoFrameConverter {
    
    private init() {}
    
    static func cgImageToCVPixelBuffer(_ cgImage: CGImage) throws -> CVPixelBuffer {
        let width = cgImage.width
        let height = cgImage.height
        
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )
        
        guard
            let pixelBuffer,
            status == kCVReturnSuccess
        else {
            throw ToCVPixelBufferError.cannotCreateCVPixelBuffer(status: status)
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw ToCVPixelBufferError.cannotGetCVPixelBufferBaseAddress
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        guard 
            let context = CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            throw ToCVPixelBufferError.cannotCreateCGContext
        }
        
        context.draw(
            cgImage,
            in: CGRect(x: 0, y: 0, width: width, height: height),
            byTiling: false
        )
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        
        return pixelBuffer
    }
    
    static func cvPixelBufferToCGImage(_ pixelBuffer: CVPixelBuffer) throws -> CGImage {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw ToCVPixelBufferError.cannotGetCVPixelBufferBaseAddress
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        guard
            let context = CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            throw ToCVPixelBufferError.cannotCreateCGContext
        }
        
        guard let image = context.makeImage() else {
            throw ToCGImageError.cannotCreateCGImage
        }
        
        return image
    }
    
    enum ToCGImageError: Error {
        case cannotCreateCGImageFromPixelBuffer(status: OSStatus)
        case cannotCreateCGImage
    }
    
    enum ToCVPixelBufferError: Error {
        case cannotCreateCVPixelBuffer(status: OSStatus)
        case cannotGetCVPixelBufferBaseAddress
        case cannotCreateCGContext
    }
    
}
