//
//  RenderImageInPlace.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 21/03/2024.
//

import CoreGraphics
import CoreImage

func renderImageInPlace(_ image: CGImage, renderSize: CGSize, imageFrame: CGRect, minDimension dMinDimension: CGFloat) throws -> CGImage {
    
    let minDimension = Float(dMinDimension)
    let originalSize = SIMD4<Float>(Float(imageFrame.width), Float(imageFrame.height), Float(renderSize.width), Float(renderSize.height))
    
    let scale = if originalSize.x <= originalSize.x {
        min(minDimension / originalSize.x, 1)
    } else {
        min(minDimension / originalSize.y, 1)
    }
    let dScale = Double(scale)
    
    let renderSizes = scale * originalSize
    let scaledImageSize = CGSize(width: Double(renderSizes.x), height: Double(renderSizes.y))
    let scaledRenderSizeWidth = Int(renderSizes.z)
    let scaledRenderSizeHeight = Int(renderSizes.w)
    
    let frame = CGRect(x: dScale * (imageFrame.minX - imageFrame.width / 2), y: dScale * (imageFrame.minY - imageFrame.height / 2), width: scaledImageSize.width, height: scaledImageSize.height)
    let renderScale = imageFrame.width / renderSize.width
    
    guard let context = CGContext(data: nil, width: scaledRenderSizeWidth, height: scaledRenderSizeHeight, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        throw RenderImageInPlaceError.cannotMakeCGContext
    }
    
    context.interpolationQuality = interpolationQuality(forScale: renderScale)
    context.draw(image, in: frame, byTiling: false)
    
    guard let image = context.makeImage() else {
        throw RenderImageInPlaceError.cannotMakeImage
    }
    
    return image
}

func resize(cgImage: CGImage, minDimension dMinDimension: CGFloat) throws -> CGImage {
    let minDimension = Float(dMinDimension)
    let originalSize = SIMD2<Float>(Float(cgImage.width), Float(cgImage.height))
    
    let scale = if originalSize.x <= originalSize.x {
        min(minDimension / originalSize.x, 1)
    } else {
        min(minDimension / originalSize.y, 1)
    }
    
    let size = scale * originalSize
    let width = Int(size.x)
    let height = Int(size.y)
    
    let frame = CGRect(x: 0, y: 0, width: width, height: height)
    
    guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        throw RenderImageInPlaceError.cannotMakeCGContext
    }
    
    context.draw(cgImage, in: frame, byTiling: false)
    
    guard let image = context.makeImage() else {
        throw RenderImageInPlaceError.cannotMakeImage
    }
    
    return image
}

private func interpolationQuality(forScale scale: Double) -> CGInterpolationQuality {
    if scale > 3 {
        return .none
    }
    
    if scale > 2 {
        return .low
    }
    
    if scale > 1 {
        return .medium
    }
    
    if scale <= 1 {
        return .high
    }
    
    return .default
}

enum RenderImageInPlaceError: Error {
    case cannotMakeCGContext
    case cannotMakeImage
}
