//
//  ImageTransformable.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 28/05/2024.
//

import Foundation
import CoreGraphics
import KaleidoscopeEngine

protocol ImageTransformable {
    func transform(kaleidoscopeEngine: KaleidoscopeEngine, image: CGImage) throws -> CGImage
}
