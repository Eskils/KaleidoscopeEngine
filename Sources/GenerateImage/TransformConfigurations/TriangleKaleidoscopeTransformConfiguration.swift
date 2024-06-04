//
//  File.swift
//  
//
//  Created by Eskil Gjerde Sviggum on 04/04/2024.
//

import Foundation
import CoreGraphics
import KaleidoscopeEngine

struct TriangleKaleidoscopeTransformConfiguration: Codable {
    var size: Int?
    var decay: Float?
    var position: CGPoint?
    
    static var defaultSize = 200
    static var defaultDecay =  Float.zero
    static var defaultPosition = CGPoint(x: 0.5, y: 0.5)
}

extension TriangleKaleidoscopeTransformConfiguration: ImageTransformable {
    
    var name: String {
        String(
            format: "triangle-kaleidoscope-%d-%.2f-(%.2f, %.2f)",
            self.size ?? Self.defaultSize,
            self.decay ?? Self.defaultDecay,
            (self.position ?? Self.defaultPosition).x,
            (self.position ?? Self.defaultPosition).y
        )
    }
    
    func transform(kaleidoscopeEngine: KaleidoscopeEngine, image: CGImage) throws -> CGImage {
        let size = self.size ?? Self.defaultSize
        let decay = self.decay ?? Self.defaultDecay
        let position = self.position ?? Self.defaultPosition
        
        return try kaleidoscopeEngine.triangleKaleidoscope(
            image: image,
            size: Float(size),
            decay: decay,
            position: position
        )
    }
    
}
