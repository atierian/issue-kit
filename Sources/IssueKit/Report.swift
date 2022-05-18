//
//  File.swift
//  
//
//  Created by Saultz, Ian on 5/17/22.
//

import Foundation
import ArgumentParser
import IssueKitCore

struct Report: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Run a report based on all issues."
    )
    
    @Argument(help: "The path of the repository. Format: '/organization/repo'")
    private var path: String
    
    @Option(name: .long, help: "Comma seperated labels to filter by")
    private var labels: [String] = []
    
    @Option(name: .long, help: "Sort direction. asc or desc")
    private var direction: IssueDirection = .desc
    
    @Option(name: .long, help: "Only show issues updated after the given time in ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ")
    private var since: String?
    
    @Flag(name: .long, help: "Generate a report. Default 'false'")
    private var generate: Bool = false
    
    @Flag(name: .shortAndLong, help: "Verbose logging. Default 'false'")
    private var verbose: Bool = false
    
    //    func issues() async throws -> [Issue] {
    //        let cachedIssuesFile = Foundation.URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    //            .appendingPathComponent("issues.json")
    //
    //        let issues: [Issue]
    //        do {
    //            let data = try Data(contentsOf: cachedIssuesFile)
    //            issues = try JSONDecoder().decode([Issue].self, from: data)
    //            print("Retrieved Issues from \(cachedIssuesFile.absoluteString)")
    //        } catch {
    //            let task = try GitHub
    //                .logging(verbose: verbose)
    //                .repository(path: path)
    //                .query(.issues, query: queryItems, all: true)
    //
    //            issues = try await task.value
    //                .filter { $0.pullRequest == nil }
    //
    //            let data = try JSONEncoder().encode(issues)
    //            try data.write(to: cachedIssuesFile)
    //            print("Comments collected at \(cachedIssuesFile.absoluteString)")
    //        }
    //
    //        return issues
    
    /*
     let cachedCommentsFile = Foundation.URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
     .appendingPathComponent("comments.json")
     let comments: [Comment]
     do {
     let data = try Data(contentsOf: cachedCommentsFile)
     comments = try JSONDecoder().decode([Comment].self, from: data)
     print("Retrieved Comments from \(cachedCommentsFile.absoluteString)")
     } catch {
     let task = try GitHub
     .logging(verbose: verbose)
     .repository(path: path)
     .query(.comments, query: queryItems, all: true)
     
     comments = try await task.value
     
     let data = try JSONEncoder().encode(comments)
     try data.write(to: cachedCommentsFile)
     print("Comments collected at \(cachedCommentsFile.absoluteString)")
     }
     */
    
    //    }
    
    func get<T>(
        _ resource: GitHub.Request.Path<T>,
        query: [URLQueryItem],
        clientSideFilter: (T) -> Bool = { _ in true }
    ) async throws -> [T] {
        let cachedFile = Foundation.URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath
        )
            .appendingPathComponent("\(resource.description).json")
        
        let resources: [T]
        do {
            let data = try Data(contentsOf: cachedFile)
            resources = try JSONDecoder().decode([T].self, from: data)
            print("Retrieved \(resource.description) from \(cachedFile.absoluteString)")
        } catch {
            let task = try GitHub
                .logging(verbose: verbose)
                .repository(path: path)
                .query(resource, query: query, all: true)
            
            resources = try await task.value
                .filter(clientSideFilter)
            
            let data = try JSONEncoder().encode(resources)
            try data.write(to: cachedFile)
            print("\(resource.description.uppercased()) collected at \(cachedFile.absoluteString)")
        }
        
        return resources
    }
    
    private func cache(
        issues: [Issue],
        comments: [Comment]
    ) -> [Issue: [Comment]] {
        [:]
    }
    
    private func queryItems(direction: IssueDirection, since: String?, labels: [String]) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "state", value: "all"),
            URLQueryItem(name: "direction", value: direction.rawValue),
            URLQueryItem(name: "per_page", value: "100")
        ]
        if let since = since {
            queryItems.append(URLQueryItem(name: "since", value: since))
        }
        if !labels.isEmpty {
            queryItems.append(URLQueryItem(name: "labels", value: labels.joined(separator: ",")))
        }
        return queryItems
    }
    
    mutating func run() async throws {
        let queryItems = queryItems(
            direction: direction,
            since: since,
            labels: labels
        )
                
        if verbose { print("labels: \(labels)") }
        
        let issues = try await get(
            .issues,
            query: queryItems
        ) { $0.pullRequest == nil }
        
        let comments = try await get(
            .comments,
            query: queryItems
        )
        
        /**
         Generate report data
         - Total amount of issues
         - Total open issues
         - Amount of issues opened per time interval
         - 1 week / 1 month / 3 months / 6 months / 12 months
         - Plus minus open closed
         - 1 week / 1 month / 3 months / 6 months / 12 months
         
         - List open issues without maintainer response + time elapsed since opening
         - Amount of issues that go > 2 business days without an initial response from maintainers
         - 1 week / 1 month / 3 months / 6 months / 12 months
         - Average and median initial response time from maintainers
         - Average and median subsequent response time from maintainers
         */
        let outputLines = consoleOutput(issues: issues, comments: comments)
        outputLines.forEach {
            print(">  \($0.display)")
        }

        generateReport(issues: issues, comments: comments)
    }
    
    private func timeIntervalBased<T>(input: T, _ f: (TimePeriod) -> Reporting<T, Line>) -> [Line] {
        [TimePeriod.oneWeek, .oneMonth, .threeMonths, .sixMonths, .oneYear]
            .map(f)
            .map { $0.generate(input) }
    }
    
    func consoleOutput(issues: [Issue], comments: [Comment]) -> [Line] {
        let totalIssuesLine = Reporting.amountOfIssues.generate(issues)
        let openIssuesLine = Reporting.amountOfOpenIssues.generate(issues)
        let issuesOpenedPerTimeIntervalLines = timeIntervalBased(
            input: issues,
            Reporting.newIssuesOpenedInThePrevious(timePeriod:)
        )
        let issuesClosedPerTimeIntervalLines = timeIntervalBased(
            input: issues,
            Reporting.issuesClosedThePrevious(timePeriod:)
        )
        let plusMinusPerTimeIntervalLines = timeIntervalBased(
            input: issues,
            Reporting.plusMinusInThePrevious(timePeriod:)
        )
        
        let cache = cache(issues: issues, comments: comments)
        let issuesWithoutMaintainerResponse = Reporting
            .issuesWithoutMaintainerResponse
            .generate(cache)
        
        let issuesWithoutMaintainerResponseWithinTwoWeekdaysTimeIntervalLines = timeIntervalBased(
            input: cache,
            Reporting.issuesWithoutMainterResponseInTwoDays(timePeriod:)
        )
        
        return [
            totalIssuesLine,
            openIssuesLine
        ] + zip(zip(
            issuesOpenedPerTimeIntervalLines,
            issuesClosedPerTimeIntervalLines),
            plusMinusPerTimeIntervalLines)
        .flatMap {
            [$0.0.0, $0.0.1, $0.1]
        } + issuesWithoutMaintainerResponseWithinTwoWeekdaysTimeIntervalLines
    }
    
    func generateReport(issues: [Issue], comments: [Comment]) {
        let reportURL = Foundation.URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("issue_summary_report.csv")
        let csv = Converting.report.run(issues)
        FileManager.default.createFile(atPath: reportURL.path, contents: csv)
        print("Report generated at: \(reportURL)")
    }
}

