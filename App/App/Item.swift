import Foundation
import SwiftData

@Model
class Item: Codable {
    #Unique<Item>([\.id])
    
    var id: UUID
    var timestamp: Date
    
    init() {
        self.id = UUID()
        self.timestamp = Date()
    }
    
    enum CodingKeys: CodingKey {
        case id
        case timestamp
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
    }
}
