// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Hummingbird
import HummingbirdFluent
import Foundation

@main
struct Server: AsyncParsableCommand {
    func run() async throws {
        let app = try await buildApplication()
        try await app.runService()
    }
}

struct MyRequestDecoder: RequestDecoder {
    func decode<T>(
        _ type: T.Type,
        from request: Request,
        context: some RequestContext
    ) async throws -> T where T : Decodable {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try await decoder.decode(type, from: request, context: context)
    }
}

protocol MyRequestContextProtocol: RequestContext {}

struct MyRequestContext: MyRequestContextProtocol {
    var coreContext: Hummingbird.CoreRequestContextStorage
    
    init(source: Hummingbird.ApplicationRequestContextSource) {
        self.coreContext = .init(source: source)
    }
    
    var requestDecoder: RequestDecoder {
        MyRequestDecoder()
    }
}
