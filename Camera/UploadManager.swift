import Foundation
import SwiftData
import BackgroundTasks

class UploadManager: NSObject, ObservableObject {
    @Published private(set) var uploadQueue: [VideoUploadInfo] = []
    @Published var currentUploadProgress: Double = 0
    @Published var isUploading = false
    
    private let uploadQueue = DispatchQueue(label: "com.yourapp.uploadQueue", qos: .background)
    private var backgroundCompletionHandler: (() -> Void)?
    private let session: URLSession
    
    override init() {
        let config = URLSessionConfiguration.background(withIdentifier: "com.yourapp.videoUpload")
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = false
        
        session = URLSession(configuration: config)
        super.init()
        session.delegate = self
    }
    
    func addToQueue(source: URL, destination: URL) -> Bool {
        // 檢查是否已經在佇列中
        if uploadQueue.contains(where: { $0.sourceURL == source }) {
            return false
        }
        
        // 檢查檔案是否存在
        guard FileManager.default.fileExists(atPath: source.path) else {
            return false
        }
        
        let uploadInfo = VideoUploadInfo(sourceURL: source, destinationURL: destination)
        uploadQueue.append(uploadInfo)
        
        if !isUploading {
            processNextUpload()
        }
        
        return true
    }
    
    private func processNextUpload() {
        guard let uploadIndex = uploadQueue.firstIndex(where: { $0.status == .notStarted }) else {
            DispatchQueue.main.async {
                self.isUploading = false
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isUploading = true
            self.uploadQueue[uploadIndex].status = .uploading
        }
        
        let uploadInfo = uploadQueue[uploadIndex]
        startUpload(uploadInfo: uploadInfo, at: uploadIndex)
    }
    
    private func startUpload(uploadInfo: VideoUploadInfo, at index: Int) {
        // 建立上傳請求
        var request = URLRequest(url: URL(string: "YOUR_UPLOAD_API_ENDPOINT")!)
        request.httpMethod = "POST"
        
        // 添加必要的 headers
        request.setValue("video/quicktime", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer YOUR_AUTH_TOKEN", forHTTPHeaderField: "Authorization")
        
        // 創建上傳任務
        let uploadTask = session.uploadTask(with: request, fromFile: uploadInfo.sourceURL) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.handleUploadError(error, for: uploadInfo, at: index)
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    self.handleUploadSuccess(for: uploadInfo, at: index)
                } else {
                    self.handleUploadError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"]), for: uploadInfo, at: index)
                }
            }
        }
        
        // 設置進度追蹤
        let observation = uploadTask.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                self.currentUploadProgress = progress.fractionCompleted
                self.uploadQueue[index].progress = progress.fractionCompleted
            }
        }
        
        // 開始上傳
        uploadTask.resume()
    }
    
    private func handleUploadSuccess(for uploadInfo: VideoUploadInfo, at index: Int) {
        uploadQueue[index].status = .completed
        completeCurrentUpload(uploadInfo: uploadInfo)
    }
    
    private func handleUploadError(_ error: Error, for uploadInfo: VideoUploadInfo, at index: Int) {
        uploadQueue[index].status = .failed(error)
        // 可以在這裡添加重試邏輯
        completeCurrentUpload(uploadInfo: uploadInfo)
    }
    
    private func completeCurrentUpload(uploadInfo: VideoUploadInfo) {
        // 清理原始暫存影片
        try? FileManager.default.removeItem(at: uploadInfo.sourceURL)
        
        // 移除已完成的上傳
        uploadQueue.removeAll { $0.id == uploadInfo.id }
        
        // 處理下一個上傳
        if !uploadQueue.isEmpty {
            processNextUpload()
        } else {
            isUploading = false
            currentUploadProgress = 0
        }
    }
    
    func isVideoUploading(_ url: URL) -> Bool {
        uploadQueue.contains { $0.sourceURL == url && 
            (($0.status == .queued) || ($0.status == .uploading)) }
    }
}

// URLSession 背景任務處理
extension UploadManager: URLSessionDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        // 處理 session 失效的情況
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}

// 進度追蹤
extension UploadManager: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        DispatchQueue.main.async {
            if let index = self.uploadQueue.firstIndex(where: { $0.status == .uploading }) {
                self.currentUploadProgress = progress
                self.uploadQueue[index].progress = progress
            }
        }
    }
} 