import Foundation

enum UploadStatus {
    case notStarted
    case queued
    case uploading
    case completed
    case failed(Error)
}

struct VideoUploadInfo: Identifiable {
    let id: UUID
    let sourceURL: URL
    let destinationURL: URL
    var status: UploadStatus
    var progress: Double
    
    init(sourceURL: URL, destinationURL: URL) {
        self.id = UUID()
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.status = .notStarted
        self.progress = 0
    }
} 