//
//  File.swift
//  
//
//  Created by Saultz, Ian on 2/4/22.
//

import Foundation
import ArgumentParser
import IssueKitCore

@main
struct Query: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Query a a repository for issues based on various parameters"
    )
    
    @Argument(help: "The path of the repository. Format: '/organization/repo'")
    private var path: String
    
    @Option(name: .long, help: "Options: open, closed, all. Default is `open`")
    private var state: IssueState = .open
    
    @Option(name: .long, help: "Comma seperated labels to filter by")
    private var labels: [String] = []
   
    @Option(name: .long, help: "What to sort results by. Can be created, updated, comments")
    private var sortBy: IssueSort = .created
    
    @Option(name: .long, help: "Sort direction. asc or desc")
    private var direction: IssueDirection = .desc
    
    @Option(name: .long, help: "Only show issues updated after the given time in ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ")
    private var since: String?
        
    @Flag(name: .long, help: "Generate a report. Default 'false'")
    private var generate: Bool = false
    
    @Flag(name: .shortAndLong, help: "Verbose logging. Default 'false'")
    private var verbose: Bool = false
    
    @Flag(name: .long, help: "Retrieve all issues matching criteria.")
    private var all: Bool = false
    
    @Flag(name: .long, help: "Exclude Pull Requests. Filtering happens locally")
    private var nopr: Bool = false
        
    mutating func run() async throws {
        var queryItems = [
            URLQueryItem(name: "state", value: state.rawValue),
            URLQueryItem(name: "sort", value: sortBy.rawValue),
            URLQueryItem(name: "direction", value: direction.rawValue),
            URLQueryItem(name: "per_page", value: "100")
        ]
        
        if let since = since {
            queryItems.append(URLQueryItem(name: "since", value: since))
        }
        
        labels.forEach {
            queryItems.append(URLQueryItem(name: "labels", value: $0))
        }
        
        if verbose {
            print("labels: \(labels)")
        }
        
        let task = try GitHub
            .logging(verbose: verbose)
            .repository(path: path)
            .query(queryItems, all: all)
        
        var issues = try await task.value
        
        if nopr {
            issues = issues.filter { $0.pullRequest == nil }
        }
        
        if generate {
            let path = Foundation.URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("issue_report.csv")
            let csv = Converting.standard.run(issues)
            FileManager.default.createFile(atPath: path.path, contents: csv)
            print("Report generated at: \(path)")
        }
    }
}

public enum IssueDirection: String, ExpressibleByArgument {
    case asc, desc
}

public enum IssueState: String, ExpressibleByArgument {
    case open, closed, all
}

public enum IssueSort: String, ExpressibleByArgument {
    case created, updated, comments
}

struct Converting {
    let run: ([Issue]) -> Data
    
    static var standard: Converting {
        Converting { issues in
            let csv = "Number, State, URL, Title, User, Labels, Created At\n"
            + issues.flatMap {
                "\($0.number),\($0.state.escapingDelimiter),\($0.repositoryURL.escapingDelimiter),\($0.title.escapingDelimiter),\($0.user.login.escapingDelimiter),\($0.labels.map(\.name.escapingDelimiter).joined(separator: " | ")),\($0.createdAt.debugDescription.escapingDelimiter)\n"
            }
            return Data(csv.utf8)
        }
    }
}

fileprivate extension String {
    var escapingDelimiter: String {
        replacingOccurrences(of: ",", with: " ")
    }
}

