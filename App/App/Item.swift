import Foundation
import SwiftData

@Model
class Item {
    #Unique<Item>([\.id])
    
    var id: UUID
    var timestamp: Date
    var isDeleted: Bool
    
    init(isDeleted: Bool = false) {
        self.id = .init()
        self.timestamp = .now
        self.isDeleted = isDeleted
    }
}
