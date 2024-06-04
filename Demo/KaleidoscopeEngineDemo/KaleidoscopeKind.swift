//
//  KaleidoscopeKind.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 28/05/2024.
//

import Foundation

enum KaleidoscopeKind: CaseIterable {
    case kaleidoscope
    case triangleKaleidoscope
    
    var name: String {
        switch self {
        case .kaleidoscope:
            "Kaleidoscope"
        case .triangleKaleidoscope:
            "Triangle Kaleidoscope"
        }
    }
    
    var configuration: ImageTransformable & VideoTransformable & ViewInitializable {
        switch self {
        case .kaleidoscope:
            KaleidoscopeTransformConfiguration.shared
        case .triangleKaleidoscope:
            TriangleKaleidoscopeTransformConfiguration.shared
        }
    }
}
