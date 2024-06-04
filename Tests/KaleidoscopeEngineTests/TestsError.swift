//
//  TestsError.swift
//
//
//  Created by Eskil Gjerde Sviggum on 26/03/2024.
//

import Foundation

enum TestsError: Error {
    case cannotFindImageResource
    case cannotMakeImageSource
    case cannotMakeCGImageFromData
    case cannotMakeImageDestination
}
