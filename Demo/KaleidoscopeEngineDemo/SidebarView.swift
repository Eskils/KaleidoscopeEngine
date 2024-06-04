//
//  SidebarView.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 20/03/2024.
//

import SwiftUI

struct SidebarView: View {
    
    @ObservedObject
    var viewModel: KaleidoscopeEngineDemoViewModel
    
    @State
    private var showImagePicker = false
    
    @State
    private var showErrorAlert = false
    
    @State
    private var isExportingVideo = false
    
    @State
    private var exportProgress: Float = 0
    
    @State
    private var shouldContinueExporting = true
    
    @State
    private var errorMessage = "" {
        didSet {
            showErrorAlert = true
        }
    }
    
    @State
    private var fileExport: ExportType? {
        didSet {
            if fileExport != nil {
                showExportSheet = true
            }
        }
    }
    
    @State
    private var showExportSheet = false
    
    @State
    private var videoExportURL: URL?
    
    var body: some View {
        VStack {
            
            if let image = viewModel.imageInput {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke()
                            .foregroundStyle(Color.secondary)
                    )
            }
            
            Button(action: didPressChooseImage) {
                Text("Choose Image or Video")
            }
            
            Divider()
            
            Picker("Kind", selection: $viewModel.kaleidoscopeKind) {
                ForEach(KaleidoscopeKind.allCases, id: \.hashValue) { kind in
                    Text(kind.name)
                        .tag(kind)
                }
            }
            
            viewModel.kaleidoscopeKind.configuration.makeView()
            
            if viewModel.kaleidoscopeKind.configuration is Positionable {
                HStack {
                    Text("Position")
                    Spacer()
                    VStack {
                        Button(viewModel.showTransformOriginSelector ? "Done" : "Set origin") {
                            viewModel.showTransformOriginSelector = !viewModel.showTransformOriginSelector
                        }.animation(.easeInOut, value: viewModel.showTransformOriginSelector)
                        if viewModel.transformOrigin != CGPoint(x: 0.5, y: 0.5) {
                            Button("Reset") {
                                viewModel.transformOrigin = CGPoint(x: 0.5, y: 0.5)
                                viewModel.showTransformOriginSelector = false
                            }
                        }
                    }.animation(.easeInOut, value: viewModel.transformOrigin)
                }
            }
            
            Divider()
            
            Button(action: didPressExport) {
                Text(viewModel.isInVideoMode ? "Export video" : "Export")
            }
            
            if viewModel.isInVideoMode && isExportingVideo {
                let percentNumberFormatter = { (n) -> NumberFormatter in
                    n.numberStyle = .percent
                    n.minimumFractionDigits = 0
                    return n
                }(NumberFormatter())
                
                VStack {
                    HStack {
                        ProgressView(value: exportProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        Text(percentNumberFormatter.string(from: NSNumber(value: exportProgress)) ?? "")
                    }
                    
                    Button(action: didPressCancelExport) {
                        Text("Cancel")
                    }
                }
            }
        }
        .padding()
        .fileImporter(isPresented: $showImagePicker, allowedContentTypes: [.image, .movie, .video], onCompletion: didSelectImage(result:))
        .fileExporter(isPresented: $showExportSheet, document: fileExport, contentType: fileExport?.contentType ?? .png, defaultFilename: fileExport?.name, onCompletion: didExport(result:))
        .onReceive(viewModel.kaleidoscopeKind.configuration.willChangePublisher, perform: { _ in
            performTile()
        })
        .onChange(of: viewModel.kaleidoscopeKind, perform: { _ in
            performTile()
        })
        .onAppear {
            #if canImport(UIKit)
            let image = UIImage(resource: .lines)
            guard let cgImage = image.cgImage else {
                return
            }
            #elseif canImport(AppKit)
            let image = NSImage(resource: .lines)
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return
            }
            #endif
            
            viewModel.handleNewImage(image: cgImage)
        }
    }
    
    private func didPressChooseImage() {
        showImagePicker = true
    }
    
    private func didSelectImage(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try viewModel.handleNewImageOrVideo(withURL: url)
            } catch {
                print(error)
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            print(error)
            errorMessage = error.localizedDescription
        }
    }
    
    private func performTile() {
        do {
            try viewModel.performTiling()
        } catch {
            print(error)
            errorMessage = error.localizedDescription
        }
    }
    
    private func didPressExport() {
        if viewModel.isInVideoMode {
            exportVideo()
        } else {
            exportImage()
        }
    }
    
    private func exportImage() {
        let name = "TiledImage.png"
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let imageURL = temporaryDirectory.appendingPathComponent(name)
        
        do {
            try viewModel.exportImage(toURL: imageURL)
            fileExport = ExportType(name: "KaleidoscopeImage.png", url: imageURL, kind: .image)
        } catch {
            print(error)
            errorMessage = error.localizedDescription
        }
    }
    
    private func exportVideo() {
        let name = "KaleidoscopeVideo.mp4"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            self.videoExportURL = url
            exportVideo(toURL: url)
        } catch {
            print(error)
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func didExport(result: Result<URL, Error>) {
        guard let fileExport else {
            return
        }
        
        switch fileExport.kind {
        case .image:
            didExportImage(result: result)
        case .video:
            didSelectPathForExportedVideo(result: result)
        }
    }
    
    private func exportVideo(toURL url: URL) {
        shouldContinueExporting = true
        exportProgress = 0
        isExportingVideo = true
        
        viewModel.exportVideo(
            toURL: url,
            progressHandler: updateExportProgressAndDetermineContinuation(progress:),
            completionHandler: didExportVideo(error:)
        )
    }
    
    private func didSelectPathForExportedVideo(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Moved video to \(url)")
        case .failure(let error):
            print(error)
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func updateExportProgressAndDetermineContinuation(progress: Float) -> Bool {
        self.exportProgress = progress
        return shouldContinueExporting
    }
    
    private func didExportVideo(error: Error?) {
        isExportingVideo = false
        
        if let error {
            print(error)
            self.errorMessage = error.localizedDescription
        } else if let videoExportURL {
            fileExport = ExportType(name: "KaleidoscopeVideo.mp4", url: videoExportURL, kind: .video)
        } else {
            print("No video export url is set. Should be in temporaryDirectory")
        }
    }
    
    private func didExportImage(result: Result<URL, Error>) {
        if case .failure(let error) = result {
            print(error)
            errorMessage = error.localizedDescription
        }
    }
    
    private func didPressCancelExport() {
        shouldContinueExporting = false
    }
}
