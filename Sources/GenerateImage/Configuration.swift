//
//  Configuration.swift
//
//
//  Created by Eskil Gjerde Sviggum on 25/03/2024.
//

import Foundation

struct Configuration: Decodable {
    /// Path to input directory / file
    let input: String
    
    /// Path to output directory
    let output: String
    
    /// Whether to clear the output directory before writing results.
    let clearOutputDirectory: Bool?
    
    /// The transforms to be applied to the inputs.
    let transforms: [Transform]
    
    struct Transform: Decodable {
        /// The kind of transform.
        let kind: ImageTransformKindDTO
        
        /// The name of this transform. When not provided, details of transform are used.
        let name: String?
        
        /// The configuration/settings for the transform.
        let configuration: [String: AnyConfigurationCodable]
    }
    
}
