//
//  VideoFrameTransformer.swift
//
//
//  Created by Eskil Gjerde Sviggum on 04/04/2024.
//

import Foundation
import CoreGraphics
import CoreVideo

struct VideoFrameTransformer {
    
    typealias TransformHandler = (CVPixelBuffer) throws -> CVPixelBuffer
    
    let videoDescription: VideoDescription
    let frameRate: Float
    let videoAssembler: VideoAssembler
    let numberOfBatches: Int
    let numberOfThreads: Int
    let progressHandler: ((Float) -> Bool)?
    let completionHandler: (Error?) -> Void
    
    private let queue = DispatchQueue(label: "com.skillbreak.VideoKaleidoscopeEngine.VideoFrameTransformer", qos: .default, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    init(videoDescription: VideoDescription, frameRateCap: Float, outputURL: URL, workItems: Int, progressHandler: ((Float) -> Bool)?, completionHandler: @escaping (Error?) -> Void) throws {
        self.videoDescription = videoDescription
        self.frameRate = videoDescription.expectedFrameRate(frameRateCap: frameRateCap)
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        
        guard
            let originalSize = videoDescription.size
        else {
            throw VideoDescription.VideoDescriptionError.assetContainsNoTrackForVideo
        }
        
        let sampleRate = videoDescription.sampleRate ?? 44100
        
        let size: CGSize
        if let renderSize = videoDescription.renderSize {
            let width = renderSize.width
            let height = width * (originalSize.height / originalSize.width)
            size = CGSize(width: width, height: height)
        } else {
            size = originalSize
        }
        
        self.videoAssembler = try VideoAssembler(outputURL: outputURL, width: Int(size.width.rounded()), height: Int(size.height.rounded()), framerate: Int(frameRate), sampleRate: sampleRate, transform: videoDescription.transform)
        
        let numberOfFrames = videoDescription.numberOfFrames(overrideFramerate: frameRate) ?? 0
        self.numberOfBatches = numberOfFrames / workItems
        self.numberOfThreads = workItems
        
        if progressHandler?(0) == false {
            videoAssembler.cancelVideoGeneration()
            completionHandler(VideoFrameTransformerError.cancelled)
            return
        }
    }
    
    func transformVideoFrames(handler: @escaping TransformHandler) {
        do {
        
            let assetReader = try videoDescription.makeReader()
            let frames = try videoDescription.getFrames(assetReader: assetReader, frameRateCap: frameRate)
            
            #if DEBUG
            print("Opening audio track")
            #endif
            
            let audioSamples: VideoDescription.GetAudioHandler?
            do {
                audioSamples = try videoDescription.getAudio(assetReader: assetReader)
            } catch {
                if let error = error as? VideoDescription.VideoDescriptionError,
                   case .assetContainsNoTrackForAudio = error {
                    print("Media has no audio track")
                    audioSamples = nil
                } else {
                    throw error
                }
            }
            
            #if DEBUG
            print("Finished opening audio track, starting to open frames")
            #endif
            
            videoDescription.startReading(reader: assetReader)
            
            DispatchQueue.main.async {
                dispatchUntilEmpty(queue: queue, handler: handler, frames: frames, videoAssembler: videoAssembler) { batchNumber in
                    if let progressHandler {
                        let progress = min(1, Float(batchNumber) / Float(numberOfBatches))
                        return progressHandler(progress)
                    }
                    
                    return true
                } completion: { wasCanceled in
                    if wasCanceled {
                        frames.cancel()
                        audioSamples?.cancel()
                        videoAssembler.cancelVideoGeneration()
                        completionHandler(VideoFrameTransformerError.cancelled)
                        return
                    }
                    
                    print("Finished adding all frames")
                    if let audioSamples {
                        transferAudio(audioSamples: audioSamples, videoAssembler: videoAssembler)
                        print("Finished adding audio")
                    }
                    DispatchQueue.main.async {
                        Task {
                            await videoAssembler.generateVideo()
                            completionHandler(nil)
                        }
                    }
                }
            }
        } catch {
            videoAssembler.cancelVideoGeneration()
            completionHandler(error)
            return
        }
    }
    
    private func transferAudio(audioSamples: VideoDescription.GetAudioHandler, videoAssembler: VideoAssembler) {
        while let sample = audioSamples.next() {
            videoAssembler.addAudio(sample: sample)
        }
    }
    
    @MainActor
    private func dispatchUntilEmpty(queue: DispatchQueue, handler: @escaping TransformHandler, frames: VideoDescription.GetFramesHandler, videoAssembler: VideoAssembler, count: Int = 0, progressHandler: @escaping (Int) -> Bool, completion: @escaping (_ wasCanceled: Bool) -> Void) {
        let buffers = (0..<numberOfThreads).compactMap { _ in frames.next() }
        let isLastRun = buffers.count != numberOfThreads
        var idempotency = 0
        dispatch(queue: queue, handler: handler, buffers: buffers, idempotency: idempotency) { receivedIdempotency, results in
            
            let shouldContinue = progressHandler(count)
            
            if !shouldContinue {
                completion(true)
                return
            }
            
            if receivedIdempotency != idempotency {
                return
            }
            
            idempotency += 1
            
            for result in results {
                if let result {
                    videoAssembler.addFrame(pixelBuffer: result)
                }
            }
            
            if isLastRun {
                completion(false)
            }
            
            if isLastRun {
                return
            }
            
            dispatchUntilEmpty(queue: queue, handler: handler, frames: frames, videoAssembler: videoAssembler, count: count + 1, progressHandler: progressHandler, completion: completion)
        }
    }
    
    private func dispatch(queue: DispatchQueue, handler: @escaping TransformHandler, buffers: [CVPixelBuffer], idempotency: Int, completion: @escaping (Int, [CVPixelBuffer?]) -> Void) {
        let numThreads = min(buffers.count, numberOfThreads)
        var results = [CVPixelBuffer?](repeating: nil, count: numThreads)
        var responses: Int = 0
        
        if numThreads == 0 {
            completion(idempotency, results)
            return
        }
        
        for i in 0..<numThreads {
            let pixelBuffer = buffers[i]
            queue.async {
                defer {
                    DispatchQueue.main.async {
                        responses += 1
                        if responses == numThreads {
                            responses += 1
                            completion(idempotency, results)
                        }
                    }
                }
                
                do {
                    let result = try handler(pixelBuffer)
                    results[i] = result
                } catch {
                    print("Failed to scale and dither frame: \(error)")
                }
            }
        }
        
    }
}

public enum VideoFrameTransformerError: Error {
    case cancelled
}
