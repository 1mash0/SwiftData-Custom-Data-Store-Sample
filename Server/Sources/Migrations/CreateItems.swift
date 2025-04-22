import FluentKit

struct CreateItems: AsyncMigration {
    func prepare(on database: any FluentKit.Database) async throws {
        return try await database.schema("items")
            .id()
            .field("timestamp",  .date, .required)
            .field("persistentIdentifier_implementation_entityName", .string, .required)
            .field("persistentIdentifier_implementation_isTemporary", .bool, .required)
            .field("persistentIdentifier_implementation_primaryKey", .string, .required)
            .field("persistentIdentifier_implementation_storeIdentifier", .string, .required)
            .field("persistentIdentifier_implementation_typedPrimaryKey", .string, .required)
            .field("persistentIdentifier_implementation_uriRepresentation", .string, .required)
            .field("isDeleted", .bool, .required)
            .unique(on: .id)
            .create()
    }
    
    func revert(on database: any FluentKit.Database) async throws {
        return try await database.schema("items").delete()
    }
    
}
