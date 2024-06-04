//
//  FillModeDTO.swift
//
//
//  Created by Eskil Gjerde Sviggum on 04/04/2024.
//

import Foundation
import KaleidoscopeEngine

enum FillModeDTO: String, Codable {
    case tile, blank
    
    var fillMode: FillMode {
        switch self {
        case .tile: .tile
        case .blank: .blank
        }
    }
}
