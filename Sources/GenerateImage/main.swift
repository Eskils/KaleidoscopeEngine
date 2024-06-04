//
//  main.swift
//
//
//  Created by Eskil Gjerde Sviggum on 18/03/2024.
//

import Foundation
import KaleidoscopeEngine

let arguments = Helpers.parseArguments(CommandLine.arguments)

let projectDirectory = URL(fileURLWithPath: #filePath + "/../../../").standardizedFileURL.path + "/"

func consumeArguments() -> (inputPath: String, outputPath: String, configuration: Configuration?)? {
    if let configPath = arguments["config"]?.replacingOccurrences(of: "./", with: projectDirectory) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            let configuration = try JSONDecoder().decode(Configuration.self, from: data)
            return (configuration.input.replacingOccurrences(of: "./", with: projectDirectory),
                    configuration.output.replacingOccurrences(of: "./", with: projectDirectory),
                    configuration)
        } catch {
            print("Cannot parse configuration file: ", error)
            return nil
        }
    } else {
        guard let inputPath = arguments["input"]?.replacingOccurrences(of: "./", with: projectDirectory) else {
            print("Please provide a valid input path with the “-input” argument.")
            return nil
        }

        guard let outputPath = arguments["output"]?.replacingOccurrences(of: "./", with: projectDirectory) else {
            print("Please provide a valid output path with the “-output” argument.")
            return nil
        }
        
        return (inputPath, outputPath, nil)
    }
}

guard let (inputPath, outputPath, configuration) = consumeArguments() else {
    exit(-1)
}

let inputURL = URL(fileURLWithPath: inputPath)
let outputURL = URL(fileURLWithPath: outputPath)

let generateImages = GenerateImages()

var outputImages = [OutputImage]()

var inputImages = [String]()

var inputIsDirectory: ObjCBool = true
let inputPathExists = FileManager.default.fileExists(atPath: inputPath, isDirectory: &inputIsDirectory)

if !inputPathExists {
    print("Input path does not exist")
    exit(-1)
}

if inputIsDirectory.boolValue {
    inputImages = try FileManager.default.contentsOfDirectory(atPath: inputPath)
} else {
    inputImages = [inputPath]
}

for inputItem in inputImages {
    if inputItem.starts(with: ".") {
        continue
    }
    
    do {
        let inputPath = if inputIsDirectory.boolValue {
            inputURL.appendingPathComponent(inputItem).path
        } else {
            inputItem
        }
        
        let inputImage = try Helpers.image(atPath: inputPath)
        let name = URL(fileURLWithPath: inputItem).lastPathComponent.split(separator: ".")[0]
        if let configuration {
            let transforms = configuration.transforms.compactMap { (dto) -> ImageTransform? in
                let kind = dto.kind
                do {
                    let configuration = try JSONDecoder().decode(kind.decodableType, from: dto.configuration.jsonData())
                    let transformKind = try kind.toImageTransformKind(configuration: configuration)
                    return ImageTransform(kind: transformKind, name: dto.name)
                } catch {
                    print("Cannot parse configuration to correct type")
                    return nil
                }
            }
            generateImages.imageTransforms(inputImage: inputImage, name: String(name), transforms: transforms, outputImages: &outputImages)
        } else {
            generateImages.imageTransforms(inputImage: inputImage, name: String(name), outputImages: &outputImages)
        }
    } catch {
        print("Could not handle \(inputItem). Error: \(error)")
    }
}

var outputDirectoryExists = FileManager.default.fileExists(atPath: outputPath)

if let configuration, configuration.clearOutputDirectory == true, outputDirectoryExists {
    try FileManager.default.removeItem(at: outputURL)
    outputDirectoryExists = false
}

if !outputDirectoryExists {
    try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
}

outputImages.forEach { output in
    let path = outputURL.appendingPathComponent(output.name + ".png").path
    do {
        try Helpers.write(image: output.image, toPath: path)
    } catch {
        print("Could not write image \(output.name) to \(path).")
    }
}
