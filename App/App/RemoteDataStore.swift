import Foundation
import SwiftData

final class RemoteStoreConfiguration: DataStoreConfiguration {
    typealias Store = RemoteDataStore
    
    var name: String
    var schema: Schema?
    var endpoint: URL
    
    init(name: String, schema: Schema? = nil, endpoint: URL) {
        self.name = name
        self.schema = schema
        self.endpoint = endpoint
    }
    
    static func == (lhs: RemoteStoreConfiguration, rhs: RemoteStoreConfiguration) -> Bool {
        lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

final class RemoteDataStore: DataStore {
    typealias Configuration = RemoteStoreConfiguration
    typealias Snapshot = DefaultSnapshot
    
    var configuration: RemoteStoreConfiguration
    var name: String
    var schema: Schema
    var identifier: String
    
    init(_ configuration: RemoteStoreConfiguration, migrationPlan: (any SchemaMigrationPlan.Type)?) throws {
        self.configuration = configuration
        self.name = configuration.name
        self.schema = configuration.schema!
        self.identifier = configuration.endpoint.lastPathComponent
    }
    
    func fetch<T>(_ request: DataStoreFetchRequest<T>) throws -> DataStoreFetchResult<T, DefaultSnapshot> where T : PersistentModel {
        var result: Result<[DefaultSnapshot], Error>!
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            defer { semaphore.signal() }
            
            do {
                let snapshot: [DefaultSnapshot] = try await APIClient.fetch()
                result = .success(snapshot)
            } catch {
                print(error)
                result = .failure(error)
            }
        }
        semaphore.wait()
        
        return .init(descriptor: request.descriptor, fetchedSnapshots: try result.get())
    }
    
    func save(_ request: DataStoreSaveChangesRequest<DefaultSnapshot>) throws -> DataStoreSaveChangesResult<DefaultSnapshot> {
        let semaphore = DispatchSemaphore(value: 0)
        let identifier = identifier
        
        Task {
            defer { semaphore.signal() }
            
            do {
                let insertItems = try request.inserted.map {
                    let persistentIdentifier = try PersistentIdentifier.identifier(
                        for: identifier,
                        entityName: $0.persistentIdentifier.entityName,
                        primaryKey: UUID()
                    )
                    return $0.copy(persistentIdentifier: persistentIdentifier)
                }
                
                if !insertItems.isEmpty {
                    try await APIClient.register(insertItems)
                }
                
//                for snapshot in request.updated {
//
//                }

//                for snapshot in request.deleted {
//
//                }
            } catch {
                print(error)
            }
        }
        semaphore.wait()
        
        return .init(for: identifier)
    }
}
