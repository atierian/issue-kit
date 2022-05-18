//
//  File.swift
//  
//
//  Created by Saultz, Ian on 2/3/22.
//

import Foundation

public struct Issue: Codable, Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public let id: Int
    public let nodeID: String
    public let url: String
    public let repositoryURL: String
    public let labelsURL: String
    public let commentsURL: String
    public let eventsURL: String
    public let htmlURL: String
    public let number: Int
    public let state: String
    public let title: String
    public let body: String
    public let user: Assignee
    public let labels: [Label]
    public let assignee: Assignee?
    public let assignees: [Assignee]
    public let milestone: Milestone?
    public let locked: Bool
    public let activeLockReason: String?
    public let comments: Int
    public let pullRequest: PullRequest?
    public let closedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date?
    public let closedBy: Assignee?
    public let authorAssociation: String

    enum CodingKeys: String, CodingKey {
        case number, state, title, body,
             user, labels, assignee, assignees,
             milestone, locked, url, id, comments
        case nodeID = "node_id"
        case repositoryURL = "repository_url"
        case labelsURL = "labels_url"
        case commentsURL = "comments_url"
        case eventsURL = "events_url"
        case htmlURL = "html_url"
        case activeLockReason = "active_lock_reason"
        case pullRequest = "pull_request"
        case closedAt = "closed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case closedBy = "closed_by"
        case authorAssociation = "author_association"
    }
    
    public init(
        id: Int,
        nodeID: String,
        url: String,
        repositoryURL: String,
        labelsURL: String,
        commentsURL: String,
        eventsURL: String,
        htmlURL: String,
        number: Int,
        state: String,
        title: String,
        body: String,
        user: Issue.Assignee,
        labels: [Issue.Label],
        assignee: Issue.Assignee?,
        assignees: [Issue.Assignee],
        milestone: Issue.Milestone?,
        locked: Bool,
        activeLockReason: String?,
        comments: Int,
        pullRequest: Issue.PullRequest?,
        closedAt: Date?,
        createdAt: Date,
        updatedAt: Date?,
        closedBy: Issue.Assignee?,
        authorAssociation: String
    ) {
        self.id = id
        self.nodeID = nodeID
        self.url = url
        self.repositoryURL = repositoryURL
        self.labelsURL = labelsURL
        self.commentsURL = commentsURL
        self.eventsURL = eventsURL
        self.htmlURL = htmlURL
        self.number = number
        self.state = state
        self.title = title
        self.body = body
        self.user = user
        self.labels = labels
        self.assignee = assignee
        self.assignees = assignees
        self.milestone = milestone
        self.locked = locked
        self.activeLockReason = activeLockReason
        self.comments = comments
        self.pullRequest = pullRequest
        self.closedAt = closedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.closedBy = closedBy
        self.authorAssociation = authorAssociation
    }
}
