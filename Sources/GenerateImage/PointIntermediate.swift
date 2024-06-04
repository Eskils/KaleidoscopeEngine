//
//  File.swift
//  
//
//  Created by Eskil Gjerde Sviggum on 13/05/2024.
//

import Foundation

struct PointIntermediate: Codable {
    private let type: String
    let x: Double
    let y: Double
    
    private static let type = "KEPointIntermediate"
    
    init(x: Double, y: Double) {
        self.type = Self.type
        self.x = x
        self.y = y
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(String.self, forKey: .type)
        if type != Self.type {
            throw DecodeError.invalidTypeForPointIntermediate
        }
        
        self.type = type
        self.x = try container.decode(Double.self, forKey: .x)
        self.y = try container.decode(Double.self, forKey: .y)
    }
    
    func toPoint() -> CGPoint {
        CGPoint(x: x, y: y)
    }
    
    enum DecodeError: Error {
        case invalidTypeForPointIntermediate
    }
}
