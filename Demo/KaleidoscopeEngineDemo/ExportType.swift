//
//  ExportType.swift
//  KaleidoscopeEngineDemo
//
//  Created by Eskil Gjerde Sviggum on 04/06/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportType {
    let name: String
    let url: URL
    let kind: Kind
    
    var fileDocument: FileDocument {
        self.kind.fileDocument(withURL: url)
    }
    
    var contentType: UTType {
        switch kind {
        case .image:
            return .png
        case .video:
            return .mpeg4Movie
        }
    }
    
    enum Kind {
        case image
        case video
        
        fileprivate func fileDocument(withURL url: URL) -> FileDocument {
            switch self {
            case .image:
                ImageFileDocument(url: url)
            case .video:
                VideoFileDocument(url: url)
            }
        }
    }
    
}

extension ExportType: FileDocument {
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try self.fileDocument.fileWrapper(configuration: configuration)
    }
    
    init(configuration: ReadConfiguration) throws {
        throw NSError()
    }
    
    static var readableContentTypes: [UTType] {
        []
    }
    
}

