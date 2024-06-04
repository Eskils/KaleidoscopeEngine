//
//  Positionable.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 28/05/2024.
//

import CoreGraphics

protocol Positionable: AnyObject {
    var position: CGPoint { get set }
}
