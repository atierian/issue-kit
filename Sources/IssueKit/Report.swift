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
        } catch {
            let config = try config()
            let task = try GitHub
                .logging(verbose: verbose)
                .config(config)
                .query(resource, query: query, all: true)
            resources = try await task.value
                .filter(clientSideFilter)

            let data = try JSONEncoder().encode(resources)
            try data.write(to: cachedFile)
        }
        
        return resources
    }
    
    private func issueCommentLink(
        issues: [Issue],
        comments: [Comment]
    ) -> [Issue: [Comment]] {
        let cachedLookup = Foundation.URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath
        )
            .appendingPathComponent("_issue_comment_lookup")

        if let data = try? Data(contentsOf: cachedLookup),
           let decoded = try? JSONDecoder().decode([Issue: [Comment]].self, from: data) {
            return decoded
        }

        let linked = issues.reduce(into: [Issue: [Comment]]()) { dict, issue in
            dict[issue] = comments
                .filter { $0.issueURL == issue.url }
        }

        do {
            let data = try JSONEncoder().encode(linked)
            try data.write(to: cachedLookup)
        } catch {}

        return linked
    }
    
    private func queryItems(
        direction: IssueDirection,
        since: String?,
        labels: [String]
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "state", value: "all"),
            URLQueryItem(name: "direction", value: direction.rawValue),
            URLQueryItem(name: "per_page", value: "100")
        ]
        if let since = since {
            queryItems.append(URLQueryItem(name: "since", value: since))
        }
        if !labels.isEmpty {
            queryItems.append(
                URLQueryItem(name: "labels", value: labels.joined(separator: ","))
            )
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
        if verbose { print("query items: \(queryItems)")}

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

        let maintainerResponseLines: [Line] = (try? config().maintainers)
            .map { maintainers in
                let issues = issueCommentLink(issues: issues, comments: comments)

                let issuesWithoutMaintainerResponse = Reporting
                    .issuesWithoutMaintainerResponse
                    .generate((issues, maintainers))

                let issuesWithoutMaintainerResponseWithinTwoWeekdaysTimeIntervalLines = timeIntervalBased(
                    input: (issues, maintainers),
                    Reporting.issuesWithoutMainterResponseInTwoDays(timePeriod:)
                )

                return issuesWithoutMaintainerResponseWithinTwoWeekdaysTimeIntervalLines +
                issuesWithoutMaintainerResponse
            } ?? []

        return [
            totalIssuesLine,
            openIssuesLine
        ] +
        zip(
            zip(
                issuesOpenedPerTimeIntervalLines,
                issuesClosedPerTimeIntervalLines
            ),
            plusMinusPerTimeIntervalLines
        )
        .flatMap { [$0.0.0, $0.0.1, $0.1] }
        + maintainerResponseLines
    }
    
    func generateReport(issues: [Issue], comments: [Comment]) {
        let reportURL = Foundation.URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("issue_summary_report.csv")
        let csv = Converting.report.run(issues)
        FileManager.default.createFile(atPath: reportURL.path, contents: csv)
        print("Report generated at: \(reportURL)")
    }
}
