// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Hummingbird
import Foundation

nonisolated(unsafe) var items: [Item] = []

@main
struct Server: AsyncParsableCommand {
    func run() async throws {
        let app = try await buildApplication()
        try await app.runService()
    }
}

func buildApplication() async throws -> some ApplicationProtocol {
    //    let router = Router(context: MyRequestContext.self)
    let router = Router()
    
    router.middlewares.add(LogRequestsMiddleware(.info))
    router.middlewares.add(FileMiddleware())
    router.middlewares.add(
        CORSMiddleware(
            allowOrigin: .originBased,
            allowHeaders: [.contentType],
            allowMethods: [.get, .post, .patch]
        )
    )
    
    router.get("/health") { _, _ -> HTTPResponse.Status in
            .ok
    }
    
    ItemController().addRoutes(to: router.group("items"))
    
    return Application(
        router: router,
        configuration: .init(
            address: .hostname(
                "localhost",
                port: 8080
            )
        )
    )
}

//struct ItemController<Context: MyRequestContextProtocol> {
struct ItemController<Context: RequestContext> {
    func addRoutes(to group: RouterGroup<Context>) {
        group
            .get(use: fetchItems)
            .post(use: registerItems)
            .patch(use: deleteItems)
    }
    
    @Sendable
    func fetchItems(_ request: Request, context: Context) async throws -> [Item] {
        items
    }
    
    @Sendable
    func registerItems(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        do {
            //            let requestItem = try await context.requestDecoder.decode([Item].self, from: request, context: context)
            let requestItem = try await request.decode(as: [Item].self, context: context)
            items.append(contentsOf: requestItem)
            return .ok
        } catch {
            print(error)
            return .badRequest
        }
    }
    
    @Sendable
    func deleteItems(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        do {
            let deleteIds = try await request.decode(as: [Item].self, context: context).map({ $0.id })
            items.removeAll(where: ({ deleteIds.contains($0.id) }))
            return .ok
        } catch {
            print(error)
            return .badRequest
        }
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

struct Item: Codable {
    var id: UUID
    var persistentIdentifier: PersistentIdentifier
    var timestamp: Date
    
    init(persistentidentifier: PersistentIdentifier) {
        self.id = UUID()
        self.persistentIdentifier = persistentidentifier
        self.timestamp = Date()
    }
}

struct PersistentIdentifier: Codable {
    struct Implementation: Codable {
        let entityName: String
        let isTemporary: Bool
        let primaryKey: String
        let storeIdentifier: String
        let typedPrimaryKey: String
        let uriRepresentation: String
    }
    
    let implementation: Implementation
}
