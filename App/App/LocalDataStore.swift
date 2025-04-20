import Foundation
import SwiftData

final class LocalStoreConfiguration: DataStoreConfiguration {
    typealias Store = LocalDataStore
    
    var name: String
    var schema: Schema?
    var fileURL: URL
    
    init(name: String, schema: Schema? = nil, fileURL: URL) {
        self.name = name
        self.schema = schema
        self.fileURL = fileURL
    }
    
    static func == (lhs: LocalStoreConfiguration, rhs: LocalStoreConfiguration) -> Bool {
        lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

final class LocalDataStore: DataStore {
    typealias Configuration = LocalStoreConfiguration
    typealias Snapshot = DefaultSnapshot
    
    var configuration: LocalStoreConfiguration
    var name: String
    var schema: Schema
    var identifier: String
    
    init(_ configuration: LocalStoreConfiguration, migrationPlan: (any SchemaMigrationPlan.Type)?) throws {
        self.configuration = configuration
        self.name = configuration.name
        self.schema = configuration.schema!
        self.identifier = configuration.fileURL.lastPathComponent
    }
    
    func fetch<T>(_ request: DataStoreFetchRequest<T>) throws -> DataStoreFetchResult<T, DefaultSnapshot> where T : PersistentModel {
        if request.descriptor.predicate != nil {
            throw DataStoreError.preferInMemoryFilter
        } else if request.descriptor.sortBy.count > 0 {
            throw DataStoreError.preferInMemorySort
        }
        
        let objects = try self.read()
        let snapshot = objects.values.map { $0 }
        return .init(descriptor: request.descriptor, fetchedSnapshots: snapshot)
    }
    
    func save(_ request: DataStoreSaveChangesRequest<DefaultSnapshot>) throws -> DataStoreSaveChangesResult<DefaultSnapshot> {
        var remappedIdentifiers = [PersistentIdentifier: PersistentIdentifier]()
        var serializedItems = try self.read()
        
        for snapshot in request.inserted {
            let permanentIdentifier = try PersistentIdentifier.identifier(
                for: identifier,
                entityName: snapshot.persistentIdentifier.entityName,
                primaryKey: UUID()
            )
            
            let permanentSnapshot = snapshot.copy(persistentIdentifier: permanentIdentifier)
            serializedItems[permanentIdentifier] = permanentSnapshot
            remappedIdentifiers[snapshot.persistentIdentifier] = permanentIdentifier
        }
        
        for snapshot in request.updated {
            serializedItems[snapshot.persistentIdentifier] = snapshot
        }
        
        for snapshot in request.deleted {
            serializedItems[snapshot.persistentIdentifier] = nil
        }
        
        try self.write(serializedItems)
        
        return .init(for: self.identifier, remappedIdentifiers: remappedIdentifiers, snapshotsToReregister: serializedItems)
    }
    
    private func read() throws -> [PersistentIdentifier: DefaultSnapshot] {
        guard FileManager.default.fileExists(atPath: configuration.fileURL.path(percentEncoded: false)) else {
            return [:]
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let items = try decoder.decode([DefaultSnapshot].self, from: try Data(contentsOf: configuration.fileURL))
        var result = [PersistentIdentifier: DefaultSnapshot]()
        items.forEach {
            result[$0.persistentIdentifier] = $0
        }
        
        return result
    }
    
    private func write(_ items: [PersistentIdentifier: DefaultSnapshot]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(items.values.map({ $0 }))
        try jsonData.write(to: configuration.fileURL)
    }
}
