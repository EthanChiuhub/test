import Foundation
import SwiftData

@Model
class Video {
    var id: UUID
    var url: URL
    var timestamp: Date
    
    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.timestamp = Date()
    }
} 