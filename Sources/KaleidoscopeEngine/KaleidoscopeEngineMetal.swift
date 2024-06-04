//
//  KaleidoscopeEngineMetal.swift
//
//
//  Created by Eskil Gjerde Sviggum on 18/03/2024.
//

import CoreGraphics
import Metal
import Accelerate.vImage
import MetalKit
import CoreImage

class KaleidoscopeEngineMetal {
    
    private lazy var device = MTLCreateSystemDefaultDevice()
    
    #if DEBUG
    private let triggerDebugCapture = false
    #endif
    
    // MARK: - Functions
    
    private lazy var kaleidoscopeFunction = tryPrecompileMetalFunction(withName: "kaleidoscope")
    private lazy var triangleKaleidoscopeNoRotateFunction = tryPrecompileMetalFunction(withName: "triangleKaleidoscopeSpecialized")
    private lazy var triangleKaleidoscopeRotateFunction = tryPrecompileMetalFunction(withName: "triangleKaleidoscopeSpecializedWithRotation")
    
    private var textureIn: MTLTexture?
    private var textureOut: MTLTexture?
    
    let ciContext = CIContext()
    
    private func tryPrecompileMetalFunction(withName name: String) -> MetalFunction? {
        device.flatMap {
            do {
                return try MetalFunction.precompileMetalFunction(withName: name, device: $0)
            } catch {
                #if DEBUG
                print("Cannot precompile metal function with error: \(error)")
                #endif
                return nil
            }
        }
    }
    
    lazy var floatBuffer1 = device?.makeBuffer(length: MemoryLayout<Float>.size)
    lazy var floatBuffer2 = device?.makeBuffer(length: MemoryLayout<Float>.size)
    lazy var float2Buffer1 = device?.makeBuffer(length: 2 * MemoryLayout<Float>.size)
    lazy var uint8Buffer1 = device?.makeBuffer(length: MemoryLayout<Int32>.size)
    
    func kaleidoscope(image: CGImage, count: Float, angle: Float, position: CGPoint, fillMode: FillMode) throws -> CGImage {
        guard let countBuffer = floatBuffer1, let angleBuffer = floatBuffer2, let fillModeBuffer = uint8Buffer1,
              let normOffsetBuffer = float2Buffer1 
        else {
            throw MetalEngineError.cannotCreateDevice
        }
        
        return try genericRunMetal(kaleidoscopeFunction, image: image) { device, encoder in
            // Count
            countBuffer.contents().assumingMemoryBound(to: Float.self).pointee = count
            encoder.setBuffer(countBuffer, offset: 0, index: 0)
            
            // Angle
            angleBuffer.contents().assumingMemoryBound(to: Float.self).pointee = angle
            encoder.setBuffer(angleBuffer, offset: 0, index: 1)
            
            // Fill Mode
            fillModeBuffer.contents().assumingMemoryBound(to: Int32.self).pointee = Int32(fillMode.rawValue)
            encoder.setBuffer(fillModeBuffer, offset: 0, index: 2)
            
            // Normalized Offset / Position
            let normOffset = SIMD2<Float>(x: Float(position.x), y: Float(position.y))
            normOffsetBuffer.contents().assumingMemoryBound(to: SIMD2<Float>.self).pointee = normOffset
            encoder.setBuffer(normOffsetBuffer, offset: 0, index: 3)
        }
    }
    
    func triangleKaleidoscopeNoAngle(image: CGImage, size: Float, decay: Float, position: CGPoint = CGPoint(x: 0.5, y: 0.5)) throws -> CGImage {
        guard let sizeBuffer = floatBuffer1, let decayBuffer = floatBuffer2, let normOffsetBuffer = float2Buffer1 else {
            throw MetalEngineError.cannotCreateDevice
        }
        
        return try genericRunMetal(triangleKaleidoscopeNoRotateFunction, image: image) { device, encoder in
            // Size
            sizeBuffer.contents().assumingMemoryBound(to: Float.self).pointee = size
            encoder.setBuffer(sizeBuffer, offset: 0, index: 0)
            
            // Decay
            decayBuffer.contents().assumingMemoryBound(to: Float.self).pointee = decay
            encoder.setBuffer(decayBuffer, offset: 0, index: 1)
            
            // Normalized Offset / Position
            let normOffset = SIMD2<Float>(x: Float(position.x), y: Float(position.y))
            normOffsetBuffer.contents().assumingMemoryBound(to: SIMD2<Float>.self).pointee = normOffset
            encoder.setBuffer(normOffsetBuffer, offset: 0, index: 2)
        }
    }
    
//    func triangleKaleidoscopeAngle(image: CGImage, size: Float, angle: Float) throws -> CGImage {
//        guard let sizeBuffer = floatBuffer1, let angleBuffer = floatBuffer2, let fillModeBuffer = uint8Buffer1 else {
//            throw MetalEngineError.cannotCreateDevice
//        }
//        
//        return try genericRunMetal(triangleKaleidoscopeRotateFunction, image: image) { device, encoder in
//            // Size
//            sizeBuffer.contents().assumingMemoryBound(to: Float.self).pointee = size
//            encoder.setBuffer(sizeBuffer, offset: 0, index: 0)
//            
//            // Angle
//            angleBuffer.contents().assumingMemoryBound(to: Float.self).pointee = angle
//            encoder.setBuffer(angleBuffer, offset: 0, index: 1)
//        }
//    }
    
