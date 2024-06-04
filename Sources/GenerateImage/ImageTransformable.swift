//
//  ImageTransformable.swift
//
//
//  Created by Eskil Gjerde Sviggum on 13/05/2024.
//

import Foundation
import CoreGraphics
import KaleidoscopeEngine

protocol ImageTransformable {
    var name: String { get }
    func transform(kaleidoscopeEngine: KaleidoscopeEngine, image: CGImage) throws -> CGImage
}
