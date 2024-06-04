//
//  TriangleKaleidoscopeTransformConfigurationView.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 28/05/2024.
//

import SwiftUI

struct TriangleKaleidoscopeTransformConfigurationView: View {
    
    @ObservedObject
    var viewModel: TriangleKaleidoscopeTransformConfiguration
    
    var body: some View {
        VStack {
            HStack {
                Text("Size")
                
                Spacer()
                
                TextField("", value: $viewModel.size, formatter: NumberFormatter())
                Stepper("", value: $viewModel.size)
            }
            
            HStack {
                Text("Decay")
                
                Spacer()
                
                TextField("", value: $viewModel.decay, formatter: {
                    $0.minimum = 0
                    $0.maximum = 1
                    $0.maximumFractionDigits = 2
                    return $0
                }(NumberFormatter()))
                Stepper("", value: $viewModel.decay, in: 0...1, step: 0.05)
            }
        }
    }
}
