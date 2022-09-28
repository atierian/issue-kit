import Foundation
import ArgumentParser

@main
public struct Issues: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "A command line tool to query GitHub issues",
        subcommands: [Query.self, Report.self]
    )
    
    public init() { }
}
