import Foundation
import AVFoundation

class CameraManager: NSObject, ObservableObject {
    @Published var error: Error?
    @Published var session = AVCaptureSession()
    @Published var lastRecordedVideoURL: URL?
    private let captureQueue = DispatchQueue(label: "com.yourapp.captureQueue", qos: .userInitiated)
    private let videoOutput = AVCaptureMovieFileOutput()
    private var isRecording = false
    private var isConfigured = false
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 確保在主線程更新 UI 相關的屬性
            DispatchQueue.main.async {
                self.isConfigured = false
            }
            
            self.session.beginConfiguration()
            
            // 添加視訊輸入
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                          for: .video,
                                                          position: .back) else {
                DispatchQueue.main.async {
                    self.error = NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "無法存取相機"])
                }
                return
            }
            
            guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                DispatchQueue.main.async {
                    self.error = NSError(domain: "", code: 2, userInfo: [NSLocalizedDescriptionKey: "無法創建視訊輸入"])
                }
                return
            }
            
            // 添加音訊輸入
            guard let audioDevice = AVCaptureDevice.default(for: .audio),
                  let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
                DispatchQueue.main.async {
                    self.error = NSError(domain: "", code: 3, userInfo: [NSLocalizedDescriptionKey: "無法創建音訊輸入"])
                }
                return
            }
            
            guard self.session.canAddInput(videoInput) && self.session.canAddInput(audioInput) else {
                DispatchQueue.main.async {
                    self.error = NSError(domain: "", code: 4, userInfo: [NSLocalizedDescriptionKey: "無法添加輸入"])
                }
                return
            }
            
            self.session.addInput(videoInput)
            self.session.addInput(audioInput)
            
            // 添加視訊輸出
            guard self.session.canAddOutput(self.videoOutput) else {
                DispatchQueue.main.async {
                    self.error = NSError(domain: "", code: 5, userInfo: [NSLocalizedDescriptionKey: "無法添加輸出"])
                }
                return
            }
            
            self.session.addOutput(self.videoOutput)
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.isConfigured = true
            }
        }
    }
    
    func startSession() {
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.isConfigured else { return }
            
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.session.isRunning else { return }
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let videoName = "video-\(Date().timeIntervalSince1970).mov"
            let videoPath = documentsPath.appendingPathComponent(videoName)
            
            self.videoOutput.startRecording(to: videoPath, recordingDelegate: self)
            DispatchQueue.main.async {
                self.isRecording = true
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.videoOutput.stopRecording()
            DispatchQueue.main.async {
                self.isRecording = false
            }
        }
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.error = error
            }
        } else {
            DispatchQueue.main.async {
                self.lastRecordedVideoURL = outputFileURL
            }
        }
    }
} 
