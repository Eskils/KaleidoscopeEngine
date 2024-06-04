//
//  AnyConfigurationCodable.swift
//  
//
//  Created by Eskil Gjerde Sviggum on 26/03/2024.
//

import Foundation

enum AnyConfigurationCodable: Decodable {
    case string(String)
    case boolean(Bool)
    case integer(Int)
    case floating(Float)
    case array([AnyConfigurationCodable])
    case dictionary([String: AnyConfigurationCodable])
//    case point([Double])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string =         try? container.decode(String.self) {
            self = .string(string)
        } else if let bool =    try? container.decode(Bool.self) {
            self = .boolean(bool)
        } else if let int =     try? container.decode(Int.self) {
            self = .integer(int)
        } else if let float =   try? container.decode(Float.self) {
            self = .floating(float)
        } else if let array =   try? container.decode([AnyConfigurationCodable].self) {
            self = .array(array)
        } else if let dict =    try? container.decode([String: AnyConfigurationCodable].self) {
            self = .dictionary(dict)
//        } else if let point =   try? container.decode([Double].self) {
//            self = .point(point)
        } else {
            throw DecodingError.typeMismatch(AnyConfigurationCodable.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Invalid type. Must be one of either string, bool, int, float, array, dict."))
        }
    }
    
    func value() -> Any {
        switch self {
        case .string(let string):
            string
        case .boolean(let bool):
            bool
        case .integer(let int):
            int
        case .floating(let float):
            float
        case .array(let array):
            array.map { $0.value() }
        case .dictionary(let dictionary):
            dictionary.mapValues { $0.value() }
//        case .point(let coordinates):
//            if coordinates.indices.contains(0) {
//                if coordinates.indices.contains(1) {
//                    PointIntermediate(x: coordinates[0], y: coordinates[1])
//                } else {
//                    PointIntermediate(x: coordinates[0], y: 0)
//                }
//            } else {
//                PointIntermediate(x: 0, y: 0)
//            }
        }
    }
}

extension [String: AnyConfigurationCodable] {
    
    func jsonDictionary() -> [String: Any] {
        self.mapValues { $0.value() }
    }
    
    func jsonData() throws -> Data {
        try JSONSerialization.data(withJSONObject: self.jsonDictionary())
    }
    
}
