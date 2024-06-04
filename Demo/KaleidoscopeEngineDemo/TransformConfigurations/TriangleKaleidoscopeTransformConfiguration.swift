//
//  File.swift
//  
//
//  Created by Eskil Gjerde Sviggum on 04/04/2024.
//

import KaleidoscopeEngine
import VideoKaleidoscopeEngine
import SwiftUI
import Combine

class TriangleKaleidoscopeTransformConfiguration: ObservableObject, Positionable {
    
    static var shared = TriangleKaleidoscopeTransformConfiguration()
    
    @Published
    var size: Int
    
    @Published
    var decay: Float
    
    @Published
    var position: CGPoint
    
    /// Initializes a new configuration with default values.
    init() {
        self.size = Self.defaultSize
        self.decay = Self.defaultDecay
        self.position = Self.defaultPosition
    }
    
    static var defaultSize = 200
    static var defaultDecay =  Float.zero
    static var defaultPosition = CGPoint(x: 0.5, y: 0.5)
}

extension TriangleKaleidoscopeTransformConfiguration: ImageTransformable, VideoTransformable {
    
    func transform(kaleidoscopeEngine: KaleidoscopeEngine, image: CGImage) throws -> CGImage {
        let size = Float(self.size)
        let decay = self.decay
        let position = self.position
        
        return try kaleidoscopeEngine.triangleKaleidoscope(
            image:      image,
            size:       size,
            decay:      decay,
            position:   position
        )
    }
    
    func transform(videoKaleidoscopeEngine: VideoKaleidoscopeEngine, video: URL, outputURL: URL, progressHandler: ((Float)->Bool)?, completionHandler: @escaping (Error?) -> Void) {
        let size = Float(self.size)
        let decay = self.decay
        let position = self.position
        
        videoKaleidoscopeEngine.triangleKaleidoscope(
            video:              video,
            outputURL:          outputURL,
            size:               size,
            decay:              decay,
            position:           position,
            progressHandler:    progressHandler,
            completionHandler:  completionHandler
        )
    }
    
}

extension TriangleKaleidoscopeTransformConfiguration: ViewInitializable {
    func makeView() -> AnyView {
        return AnyView(
            TriangleKaleidoscopeTransformConfigurationView(viewModel: self)
        )
    }
    
    var willChangePublisher: ObservableObjectPublisher {
        self.objectWillChange
    }
}
