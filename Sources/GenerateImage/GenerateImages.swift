//
//  GenerateImages.swift
//
//
//  Created by Eskil Gjerde Sviggum on 18/03/2024.
//

import CoreGraphics
import KaleidoscopeEngine

struct GenerateImages {
    
    let kaleidoscopeEngine = KaleidoscopeEngine()
    
    func imageTransforms(inputImage: CGImage, name: String, transforms: [ImageTransform], outputImages: inout [OutputImage]) {
        for transform in transforms {
            OutputImage
                .from(image: inputImage, named: "\(name)-\(transform.name ?? transform.kind.name)") { input in
                    try transform.kind.transform(kaleidoscopeEngine: kaleidoscopeEngine, image: input)
                }?
                .adding(to: &outputImages)
        }
    }
    
    func imageTransforms(inputImage: CGImage, name: String, outputImages: inout [OutputImage]) {
        // Kaleidoscope 3
        OutputImage
            .from(image: inputImage, named: "\(name)-kaleidoscope-3") { input in
                try kaleidoscopeEngine.kaleidoscope(image: input, count: 3)
            }?
            .adding(to: &outputImages)
        
        // Kaleidoscope 4 - Angle 30 deg
        OutputImage
            .from(image: inputImage, named: "\(name)-kaleidoscope-4") { input in
                try kaleidoscopeEngine.kaleidoscope(image: input, count: 4, angle: .pi / 6)
            }?
            .adding(to: &outputImages)
        
        // Kaleidoscope 5 - Fill Mode blank
        OutputImage
            .from(image: inputImage, named: "\(name)-kaleidoscope-5") { input in
                try kaleidoscopeEngine.kaleidoscope(image: input, count: 5, fillMode: .blank)
            }?
            .adding(to: &outputImages)
    }
    
}
