//
//  ContentView.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 20/03/2024.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    
    @ObservedObject
    var viewModel = KaleidoscopeEngineDemoViewModel()
    
    var body: some View {
        #if os(macOS)
        NavigationView {
            SidebarView(viewModel: viewModel)
                .listStyle(.sidebar)
            
            PreviewView(viewModel: viewModel)
        }
        #else
        if horizontalSizeClass == .regular {
            // Pad
            ZStack {
                PreviewView(viewModel: viewModel)
                
                FloatingView {
                    SidebarView(viewModel: viewModel)
                }
            }
        } else {
            // Phone
            ScrollView {
                VStack {
                    PreviewView(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(contentMode: .fit)
                    
                    SidebarView(viewModel: viewModel)
                }
            }
        }
        #endif
    }
}