struct Cache: Codable {
    private let issues: [Issue: [Comment]]
    let comments: [Comment]
}

struct TimePeriod {
    static var calendar: Calendar { Calendar.current }
    
    private static func bySubstracting(component: DateComponents, from date: Date) -> Date {
        Self.calendar.date(byAdding: component, to: date)!
    }
    
    let description: String
    let start: (Date) -> Date
    
    static var oneWeek: TimePeriod {
        TimePeriod(description: "week") { today in
            bySubstracting(component: DateComponents(day: -7), from: today)
        }
    }
    
    static var oneMonth: TimePeriod {
        TimePeriod(description: "month") { today in
            bySubstracting(component: DateComponents(month: -1), from: today)
        }
    }
    
    static var threeMonths: TimePeriod {
        TimePeriod(description: "three months") { today in
            bySubstracting(component: DateComponents(month: -3), from: today)
        }
    }
    
    static var sixMonths: TimePeriod {
        TimePeriod(description: "six months") { today in
            bySubstracting(component: DateComponents(month: -6), from: today)
        }
    }
    
    static var oneYear: TimePeriod {
        TimePeriod(description: "year") { today in
            bySubstracting(component: DateComponents(year: -1), from: today)
        }
    }
}

struct Line {
    let key: String
    let value: String
    var display: String { "\(key): \(value)" }
}

