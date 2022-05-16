//
//  File.swift
//  
//
//  Created by Saultz, Ian on 2/3/22.
//

import Foundation

public extension Issue {
    struct Milestone: Codable {
        public let url: String
        public let htmlURL: String
        public let labelsURL: String
        public let id: Int
        public let nodeID: String
        public let number: Int
        public let state, title: String
        public let milestoneDescription: String?
        public let creator: Assignee
        public let openIssues, closedIssues: Int
        public let createdAt: Date
        public let updatedAt: Date
        public let closedAt: Date?
        public let dueOn: Date?
        
        enum CodingKeys: String, CodingKey {
            case url
            case htmlURL = "html_url"
            case labelsURL = "labels_url"
            case id
            case nodeID = "node_id"
            case number, state, title
            case milestoneDescription = "description"
            case creator
            case openIssues = "open_issues"
            case closedIssues = "closed_issues"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case closedAt = "closed_at"
            case dueOn = "due_on"
        }

        public init(
            url: String,
            htmlURL: String,
            labelsURL: String,
            id: Int,
            nodeID: String,
            number: Int,
            state: String,
            title: String,
            milestoneDescription: String?,
            creator: Issue.Assignee,
            openIssues: Int,
            closedIssues: Int,
            createdAt: Date,
            updatedAt: Date,
            closedAt: Date?,
            dueOn: Date?
        ) {
            self.url = url
            self.htmlURL = htmlURL
            self.labelsURL = labelsURL
            self.id = id
            self.nodeID = nodeID
            self.number = number
            self.state = state
            self.title = title
            self.milestoneDescription = milestoneDescription
            self.creator = creator
            self.openIssues = openIssues
            self.closedIssues = closedIssues
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.closedAt = closedAt
            self.dueOn = dueOn
        }
    }
}
