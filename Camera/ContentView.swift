//
//  ContentView.swift
//  Camera
//
//  Created by Yi Chun Chiu on 2025/1/7.
//

import SwiftUI
import AVFoundation
import SwiftData

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var uploadManager = UploadManager()
    @State private var isRecording = false
    @State private var showingVideoList = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            if let videoURL = cameraManager.lastRecordedVideoURL {
                // 顯示錄影預覽
                VideoPreviewView(videoURL: videoURL)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            // 返回相機
                            cameraManager.lastRecordedVideoURL = nil
                        }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if !uploadManager.isVideoUploading(videoURL) {
                                uploadVideo(url: videoURL)
                            }
                        }) {
                            HStack {
                                Image(systemName: "icloud.and.arrow.up.fill")
                                Text(uploadManager.isVideoUploading(videoURL) ? "上傳中..." : "上傳")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(uploadManager.isVideoUploading(videoURL) ? Color.gray : Color.blue)
                            .cornerRadius(10)
                        }
                        .disabled(uploadManager.isVideoUploading(videoURL))
                    }
                    .padding()
                }
            } else {
                // 顯示相機預覽
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Button(action: {
                        if isRecording {
                            cameraManager.stopRecording()
                        } else {
                            cameraManager.startRecording()
                        }
                        isRecording.toggle()
                    }) {
                        Circle()
                            .fill(isRecording ? .red : .white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .padding(.bottom, 30)
                    }
                }
            }
            
            // 在相機預覽模式下添加一個按鈕來顯示影片列表
            if cameraManager.lastRecordedVideoURL == nil {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingVideoList = true
                        }) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                    // ... 現有的錄影按鈕 ...
                }
            }
            
            // 顯示網路錯誤
            if let networkError = uploadManager.networkError {
                VStack {
                    Text(networkError)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .alert("錯誤", isPresented: .constant(cameraManager.error != nil)) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(cameraManager.error?.localizedDescription ?? "未知錯誤")
        }
        .overlay(
            Group {
                if uploadManager.isUploading {
                    UploadProgressView(progress: uploadManager.currentUploadProgress)
                }
            }
        )
        .sheet(isPresented: $showingVideoList) {
            VideoListView()
        }
    }
    
    private func uploadVideo(url: URL) {
        // 上傳前檢查網路狀態
        if !uploadManager.networkMonitor.isConnected {
            // 可以選擇顯示警告或將影片加入等待佇列
            return
        }
        
        // 複製影片到 App 的永久儲存空間
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("videos/\(UUID().uuidString).mov")
        
        // 確保 videos 目錄存在
        try? fileManager.createDirectory(at: documentsPath.appendingPathComponent("videos"),
                                       withIntermediateDirectories: true)
        
        do {
            // 如果目標位置已存在檔案，先刪除
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // 複製影片檔案
            try fileManager.copyItem(at: url, to: destinationURL)
            
            // 檢查現有影片數量
            let fetchDescriptor = FetchDescriptor<Video>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
            if let existingVideos = try? modelContext.fetch(fetchDescriptor) {
                if existingVideos.count >= 5 {
                    let oldestVideos = existingVideos[4...]
                    for oldVideo in oldestVideos {
                        try? FileManager.default.removeItem(at: oldVideo.url)
                        modelContext.delete(oldVideo)
                    }
                }
            }
            
            // 儲存新影片到 SwiftData
            let video = Video(url: destinationURL)
            modelContext.insert(video)
            try modelContext.save()
            
            // 加入上傳佇列
            uploadManager.addToQueue(source: url, destination: destinationURL)
            
            // 返回相機預覽
            cameraManager.lastRecordedVideoURL = nil
            
        } catch {
            print("Error saving video: \(error)")
        }
    }
}

struct UploadProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack {
            ProgressView("上傳中...", value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()
        }
        .frame(maxWidth: 200)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
