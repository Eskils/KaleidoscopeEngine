//
//  VideoAssembler.swift
//
//
//  Created by Eskil Gjerde Sviggum on 04/04/2024.
//

import AVFoundation

class VideoAssembler {
    
    let width: Int
    let height: Int
    let framerate: Int
    let sampleRate: Int
    
    private let assetWriter: AVAssetWriter
    private let videoInput: AVAssetWriterInput
    private let videoInputAdaptor: AVAssetWriterInputPixelBufferAdaptor
    private let audioInput: AVAssetWriterInput
    
    private var framecount: Int = 0
    
    init(outputURL: URL, width: Int, height: Int, framerate: Int, sampleRate: Int, transform: CGAffineTransform? = nil) throws {
        self.width = width
        self.height = height
        self.framerate = framerate
        self.sampleRate = sampleRate
        
        self.assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey : width,
            AVVideoHeightKey: height
        ] as [String : Any]
        
        let audioSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 160_000
        ] as [String : Any]
        
        self.videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        if let transform {
            videoInput.transform = transform
        }
        self.videoInputAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: nil)
        
        self.audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        
        videoInput.expectsMediaDataInRealTime = true
        
        try startVideoAssetWriter()
    }
    
    private func startVideoAssetWriter() throws {
        guard assetWriter.canAdd(videoInput) else {
            throw VideoAssemblerError.cannotAddVideoAssetWriterInput
        }
        
        guard assetWriter.canAdd(audioInput) else {
            throw VideoAssemblerError.cannotAddAudioAssetWriterInput
        }
        
        assetWriter.add(videoInput)
        assetWriter.add(audioInput)
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMTime.zero)
    }
    
    func addFrame(pixelBuffer: CVPixelBuffer) {
        let frametime = CMTimeMake(value: Int64(framecount), timescale: Int32(framerate))
        framecount += 1
        
        while !videoInput.isReadyForMoreMediaData {}
        self.videoInputAdaptor.append(pixelBuffer, withPresentationTime: frametime)
    }
    
    func addAudio(sample: CMSampleBuffer) {
        while !audioInput.isReadyForMoreMediaData {}
        audioInput.append(sample)
    }
    
    func generateVideo() async {
        while !videoInput.isReadyForMoreMediaData {}
        videoInput.markAsFinished()
        audioInput.markAsFinished()
        await assetWriter.finishWriting()
    }
    
    func cancelVideoGeneration() {
        assetWriter.cancelWriting()
    }
    
    enum VideoAssemblerError: Error {
        case cannotAddVideoAssetWriterInput
        case cannotAddAudioAssetWriterInput
    }
    
}
