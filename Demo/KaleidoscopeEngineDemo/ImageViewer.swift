//
//  ImageViewer.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 21/03/2024.
//

import SwiftUI
import CoreImage

struct ImageViewerView: View {
    
    @Binding
    var originalImage: CGImage?
    
    @Binding
    var finalImage: CGImage?
    
    @Binding
    var isRunning: Bool
    
    @Binding
    var imageBounds: CGRect

    @State var shouldUpdateMergedImage = false
    
    @State var imageScaleTemp: CGSize = .zero
    @State var prevPos: CGSize = .zero
    @State var imageRect: CGRect = .zero
    
    @State var hasSetInitialSize: Bool = false
    
    @State var shouldShowOriginalImage: Bool = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(originalImage: Binding<CGImage?>, finalImage: Binding<CGImage?>, isRunning: Binding<Bool>? = nil, imageBounds: Binding<CGRect>) {
        self._originalImage = originalImage
        self._finalImage = finalImage
        self._isRunning = isRunning ?? .constant(false)
        self._imageBounds = imageBounds
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ZStack {
                    if let renderedImage = mergedImage(geo: geo, rect: imageRect, originalImage: originalImage, finalImage: finalImage, shouldShowOriginalImage: shouldShowOriginalImage, isRunning: isRunning) {
                        
                        Image(decorative: renderedImage, scale: 1)
                            .resizable()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .gesture(
                                DragGesture().simultaneously(with: MagnificationGesture())
                                    .onChanged({ shouldTransformImage(gestureResult: $0, geo: geo) } )
                                    .onEnded(commitTransformImage(gestureResult:))
                            )
                    }
                }
                .overlay {
                    if isRunning {
                        ProgressView()
                            .tint(.white)
                            .position(x: imageSplitWidth(geo: geo), y: imageRect.minY + geo.size.height / 2)
                    }
                }
                
                VStack(spacing: 20) {
                    Button(action: { shouldShowOriginalImage = !shouldShowOriginalImage },
                           label: {
                        (shouldShowOriginalImage
                         ? Image(systemName: "square.and.line.vertical.and.square.filled")
                         : Image(systemName: "square.and.line.vertical.and.square"))
                            .resizable()
                            .frame(width: 25, height: 25)
                    })
                    #if !targetEnvironment(macCatalyst)
                    .tint(.white)
                    .buttonStyle(BorderedProminentButtonStyle())
                    .foregroundStyle(Color.accentColor)
                    #endif
                    
                    Button(action: didPressMoveToHome) {
                        Image(systemName: "house")
                            .resizable()
                            .frame(width: 25, height: 25)
                    }
                    #if !targetEnvironment(macCatalyst)
                    .tint(.white)
                    .buttonStyle(BorderedProminentButtonStyle())
                    .foregroundStyle(Color.accentColor)
                    #endif
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
                .padding(.top, 16)
                
            }.background(.ultraThinMaterial)
            .onChange(of: originalImage, perform: { didChange(image: $0, geo: geo) } )
            .onChange(of: geo.size) { _ in
                updateImageBounds(geo: geo)
            }
        }
    }
    
    func imageScale() -> CGFloat {
        let originalSize = originalImage?.width ?? 400
        return imageRect.width / CGFloat(originalSize)
    }
    
    func imageSize() -> CGSize {
        guard let image = originalImage else {
            return CGSize(width: 1, height: 1)
        }
        
        return CGSize(width: image.width, height: image.height)
    }
    
    func getAspectRatio(forImage image: CGImage?) -> CGFloat {
        let size = imageSize()
        
        return size.width / size.height
    }
    
    func imageSplitWidth(geo: GeometryProxy) -> CGFloat {
        let imgStart = imageRect.minX + geo.size.width / 2
        let wid = (imageRect.width / 2) - imgStart
        return max(geo.size.width / 2, (wid / 2))
    }
    
    func mergedImage(geo: GeometryProxy, rect: CGRect, originalImage: CGImage?, finalImage: CGImage?, shouldShowOriginalImage: Bool, isRunning: Bool) -> CGImage? {
        let img: CGImage?
        if shouldShowOriginalImage {
            img = originalImage
        } else {
            img = finalImage
        }
        
        guard let img else{
            return nil
        }
        
        let pos = CGPoint(x: imageRect.minX * imageScale() + (geo.size.width / 2), y: -imageRect.minY * imageScale() + (geo.size.height / 2))
        
        let imageFrame = CGRect(origin: pos, size: rect.size)
        
        do {
            return try renderImageInPlace(img, renderSize: geo.size, imageFrame: imageFrame, minDimension: 1000)
        } catch {
            print("Cannot render image: ", error)
            return nil
        }
    }
    
    func shouldTransformImage(gestureResult: SimultaneousGesture<DragGesture, MagnificationGesture>.Value, geo: GeometryProxy) {
        
        let drag = gestureResult.first?.translation ?? .zero
        let newScale = gestureResult.second ?? 1
        
        updateImageTransform(drag: drag, newScale: newScale, geo: geo)
    }
    
    func updateImageTransform(drag pos: CGSize, newScale: CGFloat, geo: GeometryProxy) {
        imageRect.size.width = imageScaleTemp.width * newScale
        imageRect.size.height = imageScaleTemp.height * newScale
        let scale = imageScale()
        
        imageRect.origin.x += (pos.width - prevPos.width) / scale
        imageRect.origin.y += (pos.height - prevPos.height) / scale
        prevPos = pos
        
        updateImageBounds(geo: geo)
        
        shouldUpdateMergedImage.toggle()
    }
    
    func updateImageBounds(geo: GeometryProxy) {
        let scale = imageScale()
        let globalPos = CGPoint(x: imageRect.minX * scale + (geo.size.width / 2) - imageRect.size.width / 2, y: imageRect.minY * scale + (geo.size.height / 2) - imageRect.size.height / 2)
        let imageFrame = CGRect(origin: globalPos, size: imageRect.size)
        
        imageBounds = imageFrame
    }
    
    func commitTransformImage(gestureResult: SimultaneousGesture<DragGesture, MagnificationGesture>.Value) {
        
        imageScaleTemp = imageRect.size
        prevPos = .zero
        shouldUpdateMergedImage.toggle()
    }
    
    func didChange(image: CGImage?, geo: GeometryProxy) {
        imageRect.size = imageSize()
        imageScaleTemp = imageSize()
        
        updateImageTransform(drag: .zero, newScale: 1, geo: geo)
        
        if !hasSetInitialSize {
            hasSetInitialSize = true
        }
    }
    
    func didPressShowOriginal(showOriginal: Bool) {
        shouldShowOriginalImage = showOriginal
    }
    
    func didPressMoveToHome() {
        imageRect.size = imageSize()
        imageScaleTemp = imageSize()
        prevPos = .zero
        imageRect.origin = .zero
        shouldUpdateMergedImage.toggle()
    }
}
