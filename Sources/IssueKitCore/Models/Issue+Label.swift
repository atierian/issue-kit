//
//  File.swift
//  
//
//  Created by Saultz, Ian on 2/3/22.
//

import Foundation

public extension Issue {
    struct Label: Codable {
        public let id: Int
        public let nodeID: String
        public let url: String
        public let name: String
        public let labelDescription: String
        public let color: String
        public let labelDefault: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case nodeID = "node_id"
            case url, name
            case labelDescription = "description"
            case color
            case labelDefault = "default"
        }
        
        public init(
            id: Int,
            nodeID: String,
            url: String,
            name: String,
            labelDescription: String,
            color: String,
            labelDefault: Bool
        ) {
            self.id = id
            self.nodeID = nodeID
            self.url = url
            self.name = name
            self.labelDescription = labelDescription
            self.color = color
            self.labelDefault = labelDefault
        }
    }
}
