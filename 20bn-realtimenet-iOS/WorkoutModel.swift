import UIKit
import Vision
import AVFoundation
import CoreMedia
import VideoToolbox
import MediaPlayer


protocol GUIControllerDelegate {
    func getOrientation() -> UIDeviceOrientation
    func emitPredictions(_ output: [[Float]], _ global_output: MLMultiArray)
}

// Interface for ViewController
protocol WorkoutsType {
    var cameraPermission: AVAuthorizationStatus { get }
    func requestCameraAccess(completion: @escaping (Bool) -> Void)
}


final class WorkoutModel: WorkoutsType {
    
    // Class declarations
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    var frameExtractor: FrameExtractor!
    var inference =  InferenceLocal()
    var motionManager = MotionManager()
    var cameraPermission: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    var isExercise = false
    
    // Variable declarations for video processing
    var resizedPixelBuffer: CVPixelBuffer?
    var frameCapturingStartTime = CACurrentMediaTime()
    var lastPredictionTime = CACurrentMediaTime()
    let fractionImageProcessRest = 1
    var numFrame = 0
    
    // Variable declarations for motion control
    var deviceOrientation = UIDevice.current.orientation
    var workoutStarted = false
    var cameraReady = false
    var viewAppeared = false
    
    var delegate: WorkoutModelDelegate? = nil
    //Coupon
    var lab2int: [String:Int] = [:]
    var int2lab: [Int:String] = [:]
    
    
    // MARK: Internal
    
    init() {
        inference.delegate = self
        frameCapturingStartTime = CACurrentMediaTime()
        motionManager.delegate = self
        if let path = Bundle.main.path(forResource: "realtimenet_labels", ofType: "json") {
            do {
                  let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                  let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                  if let jsonResult = jsonResult as? Dictionary<String, Int> {
                    lab2int = jsonResult
                    int2lab = Dictionary(uniqueKeysWithValues: lab2int.map({ ($1, $0) }))
                  }
              } catch {
              }
        }
    }
   
    
    func startWorkout() {

        UIApplication.shared.isIdleTimerDisabled = true

        // create and initialize video recorder
        
        // wait for camera and state machine to be ready
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if self.cameraReady {
                self.workoutStarted = true
                timer.invalidate()
                self.frameExtractor.delegate = self
                self.frameExtractor.start()
                self.lastPredictionTime = CACurrentMediaTime()
            }
        }
    }
    
    func goBackground() {
        if workoutStarted {
            frameExtractor.stop()
        }
    }
    
    func leaveBackground() {
        if workoutStarted {
            frameExtractor.delegate = self
            frameExtractor.start()
        }
    }
    
    func setUpCamera() {
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        frameExtractor.setUp { success in
            if success {
                self.frameExtractor.start()
                self.frameExtractor.stop()
                self.cameraReady = true
            } else{
                print("error: did not succeed to start frame extractor")
            }
        }
    }

    
    // MARK: GUIControllerDelegate Methods
    
    func emitPredictions(_ output: [[Float]], _ global_output: MLMultiArray) {
        let ptr = global_output.dataPointer
        let mem = ptr.bindMemory(to: Float32.self, capacity: InferenceLocal.dimGlobalClassifier)
        let global_out: Array? = Array(UnsafeBufferPointer(start: mem, count: InferenceLocal.dimGlobalClassifier))
        if let outputs = global_out {
            let time = CACurrentMediaTime()
            let elapsed = time - lastPredictionTime
            lastPredictionTime = time

            let softmax = self.softmax(logits: outputs)
            let maxIndice = softmax.argmax()
            if let maxPosition = maxIndice {
                let maxScore = softmax[maxPosition]
                var label = ""
                var score = ""
                if maxScore > 0.6 {
                    label = "\(int2lab[maxPosition]!)"
                    score = "\(Double(round(100*maxScore)))%"
                }
                delegate?.showPrediction(label: label, score: score)
            }
            
        }
        
        
    }
    
    func softmax(logits: [Float32]) -> [Float32] {
        var sumExps: Float32 = 0.0
        var exps = [Float32]()
        var softmax = [Float32]()
        for output in logits {
            let expValue = exp(output)
            exps.append(expValue)
            sumExps += expValue
        }
        for exp in exps {
            softmax.append(exp / sumExps)
        }
        return softmax
    }

     
    // MARK: WorkoutType Methods
     
    func requestCameraAccess(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            completion(granted)
        }
    }
    
    private func processPrediction(pixelBuffer: CVPixelBuffer) {
        // Resize the input with Core Image to the desired output.
        let srcWidth = CVPixelBufferGetWidth(pixelBuffer)
        let srcHeight = CVPixelBufferGetHeight(pixelBuffer)
        guard let resizedPixelBuffer = resizePixelBuffer(pixelBuffer,
                                                         width: InferenceLocal.inputWidth,
                                                         height: InferenceLocal.inputHeight) else { return }
        
        
        // Rotate input accordingly and give it to our model.
        var rotatedBuffer: CVPixelBuffer?
        var noRotation = false
        var transform = CGAffineTransform(scaleX: -1, y: 1)
        switch self.deviceOrientation {
        case .portraitUpsideDown:
            rotatedBuffer = rotate90PixelBuffer(resizedPixelBuffer, factor: 2)
            transform = CGAffineTransform(scaleX: 1, y: 1)
        default:
            noRotation = true
        }
        
        if noRotation {
            let padded = resizedPixelBuffer
            delegate?.showDebugImage(padded, transform: transform)
            if isExercise {
                inference.collectFrames(imageBuffer: padded)
            } else {
                numFrame += 1
                if numFrame == fractionImageProcessRest {
                    numFrame = 0
                    inference.collectFrames(imageBuffer: padded)
                }
            }
        } else {
            let padded = rotatedBuffer!
            delegate?.showDebugImage(padded, transform: transform)
            if isExercise {
                inference.collectFrames(imageBuffer: padded)
            } else {
                numFrame += 1
                if numFrame == fractionImageProcessRest {
                    numFrame = 0
                    inference.collectFrames(imageBuffer: padded)
                }
            }
        }
    }
    
    private func endWorkout() {
        workoutStarted = false
        frameExtractor.stop()

        
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        
    }
}


extension WorkoutModel: GUIControllerDelegate{

    func getOrientation() -> UIDeviceOrientation {
        return self.deviceOrientation
    }
}

extension WorkoutModel: MotionManagerDelegate {
    public func rotated(_ orientation: UIDeviceOrientation) {
        self.deviceOrientation = orientation
        // Handle rotation
        print(self.deviceOrientation)
    }
}


extension WorkoutModel: FrameExtractorDelegate {
    func captured(_ capture: FrameExtractor, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?) {
        if let pixelBuffer = pixelBuffer {
            DispatchQueue.global().async {
                self.processPrediction(pixelBuffer: pixelBuffer)
            }
        }
    }
}
