//
//  File.swift
//  
//
//  Created by Saultz, Ian on 2/4/22.
//

import Foundation

public struct GitHub {
    private static var verbose: Bool = false
    
    public static func logging(verbose: Bool) -> GitHub.Type {
        Self.verbose = verbose
        return GitHub.self
    }
    
    enum Error: Swift.Error {
        case invalidPath
        case invalidQuery
    }
    
    public static func repository(path: String) throws -> Request {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/repos\(path)/issues"
        guard let url = components.url else {
            print("input path: \(path) generates an invalid URL")
            throw Error.invalidPath
        }
        
        return Request(url: url)
    }
}

public extension GitHub {
    struct Request {
        let url: URL
        
        static let decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return decoder
        }()
        
        public init(url: URL) {
            self.url = url
        }
        
        public func query(_ queryItems: [URLQueryItem], all: Bool) -> Task<[Issue], Swift.Error> {
            
            return .init {
                
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.queryItems = queryItems
                
                var issues: [Issue] = []
                guard let url = components?.url else {
                    print("input query parameters:\n \(queryItems.map { "\($0)\n" }))\n generates an invalid URL")
                    throw Error.invalidQuery
                }

                var page = 1

                func fetch(url: URL) async throws {
                    let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
                    issues += try Self.decoder.decode([Issue].self, from: data)

                    if all {
                        if issues.count == page * 100 {
                            components?.queryItems?.removeAll(where: { $0.name == "page" })
                            page += 1
                            components?.queryItems?.append(URLQueryItem(name: "page", value: "\(page)"))
                            guard let url = components?.url else {
                                print("input query parameters:\n \(queryItems.map { "\($0)\n" }))\n generates an invalid URL")
                                throw Error.invalidQuery
                            }
                            try await fetch(url: url)
                        }
                    }
                }
                
                try await fetch(url: url)
                print("Retrieved \(issues.count) issues")
                return issues
            }
        }
    }
}

extension Data {
    func prettyPrint() {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .withoutEscapingSlashes]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return print("Unable to create JSON") }
        
        print(prettyPrintedString)
    }
}
