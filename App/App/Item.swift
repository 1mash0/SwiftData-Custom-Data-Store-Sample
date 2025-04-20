import Foundation
import SwiftData

@Model
class Item {
    #Unique<Item>([\.id])
    
    var id: UUID
    var timestamp: Date
    
    init() {
        self.id = UUID()
        self.timestamp = Date()
    }
}
