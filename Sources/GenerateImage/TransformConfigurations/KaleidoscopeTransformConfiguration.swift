//
//  File.swift
//  
//
//  Created by Eskil Gjerde Sviggum on 25/03/2024.
//

import Foundation
import CoreGraphics
import KaleidoscopeEngine

struct KaleidoscopeTransformConfiguration: Codable {
    var count: Int?
    var angle: Float?
    var position: CGPoint?
    var fillMode: FillModeDTO?
    
    static var defaultCount = 3
    static var defaultAngle =  Float.zero
    static var defaultPosition = CGPoint(x: 0.5, y: 0.5)
    static var defaultFillMode = FillModeDTO.tile
}

extension KaleidoscopeTransformConfiguration: ImageTransformable {
    
    var name: String {
        String(
            format: "kaleidoscope-%d-%.2frad-%@-(%.2, %.2)",
            self.count ?? Self.defaultCount,
            self.angle ?? Self.defaultAngle,
            (self.fillMode ?? Self.defaultFillMode).rawValue,
            (self.position ?? Self.defaultPosition).x,
            (self.position ?? Self.defaultPosition).y
        )
    }
    
    func transform(kaleidoscopeEngine: KaleidoscopeEngine, image: CGImage) throws -> CGImage {
        let count = self.count ?? Self.defaultCount
        let angle = self.angle ?? Self.defaultAngle
        let position = self.position ?? Self.defaultPosition
        let fillMode = (self.fillMode ?? Self.defaultFillMode).fillMode
        
        return try kaleidoscopeEngine.kaleidoscope(
            image: image,
            count: Float(count),
            angle: angle,
            position: position,
            fillMode: fillMode
        )
    }
    
}
