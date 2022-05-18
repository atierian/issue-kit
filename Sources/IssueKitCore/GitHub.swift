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
    
    @usableFromInline
    enum Error: Swift.Error {
        case invalidPath
        case invalidQuery
    }
    
    public static func repository(path: String) throws -> Request {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/repos\(path)"
        guard let url = components.url else {
            print("input path: \(path) generates an invalid URL")
            throw Error.invalidPath
        }
        
        return Request(url: url)
    }
}

public extension GitHub {
    struct Request {
        @usableFromInline
        let url: URL
        
        static let decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return decoder
        }()
        
        public init(url: URL) {
            self.url = url
        }
        
        public struct Path<T: Codable> {
            @usableFromInline
            let value: String
            
            @usableFromInline
            let decode: (Data) throws -> [T] = {
                try GitHub.Request.decoder.decode([T].self, from: $0)
            }
            
            public let description: String
            
            public static var issues: Path<Issue> { .init(value: "/issues", description: "issues") }
            public static var comments: Path<Comment> { .init(value: "/issues/comments", description: "comments") }
        }
        
        @inlinable
        @inline(__always)
        public func query<T>(_ path: Path<T>, query queryItems: [URLQueryItem], all: Bool) -> Task<[T], Swift.Error> {
            
            return .init {
                let url = url
                    .appendingPathComponent(path.value)

                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.queryItems = queryItems
                
                var result: [T] = []
                guard let url = components?.url else {
                    print("input query parameters:\n \(queryItems.map { "\($0)\n" }))\n generates an invalid URL")
                    throw Error.invalidQuery
                }
                
                var page = 1
                let token = ""

                func fetch(request: URLRequest) async throws {
                    let (data, _) = try await URLSession.shared.data(for: request)
                    
                    result += try path.decode(data)
                    if all {
                        if result.count == page * 100 {
                            components?.queryItems?.removeAll(where: { $0.name == "page" })
                            page += 1
                            components?.queryItems?.append(URLQueryItem(name: "page", value: "\(page)"))
                            guard let url = components?.url else {
                                print("input query parameters:\n \(queryItems.map { "\($0)\n" }))\n generates an invalid URL")
                                throw Error.invalidQuery
                            }
                            var request = URLRequest(url: url)
                            
                            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
                            try await fetch(request: request)
                        }
                    }
                }
                var request = URLRequest(url: url)
                request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
                try await fetch(request: request)
                print("Retrieved \(result.count) \(path.description)")
                return result
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
