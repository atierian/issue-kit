//
//  File.swift
//  
//
//  Created by Saultz, Ian on 9/28/22.
//

import Foundation
import IssueKitCore

struct Reporting<T, U> {
    let generate: (T) -> U
}

struct Line {
    let key: String
    let value: String
    var display: String { "\(key): \(value)" }
}

extension Reporting where T == ([Issue: [Comment]], Set<String>), U == [Line] {

    static let issuesWithoutMaintainerResponse = Reporting { dict, maintainerSet in
        let open = dict.filter {
            $0.key.state == "open"
        }

        let issuesFromNonMaintainers = open
            .filter { issue, _ in
                !maintainerSet.contains(issue.user.login)
            }

        let issuesFromNonMaintainersWOMaintainerResponse = issuesFromNonMaintainers
            .filter { _, comments in
                let userSet = Set(comments.map(\.user.login))
                let noMaintainerComment = userSet
                    .isDisjoint(with: maintainerSet)
                return noMaintainerComment
            }

        let lines = issuesFromNonMaintainersWOMaintainerResponse.keys
            .sorted { $0.createdAt < $1.createdAt }
            .map {
                Line(
                    key: "Number / URL",
                    value: "\($0.number) / \($0.htmlURL)"
                )
            }
        return lines
    }
}

extension Reporting where T == ([Issue: [Comment]], Set<String>), U == Line {

    static func averageMaintainerResponseTime(from start: Date, to end: Date) -> Reporting {
        .init { dict, maintainerSet in
            let issues = dict.keys.filter {
                start...end ~= $0.createdAt
            }

            let responseTimeInDays = issues.compactMap { issue in
                let firstMaintainerResponse = dict[issue]?
                    .sorted(by: { $0.createdAt < $1.createdAt })
                    .first(where: { maintainerSet.contains($0.user.login) })

                let issueCreatedDate = issue.createdAt

                if let firstMaintainerResponse = firstMaintainerResponse {
                    let componenents = Calendar.current.dateComponents([.weekday], from: issueCreatedDate, to: firstMaintainerResponse.createdAt)
                    return componenents.weekday!
                } else {
                    return nil
                }
            }

            let average = responseTimeInDays.reduce(0, +) / responseTimeInDays.count
            let median = responseTimeInDays.sorted(by: <)[responseTimeInDays.count / 2]
            return Line(
                key: "Maintainer Response time in weekdays for issues opened \(start.readable) - \(end.readable)",
                value: "Average: \(average) | Median: \(median)"
            )
        }
    }

    static func issuesWithoutMainterResponseInTwoDays(timePeriod: TimePeriod) -> Reporting {
        .init { dict, maintainers in
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
                    .filter {
                        maintainers.contains($0.user.login)
                    }
                    .map(\.createdAt)
                    .sorted(by: >)
                    .filter { $0 <= twoBusinessDaysAfter }
                    .count ?? 0)
            }

            return Line(
                key: "# issues opened w/o maintainer response w/in 2 weekdays in previous \(timePeriod.description)",
                value: woResponse.description
            )
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
        return Line(
            key: "Total amount of open issues",
            value: openIssuesCount
        )
    }

    static func newIssuesOpenedInThePrevious(timePeriod: TimePeriod) -> Reporting {
        Reporting { issues in
            let today = Date()
            let start = timePeriod.start(today)
            let i = issues.filter { $0.createdAt >= start }
            return Line(
                key: "Issues opened in the previous \(timePeriod.description)",
                value: i.count.description
            )
        }
    }

    static func issuesClosedThePrevious(timePeriod: TimePeriod) -> Reporting {
        Reporting { issues in
            let today = Date()
            let start = timePeriod.start(today)
            let i = issues.filter {
                $0.closedAt != nil && $0.closedAt! >= start
            }
            return Line(
                key: "Issues closed in the previous \(timePeriod.description)",
                value: i.count.description
            )
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
            return Line(
                key: "+ - open/closed in the previous \(timePeriod.description)",
                value: String(delta)
            )
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
