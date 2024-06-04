//
//  KaleidoscopeEngineDemoViewModel.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 20/03/2024.
//

import Foundation
import CoreGraphics
import ImageIO
import KaleidoscopeEngine
import VideoKaleidoscopeEngine
import UniformTypeIdentifiers
import AVFoundation

final class KaleidoscopeEngineDemoViewModel: ObservableObject {
    
    private let kaleidoscopeEngine = KaleidoscopeEngine()
    
    @Published
    var imageInput: CGImage?

    @Published
    var smallImageInput: CGImage?
    
    @Published
    var imageOutput: CGImage?
    
    @Published
    var kaleidoscopeKind: KaleidoscopeKind = .kaleidoscope
    
    @Published
    var transformOrigin: CGPoint = CGPoint(x: 0.5, y: 0.5)
    
    @Published
    var showTransformOriginSelector: Bool = false
    
    @Published
    var isInVideoMode: Bool = false
    
    private var videoURL: URL?
    
    func performTiling(useSmallImage: Bool = false) throws {
        guard let imageInput = imageInput(useSmallImage: useSmallImage) else {
            return
        }
        
        let imageOutput = try kaleidoscopeKind.configuration.transform(kaleidoscopeEngine: kaleidoscopeEngine, image: imageInput)
        self.imageOutput = imageOutput
    }
    
    func imageInput(useSmallImage: Bool = false) -> CGImage? {
        useSmallImage 
            ? (smallImageInput ?? imageInput)
            : imageInput
    }
    
    func handleNewImageOrVideo(withURL url: URL) throws {
        let fileExtension = url.pathExtension
        guard
            let fileType = UTType(filenameExtension: fileExtension)
        else {
            throw ViewModelError.invalidFileType
        }
        
        if fileType.conforms(to: .image) {
            try handleNewImage(withURL: url)
        } else if fileType.conforms(to: .movie) || fileType.conforms(to: .video) {
            try handleNewVideo(withURL: url)
        } else {
            throw ViewModelError.unhandledFileType
        }
    }
    
    func handleNewImage(withURL url: URL) throws {
        let imageData = try Data(contentsOf: url)
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            throw ViewModelError.cannotMakeImageSource
        }
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ViewModelError.cannotMakeCGImageFromData
        }
        
        self.isInVideoMode = false
        
        handleNewImage(image: cgImage)
    }
    
    func handleNewVideo(withURL url: URL) throws {
        let asset = AVAsset(url: url)
        
        guard !asset.tracks(withMediaType: .video).isEmpty else {
            throw ViewModelError.fileDoesNotHaveATrackForVideo
        }
        
        self.isInVideoMode = true
        self.videoURL = url
        
        let previewImage = try makePreviewImage(forVideoAsset: asset)
        handleNewImage(image: previewImage)
    }
    
    func handleNewImage(image cgImage: CGImage) {
        self.imageInput = cgImage
        do {
            self.smallImageInput = try resize(cgImage: cgImage, minDimension: 1000)
        } catch {
            print("Cannot resize image: ", error)
        }
        
        try? performTiling()
    }
    
    func exportImage(toURL url: URL) throws {
        try performTiling()
        
        guard let image = imageOutput else {
            return
        }
        
        let data = NSMutableData()
        guard
            let imageDestination = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil)
        else {
            throw ViewModelError.cannotMakeImageDestination
        }
        
        CGImageDestinationAddImage(imageDestination, image, nil)
        
        CGImageDestinationFinalize(imageDestination)
        
        data.write(toFile: url.path, atomically: true)
    }
    
    func exportVideo(toURL url: URL, progressHandler: @escaping (Float) -> Bool, completionHandler: @escaping (Error?) -> Void) {
        guard let videoURL else {
            completionHandler(ViewModelError.noVideoToExport)
            return
        }
        
        let videoKaleidoscopeEngine = VideoKaleidoscopeEngine(frameRate: 30)
        
        kaleidoscopeKind.configuration.transform(
            videoKaleidoscopeEngine:    videoKaleidoscopeEngine,
            video:                      videoURL,
            outputURL:                  url,
            progressHandler:            progressHandler,
            completionHandler:          completionHandler
        )
    }
    
    private func makePreviewImage(forVideoAsset asset: AVAsset) throws -> CGImage {
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        let time = CMTime.zero
        
        let image = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
        return image
    }
    
    enum ViewModelError: Error {
        case cannotMakeImageSource
        case cannotMakeCGImageFromData
        case cannotMakeImageDestination
        case invalidFileType
        case unhandledFileType
        case fileDoesNotHaveATrackForVideo
        case noVideoToExport
    }
    
}
