import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // 保存 completion handler 以供稍後使用
        if identifier == "com.yourapp.videoUpload" {
            // 假設 UploadManager 是一個單例或可以通過某種方式訪問
            // uploadManager.backgroundCompletionHandler = completionHandler
        }
    }
} 