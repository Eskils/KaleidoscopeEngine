//
//  VideoFileDocument.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 03/06/2024.
//

import UniformTypeIdentifiers
import SwiftUI

class VideoFileDocument: FileDocument {
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    static var readableContentTypes: [UTType] {
        [.video]
    }
    
    static var writableContentTypes: [UTType] {
        [.mpeg4Movie]
    }
    
    required init(configuration: ReadConfiguration) throws {
        fatalError("Not implemented")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url)
    }
    
}
