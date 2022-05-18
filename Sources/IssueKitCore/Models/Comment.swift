//
//  File.swift
//  
//
//  Created by Saultz, Ian on 5/18/22.
//

import Foundation

public struct Comment: Codable {
    public let id: Int
    public let nodeID: String
    public let url: String
    public let htmlURL: String
    public let user: Issue.Assignee
    public let createdAt: Date
    public let updatedAt: Date?
    public let issueURL: String
    public let authorAssociation: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case nodeID = "node_id"
        case url
        case htmlURL = "html_url"
        case user
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case issueURL = "issue_url"
        case authorAssociation = "author_association"
    }
}