    private func genericRunMetal(_ function: MetalFunction?, image: CGImage, bufferConfigurationHandler: @escaping (MTLDevice, MTLComputeCommandEncoder) -> Void) throws -> CGImage {
        guard let device else {
            throw MetalEngineError.cannotCreateDevice
        }
        
        guard
            let textureIn = makeInputTexture(withImage: image),
            let textureOut = makeOutputTexture(forImage: image)
        else {
            throw MetalEngineError.cannotMakeTexture
        }
        
        #if DEBUG
        if triggerDebugCapture {
            triggerProgrammaticCapture(device: device)
        }
        #endif
        
        guard let function else {
            throw MetalEngineError.cannotPrecompileMetalFunction
        }
        
        let width = image.width
        let height = image.height
        
        try function.perform(
            numWidth: width,
            numHeight: height
        ) { (commandEncoder, threadgroups) in
            commandEncoder.setTexture(textureIn, index: 0)
            commandEncoder.setTexture(textureOut, index: 1)
            
            bufferConfigurationHandler(device, commandEncoder)
        }
        
        guard let resultImage = makeImage(fromTexture: textureOut, width: width, height: height) else {
            throw MetalEngineError.cannotMakeFinalImage
        }
        
        return resultImage
    }
    
    private func makeInputTexture(withImage image: CGImage, allowResusingTexture: Bool = true) -> MTLTexture? {
        guard let device else {
            return nil
        }
        
        let textureLoader = MTKTextureLoader(device: device)
        guard let texture = try? textureLoader.newTexture(cgImage: image, options: [.textureUsage: MTLTextureUsage.shaderRead.rawValue, .textureStorageMode: MTLStorageMode.shared.rawValue, .SRGB: false]) else {
            return nil
        }
        
        return texture
    }
    
    private func makeOutputTexture(forImage image: CGImage, allowResusingTexture: Bool = true) -> MTLTexture? {
        guard let device else {
            return nil
        }
        
        let width = image.width
        let height = image.height
        
        let texture: MTLTexture?
        if let textureOut, textureOut.width == width, textureOut.height == height, allowResusingTexture {
            texture = textureOut
        } else {
            texture = MetalFunction.makeTexture(width: width, height: height, device: device, usage: [.shaderRead, .shaderWrite], storageMode: .shared)
        }
        
        return texture
    }
    
    private func makeImage(fromTexture texture: MTLTexture, width: Int, height: Int) -> CGImage? {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        guard
            let context,
            let imageBytes = context.data
        else {
            return nil
        }
        
        texture.getBytes(
            imageBytes,
            bytesPerRow: context.bytesPerRow,
            from: MTLRegion(
                origin: MTLOrigin(x: 0, y: 0, z: 0),
                size: MTLSize(width: width, height: height, depth: 1)
            ),
            mipmapLevel: 0
        )
        
        return context.makeImage()
    }
    
    private func triggerProgrammaticCapture(device: MTLDevice) {
        let captureManager = MTLCaptureManager.shared()
        let captureDescriptor = MTLCaptureDescriptor()
        captureDescriptor.captureObject = self.device
        captureDescriptor.destination = .developerTools
        do {
            try captureManager.startCapture(with: captureDescriptor)
        } catch {
            fatalError("error when trying to capture: \(error)")
        }
    }
    
    enum MetalEngineError: Error {
        case cannotCreateDevice
        case cannotPrecompileMetalFunction
        case cannotMakeTexture
        case cannotMakeFinalImage
    }
    
}
