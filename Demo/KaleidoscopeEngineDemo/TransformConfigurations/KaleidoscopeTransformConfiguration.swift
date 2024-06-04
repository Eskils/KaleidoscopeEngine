//
//  File.swift
//  
//
//  Created by Eskil Gjerde Sviggum on 25/03/2024.
//

import VideoKaleidoscopeEngine
import KaleidoscopeEngine
import SwiftUI
import Combine

class KaleidoscopeTransformConfiguration: ObservableObject, Positionable {
    
    static var shared = KaleidoscopeTransformConfiguration()
    
    @Published
    var count: Int
    
    @Published
    var angle: Float
    
    @Published
    var position: CGPoint
    
    @Published
    var fillMode: FillMode
    
    @Published
    var angleDeg: Float {
        didSet {
            angle = angleDeg * .pi / 180
        }
    }
    
    /// Initializes a new configuration with default values.
    init() {
        self.count = Self.defaultCount
        self.angle = Self.defaultAngle
        self.position = Self.defaultPosition
        self.fillMode = Self.defaultFillMode
        self.angleDeg = Self.defaultAngle * (180 / .pi)
    }
    
    static var defaultCount = 3
    static var defaultAngle =  Float.zero
    static var defaultPosition = CGPoint(x: 0.5, y: 0.5)
    static var defaultFillMode = FillMode.tile
}

extension KaleidoscopeTransformConfiguration: ImageTransformable, VideoTransformable {
    
    func transform(kaleidoscopeEngine: KaleidoscopeEngine, image: CGImage) throws -> CGImage {
        let count = Float(self.count)
        let angle = self.angle
        let position = self.position
        let fillMode = self.fillMode
        
        return try kaleidoscopeEngine.kaleidoscope(
            image:      image,
            count:      count,
            angle:      angle,
            position:   position,
            fillMode:   fillMode
        )
    }
    
    func transform(videoKaleidoscopeEngine: VideoKaleidoscopeEngine, video: URL, outputURL: URL, progressHandler: ((Float) -> Bool)?, completionHandler: @escaping (Error?) -> Void) {
        let count = Float(self.count)
        let angle = self.angle
        let position = self.position
        let fillMode = self.fillMode
        
        videoKaleidoscopeEngine.kaleidoscope(
            video:              video,
            outputURL:          outputURL,
            count:              count,
            angle:              angle,
            position:           position,
            fillMode:           fillMode,
            progressHandler:    progressHandler,
            completionHandler:  completionHandler
        )
    }
    
}

extension KaleidoscopeTransformConfiguration: ViewInitializable {
    func makeView() -> AnyView {
        AnyView(
            KaleidoscopeTransformConfigurationView(viewModel: self)
        )
    }
    
    var willChangePublisher: ObservableObjectPublisher {
        self.objectWillChange
    }
}
