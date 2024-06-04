//
//  FillMode.swift
//
//
//  Created by Eskil Gjerde Sviggum on 20/03/2024.
//

import Foundation

/// The fill mode determines how to deal with filling the edges where the tiling would go outside the image.
public enum FillMode: Int, CaseIterable {
    /// Tile the image to not leave any blank edges
    case tile = 0
    
    /// Leave the edges blank
    case blank = 1
    
    /// The default fill mode. Resolves to `.tile`.
    public static let standard: FillMode = .tile
    
    public var title: String {
        switch self {
        case .tile:
            NSLocalizedString("Tile", comment: "KaleidoscopeEngine FillMode title")
        case .blank:
            NSLocalizedString("Blank", comment: "KaleidoscopeEngine FillMode title")
        }
    }
}
