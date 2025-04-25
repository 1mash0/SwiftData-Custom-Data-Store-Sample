import SwiftUI
import SwiftData

@main
struct CustomDataStoreApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(makeModelContainer(.local))
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
                    name: "LocalItem",
                    fileURL: fileURL
                )
            case .remote:
                return RemoteStoreConfiguration(
                    name: "RemoteItem",
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
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: configuration)
        }
        return try ModelContainer(for: schema, configurations: [type.modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
