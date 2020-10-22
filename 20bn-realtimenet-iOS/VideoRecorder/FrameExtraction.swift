//
//  FrameExtraction.swift
//  python-ios-integration
//
//  Created by Rakeeb Hossain on 2019-06-20.
//  Copyright © 2019 20bn. All rights reserved.
//

import UIKit
import AVFoundation
import CoreVideo
import Accelerate

public protocol FrameExtractorDelegate: class {
    func captured(_ capture: FrameExtractor, didCaptureVideoFrame: CVPixelBuffer?)
}

public class FrameExtractor: NSObject {
    public var previewLayer: AVCaptureVideoPreviewLayer?
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
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        previewLayer.connection?.videoOrientation = .portrait
        // previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        // previewLayer.connection?.isVideoMirrored = true

        self.previewLayer = previewLayer
        
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
    
    private func resizePixelBuffer_Accelerate(imageBuffer: CVPixelBuffer, scaleWidth: Int, scaleHeight: Int) -> CVPixelBuffer? {
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else {return nil}
        let bytes_per_row = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        // Allocate input buffer
        var inBuff = vImage_Buffer(data: baseAddress, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: bytes_per_row)
        defer { free(inBuff.data) }
        
        // Allocate output container
        let outData = UnsafeMutablePointer<UInt8>.allocate(capacity: 4*scaleWidth*scaleHeight)
        defer { outData.deallocate() }
 
        // Assign output buffer
        var outBuff = vImage_Buffer(data: outData, height: vImagePixelCount(scaleHeight), width: vImagePixelCount(scaleWidth), rowBytes: 4*scaleWidth)
        defer { free(outBuff.data) }
        
        let releaseCallback: CVPixelBufferReleaseBytesCallback = {_, ptr in
            if let ptr = ptr {
                free(UnsafeMutableRawPointer(mutating: ptr))
            }
        }
        // Assign output data
        let error = vImageScale_ARGB8888(&inBuff, &outBuff, nil, vImage_Flags(kvImageHighQualityResampling))
        guard error == kvImageNoError else {return nil}
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        var dstPixelBuffer: CVPixelBuffer?
        let pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer)
        let status = CVPixelBufferCreateWithBytes(nil, scaleWidth, scaleHeight, pixelFormat, outData, bytes_per_row, releaseCallback, nil, nil, &dstPixelBuffer)
        guard status == kCVReturnSuccess else {return nil}
        return dstPixelBuffer
    }
    
    private func resizePixelBuffer(imageBuffer: CVPixelBuffer, scaleWidth: Int, scaleHeight: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil, scaleWidth, scaleHeight,
                                         kCVPixelFormatType_32BGRA, nil,
                                         &pixelBuffer)
        if status != kCVReturnSuccess {
            print("Error: could not create pixel buffer", status)
            return nil
        }
        
        let ciimage = CIImage(cvPixelBuffer: imageBuffer)
        let sx = CGFloat(scaleWidth) / CGFloat(CVPixelBufferGetWidth(imageBuffer))
        let sy = CGFloat(scaleHeight) / CGFloat(CVPixelBufferGetHeight(imageBuffer))
        let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
        let scaledImage = ciimage.transformed(by: scaleTransform)
        let context = CIContext()
        context.render(scaledImage, to: pixelBuffer!)
        return pixelBuffer
    }

    /*
    // MARK: Sample buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CVPixelBuffer? {
        // Try and edit this function to return scaled down CMSampleBuffer to remove unnecessary conversion to CIImage, CGImage, UIImage, then byte array
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        guard let resizedBuffer = resizePixelBuffer(imageBuffer: imageBuffer, scaleWidth: 416, scaleHeight: 416) else {return nil}
        return resizedBuffer
        /*
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let resizedImage = ciImage.transformed(by: CGAffineTransform(scaleX: 224.0 / CGFloat(width), y: 224.0 / CGFloat(height)))
        return resizedImage
        */
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    public func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cvPixelBuffer = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.captured(buffer: cvPixelBuffer)
        }
    }
    */
}

extension FrameExtractor: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Because lowering the capture device's FPS looks ugly in the preview,
        // we capture at full speed but only call the delegate at its desired
        // framerate.
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
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
        //print("dropped frame")
    }
}
