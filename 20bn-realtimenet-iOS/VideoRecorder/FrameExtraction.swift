import UIKit
import AVFoundation
import CoreVideo
import Accelerate

public protocol FrameExtractorDelegate: class {
    func captured(_ capture: FrameExtractor, didCaptureVideoFrame: CVPixelBuffer?)
}

public class FrameExtractor: NSObject {
    weak var delegate: FrameExtractorDelegate?
    public var fps = 16
    public var fps2 = 30
    public var deviceOrientation = "portrait"

    private var position = AVCaptureDevice.Position.front
    private let quality = AVCaptureSession.Preset.vga640x480
    
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let context = CIContext()
    
    private var lastTimestamp = CACurrentMediaTime()
    private var lastTimestamp2 = CACurrentMediaTime()
    override init() { }
    
    public func setUp(completion: @escaping (Bool) -> Void) {
        checkPermission()
        
        sessionQueue.async {
            let success = self.configureSession()
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    // MARK: AVSession configuration
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            permissionGranted = true
        default:
            permissionGranted = false
        }
    }
    
    func configureSession() -> Bool {
        guard permissionGranted else { return false }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = quality
        guard let captureDevice = selectCaptureDevice() else { return false }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return false }
        guard captureSession.canAddInput(captureDeviceInput) else { return false }
        captureSession.addInput(captureDeviceInput)
        
        let settings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]

        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = settings
        
        guard captureSession.canAddOutput(videoOutput) else { return false }
        captureSession.addOutput(videoOutput)
        
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait
        videoOutput.connection(with: AVMediaType.video)?.isVideoMirrored = false
        captureSession.commitConfiguration()
        return true
    }
    
    private func selectCaptureDevice() -> AVCaptureDevice? {
        if position == .front {
            return AVCaptureDevice.default(.builtInWideAngleCamera,
                                           for: AVMediaType.video,
                                           position: .front)
        }
        else {
            return AVCaptureDevice.default(.builtInWideAngleCamera,
                                           for: AVMediaType.video,
                                           position: .back)
        }
        
    }
    
    public func start() {
        if (!captureSession.isRunning) {
            captureSession.startRunning()
        }
    }
    
    public func stop() {
        if (captureSession.isRunning) {
            captureSession.stopRunning()
        }
    }
}

extension FrameExtractor: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Because lowering the capture device's FPS looks ugly in the preview,
        // we capture at full speed but only call the delegate at its desired
        // framerate.
        let currentTime = CACurrentMediaTime()
        
        // send image to neural network
        let deltaTime = currentTime - lastTimestamp
        if deltaTime >= (1 / Double(fps)) {
            // update time by adding the delta, and not taking the current time
            while lastTimestamp + (1 / Double(fps)) <= currentTime{
                lastTimestamp = lastTimestamp + (1 / Double(fps))
            }
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            delegate?.captured(self, didCaptureVideoFrame: imageBuffer)
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    }
}
