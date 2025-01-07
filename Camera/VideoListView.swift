import SwiftUI
import SwiftData
import AVKit

struct VideoListView: View {
    @Query(sort: \Video.timestamp, order: .reverse) private var videos: [Video]
    @State private var selectedVideo: Video?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            ForEach(videos) { video in
                VideoRow(video: video)
                    .onTapGesture {
                        selectedVideo = video
                    }
            }
        }
        .sheet(item: $selectedVideo) { video in
            VideoPlayer(player: AVPlayer(url: video.url))
        }
        .onAppear {
            // 確保只保留最新的5部影片
            if videos.count > 5 {
                let videosToDelete = videos[5...]
                for video in videosToDelete {
                    // 刪除檔案
                    try? FileManager.default.removeItem(at: video.url)
                    // 從 SwiftData 中刪除
                    modelContext.delete(video)
                }
                try? modelContext.save()
            }
        }
    }
}

struct VideoRow: View {
    let video: Video
    
    var body: some View {
        HStack {
            Image(systemName: "video.fill")
            Text(video.timestamp.formatted())
        }
    }
} 