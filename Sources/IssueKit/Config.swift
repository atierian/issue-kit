//
//  File.swift
//  
//
//  Created by Saultz, Ian on 9/28/22.
//

import Foundation
import IssueKitCore

func config() throws -> Config {
    let configFile = Foundation.URL(
        fileURLWithPath: FileManager.default.currentDirectoryPath
    )
        .appendingPathComponent("config.txt")

    let data = try Data(contentsOf: configFile)
    let string = String(data: data, encoding: .utf8)!

    let components = string
        .components(separatedBy: .newlines)
        .dropLast()

    let dict = components
        .reduce(into: [String: String]()) { dict, line in
            let components = line.components(separatedBy: "=")
            dict[components[0]] = components[1]
        }

    let config = Config(
        org: dict["org"]!,
        repo: dict["repo"]!,
        pat: dict["pat"],
        maintainers: dict["maintainers"]?
            .components(separatedBy: ",")
    )

    return config
}
