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
        
    @Flag(name: .long, help: "Exclude Pull Requests. Filtering happens locally")
    private var nopr: Bool = false
        
    mutating func run() async throws {
        var queryItems = [
            URLQueryItem(name: "state", value: "all"),
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
        
        let cachedIssuesFile = Foundation.URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("issues.json")
        
        let issues: [Issue]
        do {
            let data = try Data(contentsOf: cachedIssuesFile)
            issues = try JSONDecoder().decode([Issue].self, from: data)
        } catch {
            let task = try GitHub
                .logging(verbose: verbose)
                .repository(path: path)
                .query(queryItems, all: true)
            
            issues = try await task.value
                .filter { $0.pullRequest == nil }
        }
        
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
        let amountOfIssuesLine = Reporting.amountOfIssues.generate(issues)
        let amountOfOpenIssuesLine = Reporting.amountOfOpenIssues.generate(issues)
        let issuesOpenedPerTimeIntervalLines = [Reporting.TimePeriod.oneWeek, .oneMonth, .threeMonths, .sixMonths, .oneYear]
            .map {
                Reporting.newIssuesOpenedInThePrevious(timePeriod: $0)
                    .generate(issues)
            }
        
        let plusMinusPerTimeIntervalLines = [Reporting.TimePeriod.oneWeek, .oneMonth, .threeMonths, .sixMonths, .oneYear]
            .map {
                Reporting.plusMinusInThePrevious(timePeriod: $0)
                    .generate(issues)
            }

                
        let reportURL = Foundation.URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("issue_summary_report.csv")
        let csv = Converting.report.run(issues)
        FileManager.default.createFile(atPath: reportURL.path, contents: csv)
        print("Report generated at: \(reportURL)")
        
    }
}

struct Reporting {
    struct Line {
        let key: String
        let value: String
        var display: String { "\(key): \(value)" }
    }
    
    let generate: ([Issue]) -> Line
    
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
    
    static func plusMinusInThePrevious(timePeriod: TimePeriod) -> Reporting {
        Reporting { issues in
            let today = Date()
            let start = timePeriod.start(today)
            let opened = issues.filter { $0.createdAt >= start }.count
            let closed = issues.filter { $0.closedAt ?? Date() <= start }.count
            let delta = opened - closed
            return Line(key: "+ - open/closed in the previous \(timePeriod.description)", value: String(delta))
        }
    }
    
    
    
//    static let openIssuesWithoutResponse = Reporting { issues in
//
//    }
    
    struct TimePeriod {
        static let calendar = Calendar.current
        
        private static func bySubstracting(component: DateComponents, from date: Date) -> Date {
            Self.calendar.date(byAdding: component, to: date)!
        }
        
        let description: String
        let start: (Date) -> Date
        
        static let oneWeek = TimePeriod(description: "week") { today in
            bySubstracting(component: DateComponents(day: -7), from: today)
        }
        
        static let oneMonth = TimePeriod(description: "month") { today in
            bySubstracting(component: DateComponents(month: -1), from: today)
        }
        
        static let threeMonths = TimePeriod(description: "three months") { today in
            bySubstracting(component: DateComponents(month: -3), from: today)
        }
        
        static let sixMonths = TimePeriod(description: "six months") { today in
            bySubstracting(component: DateComponents(month: -6), from: today)
        }
        
        static let oneYear = TimePeriod(description: "year") { today in
            bySubstracting(component: DateComponents(year: -1), from: today)
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
