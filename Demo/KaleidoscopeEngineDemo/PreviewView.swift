//
//  PreviewView.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 20/03/2024.
//

import SwiftUI

struct PreviewView: View {
    
    @ObservedObject
    var viewModel: KaleidoscopeEngineDemoViewModel
    
    @State
    var imageBounds: CGRect = .zero
    
    @State
    var transformOriginPosition = CGPoint.zero
    
    @State
    var transformOriginPositionTemp = CGPoint.zero
    
    var body: some View {
        ZStack {
            ImageViewerView(
                originalImage: $viewModel.imageInput,
                finalImage: $viewModel.imageOutput,
                imageBounds: $imageBounds
            )
            
            if viewModel.showTransformOriginSelector {
                Circle()
                    .fill()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.accentColor.opacity(0.8))
                    .overlay(
                        Circle()
                            .stroke(lineWidth: 2)
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color.white)
                    )
                    .shadow(radius: 1)
                    .position(transformOriginPosition)
                    .gesture(DragGesture()
                        .onChanged(didChangeTranformOrigin(value:))
                    )
            }
        }
        .onChange(of: viewModel.showTransformOriginSelector, perform: { _ in
            transformOriginPosition = convertTransformOriginToImageBoundedPosition(viewModel.transformOrigin)
        })
        .onChange(of: imageBounds, perform: { _ in
            transformOriginPosition = convertTransformOriginToImageBoundedPosition(viewModel.transformOrigin)
        })
        .onChange(of: viewModel.transformOrigin, perform: { transformOrigin in
            if let positionable = viewModel.kaleidoscopeKind.configuration as? Positionable {
                positionable.position = transformOrigin
            }
        })
        .onChange(of: viewModel.kaleidoscopeKind) { _ in
            if let positionable = viewModel.kaleidoscopeKind.configuration as? Positionable {
                viewModel.transformOrigin = positionable.position
                transformOriginPosition = convertTransformOriginToImageBoundedPosition(positionable.position)
            }
        }
    }
    
    func clampPositionWithinImageBounds(_ position: CGPoint) -> CGPoint {
        let x = min(max(position.x, imageBounds.minX), imageBounds.maxX)
        let y = min(max(position.y, imageBounds.minY), imageBounds.maxY)
        return CGPoint(x: x, y: y)
    }
    
    /// Converts normalized coordinates to ones within image bounds
    func convertTransformOriginToImageBoundedPosition(_ transformOrigin: CGPoint) -> CGPoint {
        let x = imageBounds.minX + transformOrigin.x * imageBounds.width
        let y = imageBounds.minY + transformOrigin.y * imageBounds.height
        return CGPoint(x: x, y: y)
    }
    
    /// Makes coordinates within image bounds normalized
    func convertImageBoundedPositionToTransformOrigin(_ position: CGPoint) -> CGPoint {
        let x = (position.x - imageBounds.minX) / imageBounds.width
        let y = (position.y - imageBounds.minY) / imageBounds.height
        return CGPoint(x: x, y: y)
    }
    
    func didChangeTranformOrigin(value: DragGesture.Value) {
        let clamped = clampPositionWithinImageBounds(value.location)
        transformOriginPosition = clamped
        viewModel.transformOrigin = convertImageBoundedPositionToTransformOrigin(clamped)
    }
}
