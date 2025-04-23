import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp) private var items: [Item]
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        VStack {
                            Text("timestamp: \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        }
                        .navigationTitle(item.id.uuidString)
                    } label: {
                        Text(item.id.uuidString)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: fetch) {
                        Label("Reload Item", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
    
    private func fetch() {
        let descriptor = FetchDescriptor<Item>()
        do {
            _ = try modelContext.fetch(descriptor)
        } catch {
            print(error)
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item()
            modelContext.insert(newItem)
            do {
                try modelContext.save()
            } catch {
                print(error)
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
                do {
                    try modelContext.save()
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
