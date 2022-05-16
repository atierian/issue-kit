//
//  File.swift
//  
//
//  Created by Saultz, Ian on 2/3/22.
//

import Foundation

public extension Issue {
    struct PullRequest: Codable {
        public let url: String
        public let htmlURL: String
        public let diffURL: String
        public let patchURL: String

        enum CodingKeys: String, CodingKey {
            case url
            case htmlURL = "html_url"
            case diffURL = "diff_url"
            case patchURL = "patch_url"
        }
        
        public init(
            url: String,
            htmlURL: String,
            diffURL: String,
            patchURL: String
        ) {
            self.url = url
            self.htmlURL = htmlURL
            self.diffURL = diffURL
            self.patchURL = patchURL
        }
    }
}
