import SwiftUI
import SwiftData

@main
struct CustomDataStoreApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(makeModelContainer())
    }
}

enum ModelContainerType {
    case local
    case remote
    
    var modelConfiguration: any DataStoreConfiguration {
        switch self {
            case .local:
                let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("item.json")
                return LocalStoreConfiguration(
                    name: "item",
                    fileURL: fileURL
                )
            case .remote:
                return RemoteStoreConfiguration(
                    name: "item",
                    endpoint: URL(string:"http://localhost:8080/items")!
                )
        }
    }
}

func makeModelContainer(_ type: ModelContainerType? = nil) -> ModelContainer {
    let schema = Schema([
        Item.self,
    ])
    do {
        guard let type = type else {
            return try ModelContainer(for: schema, configurations: .init(isStoredInMemoryOnly: false))
        }
        return try ModelContainer(for: schema, configurations: [type.modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
