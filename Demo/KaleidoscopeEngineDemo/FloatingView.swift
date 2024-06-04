//
//  FloatingView.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 25/03/2024.
//

import SwiftUI

struct FloatingView<T: View>: View {
    
    @State
    private var oldTranslation: CGSize = CGSize(width: 40, height: 40)
    
    @State
    private var translation: CGSize = CGSize(width: 40, height: 40)
    
    var content: () -> T
    
    init(@ViewBuilder content: @escaping () -> T) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                content()
                Divider()
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill()
                        .foregroundStyle(Color.secondary)
                        .frame(width: 38, height: 5)
                    Spacer()
                }
                .frame(height: 40)
            }
            .frame(width: 340)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .offset(translation)
            .gesture(
                DragGesture()
                    .onChanged(didChangeDrag(value:))
                    .onEnded(didEndDrag(value:))
            )
        }
    }
    
    private func didChangeDrag(value: DragGesture.Value) {
        translation = CGSize(width: oldTranslation.width + value.translation.width, height: oldTranslation.height + value.translation.height)
    }
    
    private func didEndDrag(value: DragGesture.Value) {
        oldTranslation.width += value.translation.width
        oldTranslation.height += value.translation.height
    }
}
