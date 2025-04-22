import FluentKit
import Foundation
import Hummingbird

final class Implementation: Fields, @unchecked Sendable {
    @Field(key: "entityName")
    var entityName: String
    
    @Field(key: "isTemporary")
    var isTemporary: Bool
    
    @Field(key: "primaryKey")
    var primaryKey: String
    
    @Field(key: "storeIdentifier")
    var storeIdentifier: String
    
    @Field(key: "typedPrimaryKey")
    var typedPrimaryKey: String
    
    @Field(key: "uriRepresentation")
    var uriRepresentation: String
    
    init() {}
    
    init(
        entityName: String,
        isTemporary: Bool,
        primaryKey: String,
        storeIdentifier: String,
        typedPrimaryKey: String,
        uriRepresentation: String
    ) {
        self.entityName = entityName
        self.isTemporary = isTemporary
        self.primaryKey = primaryKey
        self.storeIdentifier = storeIdentifier
        self.typedPrimaryKey = typedPrimaryKey
        self.uriRepresentation = uriRepresentation
    }
}

final class PersistentIdentifier: Fields, @unchecked Sendable {
    @Group(key: "implementation")
    var implementation: Implementation
    
    init() {}
    
    init(implementation: Implementation) {
        self.implementation = implementation
    }
}

final class Item: Model, @unchecked Sendable {
    static let schema = "items"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "timestamp")
    var timestamp: Date
    
    @Group(key: "persistentIdentifier")
    var persistentIdentifier: PersistentIdentifier
    
    @Field(key: "isDeleted")
    var isDeleted: Bool
    
    init() {}
    
    init(persistentIdentifier: PersistentIdentifier) {
        self.id = .init()
        self.timestamp = .now
        self.persistentIdentifier = persistentIdentifier
        self.isDeleted = false
    }
    
    func delete() {
        self.isDeleted = true
    }
}

extension Item: ResponseCodable {}
