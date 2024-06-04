//
//  ImageTransformKind.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 28/05/2024.
//

import Foundation
import CoreGraphics
import KaleidoscopeEngine

struct ImageTransformKind {
    
    static func kaleidoscope(_ configuration: KaleidoscopeTransformConfiguration) -> ImageTransformKind {
        ImageTransformKind(configuration: configuration)
    }
    
    static func triangleKaleidoscope(_ configuration: TriangleKaleidoscopeTransformConfiguration) -> ImageTransformKind {
        ImageTransformKind(configuration: configuration)
    }
    
    private let configuration: any ImageTransformable
    
}

extension ImageTransformKind: ImageTransformable {
    
    func transform(kaleidoscopeEngine: KaleidoscopeEngine, image: CGImage) throws -> CGImage {
        try configuration.transform(kaleidoscopeEngine: kaleidoscopeEngine, image: image)
    }
    
}
