//
//  File.swift
//  
//
//  Created by Eskil Gjerde Sviggum on 25/03/2024.
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
    
    var name: String {
        configuration.name
    }
    
    func transform(kaleidoscopeEngine: KaleidoscopeEngine, image: CGImage) throws -> CGImage {
        try configuration.transform(kaleidoscopeEngine: kaleidoscopeEngine, image: image)
    }
    
}

enum ImageTransformKindDTO: String, Codable {
    case kaleidoscope
    case triangleKaleidoscope
    
    var decodableType: Codable.Type {
        switch self {
        case .kaleidoscope:
            KaleidoscopeTransformConfiguration.self
        case .triangleKaleidoscope:
            TriangleKaleidoscopeTransformConfiguration.self
        }
    }
    
    func toImageTransformKind(configuration: Codable) throws -> ImageTransformKind {
        switch self {
        case .kaleidoscope:
            guard let configuration = configuration as?
                    KaleidoscopeTransformConfiguration else {
                throw DTOError.incorrectConfigurationType
            }
            return .kaleidoscope(configuration)
        case .triangleKaleidoscope:
            guard let configuration = configuration as?
                    TriangleKaleidoscopeTransformConfiguration else {
                throw DTOError.incorrectConfigurationType
            }
            return .triangleKaleidoscope(configuration)
        }
    }
    
    enum DTOError: Error {
        case incorrectConfigurationType
    }
}
