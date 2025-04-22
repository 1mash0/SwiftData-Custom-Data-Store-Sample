import FluentKit
import Foundation
import Hummingbird
import HummingbirdFluent
import NIO

//struct ItemController<Context: MyRequestContextProtocol> {
struct ItemController<Context: RequestContext> {
    let fluent: Fluent
    
    func addRoutes(to group: RouterGroup<Context>) {
        group
            .get(use: fetchItems)
            .post(use: registerItems)
            .patch(use: deleteItems)
    }
    
    @Sendable
    func fetchItems(_ request: Request, context: Context) async throws -> [Item] {
        do {
            return try await Item.query(on: fluent.db()).filter(\.$isDeleted == false).all()
        } catch {
            print(error)
            return []
        }
    }
    
    @Sendable
    func registerItems(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        do {
//            let requestItem = try await context.requestDecoder.decode([Item].self, from: request, context: context)
            let requestItem = try await request.decode(as: [Item].self, context: context)
            for item in requestItem {
                try await item.save(on: fluent.db())
            }
            return .ok
        } catch {
            print(error)
            return .badRequest
        }
    }
    
    @Sendable
    func deleteItems(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        do {
            let deleteIDs = try await request.decode(as: [Item].self, context: context).compactMap { $0.id }
            
            if deleteIDs.isEmpty {
                return .notFound
            }
            
            let db = fluent.db()
            
            for deleteID in deleteIDs {
                guard let item = try await Item.query(on: db).filter(\.$id == deleteID).first() else {
                    continue
                }
                item.delete()
                try await item.update(on: db)
            }
            return .ok
        } catch {
            print(error)
            return .badRequest
        }
    }
}
