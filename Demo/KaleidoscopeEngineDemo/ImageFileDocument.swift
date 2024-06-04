//
//  ImageFileDocument.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 21/03/2024.
//

import UniformTypeIdentifiers
import SwiftUI

class ImageFileDocument: FileDocument {
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    static var readableContentTypes: [UTType] {
        [.image]
    }
    
    static var writableContentTypes: [UTType] {
        [.png]
    }
    
    required init(configuration: ReadConfiguration) throws {
        fatalError("Not implemented")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url)
    }
    
}
