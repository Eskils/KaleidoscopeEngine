//
//  ViewInitializable.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 28/05/2024.
//

import SwiftUI
import Combine

protocol ViewInitializable {
    func makeView() -> AnyView
    var willChangePublisher: ObservableObjectPublisher { get }
}
