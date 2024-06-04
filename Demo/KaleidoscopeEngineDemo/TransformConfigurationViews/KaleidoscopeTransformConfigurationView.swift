//
//  KaleidoscopeTransformConfigurationView.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 28/05/2024.
//

import SwiftUI
import KaleidoscopeEngine

struct KaleidoscopeTransformConfigurationView: View {
    
    @ObservedObject
    var viewModel: KaleidoscopeTransformConfiguration
    
    var body: some View {
        VStack {
            HStack {
                Text("Count")
                
                Spacer()
                
                TextField("", value: $viewModel.count, formatter: NumberFormatter())
                Stepper("", value: $viewModel.count)
            }
            
            HStack {
                Text("Angle")
                
                Spacer()
                
                TextField("", value: $viewModel.angleDeg, formatter: NumberFormatter())
                Stepper("", value: $viewModel.angleDeg)
            }
            
            HStack {
                Text("Fill mode")
                
                Spacer()
                
                Picker("", selection: $viewModel.fillMode) {
                    ForEach(FillMode.allCases, id: \.self) { fillMode in
                        Text(fillMode.title)
                            .tag(fillMode)
                    }
                }
            }
        }
    }
}
