import Foundation

enum UploadStatus: Equatable {
    case notStarted
    case queued
    case uploading
    case completed
    case failed(Error)
    
    // 自定義 Equatable 實作，因為 Error 不遵循 Equatable
    static func == (lhs: UploadStatus, rhs: UploadStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
             (.queued, .queued),
             (.uploading, .uploading),
             (.completed, .completed):
            return true
        case (.failed, .failed):
            return true  // 我們只比較是否都是失敗狀態，不比較具體錯誤
        default:
            return false
        }
    }
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