struct Reporting<T, U> {
    let generate: (T) -> U
}

extension Reporting where T == [Issue: [Comment]], U == [Line] {
    
    static let issuesWithoutMaintainerResponse = Reporting { dict in
        let issuesWOResponse = dict.filter {
            !$0.value.contains(where: { $0.authorAssociation == "SOMETHING" })
        }
        let lines = issuesWOResponse.keys
            .map { Line(key: "Number / URL", value: "\($0.number) / \($0.htmlURL)") }
        return lines
    }
}

extension Reporting where T == [Issue: [Comment]], U == Line {
    
    static func issuesWithoutMainterResponseInTwoDays(timePeriod: TimePeriod) -> Reporting {
        .init { dict in
            let today = Date()
            let start = timePeriod.start(today)
            let opened = dict.keys.filter { $0.createdAt >= start }
            let woResponse = opened.reduce(0) { partialResult, issue in
                let twoBusinessDaysAfter = Calendar.current
                    .date(
                        byAdding: DateComponents(weekday: 2),
                        to: issue.createdAt
                    )!
                
                return partialResult + (dict[issue]?
                    .filter { $0.authorAssociation == "SOMETHING" }
                    .map(\.createdAt)
                    .sorted(by: >)
                    .filter { $0 <= twoBusinessDaysAfter }
                    .count ?? 0)
            }
            
            return Line(key: "# issues opened w/o maintainer response w/in 2 weekdays", value: woResponse.description)
        }
    }
}

extension Reporting where T == [Issue], U == Line {
    static let amountOfIssues = Reporting { issues in
        Line(key: "Total amount of issues", value: issues.count.description)
    }
    
    static let amountOfOpenIssues = Reporting { issues in
        let openIssuesCount = issues
            .filter { $0.state == "open" }
            .count
            .description
        return Line(key: "Total amount of open issues", value: openIssuesCount)
    }
    
    
    static func newIssuesOpenedInThePrevious(timePeriod: TimePeriod) -> Reporting {
        Reporting { issues in
            let today = Date()
            let start = timePeriod.start(today)
            let i = issues.filter { $0.createdAt >= start }
            return Line(key: "Issues opened in the previous \(timePeriod.description)", value: i.count.description)
        }
    }
    
    
    static func issuesClosedThePrevious(timePeriod: TimePeriod) -> Reporting {
        Reporting { issues in
            let today = Date()
            let start = timePeriod.start(today)
            let i = issues.filter {
                $0.closedAt != nil && $0.closedAt! >= start
            }
            return Line(key: "Issues closed in the previous \(timePeriod.description)", value: i.count.description)
        }
    }
    
    static func plusMinusInThePrevious(timePeriod: TimePeriod) -> Reporting {
        Reporting { issues in
            let today = Date()
            let start = timePeriod.start(today)
            let opened = issues.filter { $0.createdAt >= start }.count
            let closed = issues.filter {
                $0.closedAt != nil && $0.closedAt! >= start
            }.count
            let delta = opened - closed
            return Line(key: "+ - open/closed in the previous \(timePeriod.description)", value: String(delta))
        }
    }
}

extension Converting {
    static var report: Converting {
        Converting { issues in
            Data()
        }
    }
}
