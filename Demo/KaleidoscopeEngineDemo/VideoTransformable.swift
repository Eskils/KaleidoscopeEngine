//
//  VideoTransformable.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 29/05/2024.
//

import Foundation
import VideoKaleidoscopeEngine

protocol VideoTransformable {
    func transform(videoKaleidoscopeEngine: VideoKaleidoscopeEngine, video: URL, outputURL: URL, progressHandler: ((Float)->Bool)?, completionHandler: @escaping (Error?) -> Void)
}
