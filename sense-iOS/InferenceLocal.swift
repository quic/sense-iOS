import Foundation
import CoreML
import Accelerate
import AVFoundation


class InferenceLocal : NSObject {
    
    var delegate: GUIControllerDelegate?
    var modelRunning = false
    public static let inputWidth: Int = 160
    public static let inputHeight: Int = 224
    public static let maxBoundingBoxes = 3
    public static let dimGlobalClassifier = 30

    
    struct Prediction {
        let classIndex: Int
        let score: Float
        let rect: CGRect
    }
    
    var startTime = CACurrentMediaTime()
    var model = sensenet()
    
    var numFrames = -2
    var frames = [CVPixelBuffer]()
    var framesForPrediction = [CVPixelBuffer]()
    var cache_initialized = false
    var cachedOutputs0: sensenetOutput? = nil
    var cachedOutputs1: sensenetOutput? = nil
    var numFramePrediction = 4
    
    
    
    private func init_cache() {
        // cached_outputs_0 is the most recent output
        cachedOutputs0 = sensenetOutput.init(cnn_3_save_0: try! MLMultiArray(shape: [32,56,40], dataType: MLMultiArrayDataType.float32), cnn_3_save_1: try! MLMultiArray(shape: [32,56,40], dataType: MLMultiArrayDataType.float32), cnn_7_save_0: try! MLMultiArray(shape: [56,28,20], dataType: MLMultiArrayDataType.float32), cnn_11_save_0: try! MLMultiArray(shape: [112,14,10], dataType: MLMultiArrayDataType.float32), cnn_11_save_1: try! MLMultiArray(shape: [112,14,10], dataType: MLMultiArrayDataType.float32), cnn_14_save_0: try! MLMultiArray(shape: [112,14,10], dataType: MLMultiArrayDataType.float32), cnn_17_save_0: try! MLMultiArray(shape: [160,14,10], dataType: MLMultiArrayDataType.float32), cnn_20_save_0: try! MLMultiArray(shape: [160,14,10], dataType: MLMultiArrayDataType.float32), cnn_23_save_0: try! MLMultiArray(shape: [272,7,5], dataType: MLMultiArrayDataType.float32), cnn_25_save_0: try! MLMultiArray(shape: [272,7,5], dataType: MLMultiArrayDataType.float32), output_globalclassifier: try! MLMultiArray(shape: [NSNumber(value: InferenceLocal.dimGlobalClassifier)], dataType: MLMultiArrayDataType.float32))
        
        cachedOutputs1 = sensenetOutput.init(cnn_3_save_0: try! MLMultiArray(shape: [32,56,40], dataType: MLMultiArrayDataType.float32), cnn_3_save_1: try! MLMultiArray(shape: [32,56,40], dataType: MLMultiArrayDataType.float32), cnn_7_save_0: try! MLMultiArray(shape: [56,28,20], dataType: MLMultiArrayDataType.float32), cnn_11_save_0: try! MLMultiArray(shape: [112,14,10], dataType: MLMultiArrayDataType.float32), cnn_11_save_1: try! MLMultiArray(shape: [112,14,10], dataType: MLMultiArrayDataType.float32), cnn_14_save_0: try! MLMultiArray(shape: [112,14,10], dataType: MLMultiArrayDataType.float32), cnn_17_save_0: try! MLMultiArray(shape: [160,14,10], dataType: MLMultiArrayDataType.float32), cnn_20_save_0: try! MLMultiArray(shape: [160,14,10], dataType: MLMultiArrayDataType.float32), cnn_23_save_0: try! MLMultiArray(shape: [272,7,5], dataType: MLMultiArrayDataType.float32), cnn_25_save_0: try! MLMultiArray(shape: [272,7,5], dataType: MLMultiArrayDataType.float32), output_globalclassifier: try! MLMultiArray(shape: [NSNumber(value: InferenceLocal.dimGlobalClassifier)], dataType: MLMultiArrayDataType.float32))
}
    
    
    public func collectFrames(imageBuffer: CVPixelBuffer) {
        if !cache_initialized {
            init_cache()
            cache_initialized = true
        }
        if (self.frames.count > 7) {
            if !self.modelRunning {
                // prevent to run the model while in the process of removing frames to avoid access concurency issues
                modelRunning = true
                
                while self.frames.count > 4 {
                    frames.removeFirst(1)
                    debugPrint("TIMING: remove frame")
                }
                modelRunning = false
            }
        }
        self.frames.append(imageBuffer)
        if (self.frames.count >= numFramePrediction && modelRunning == false) {
            self.modelRunning = true
            // do the copy of the frame here to  avoid replacing some frames before prediction

            for i in 0 ... (numFramePrediction - 1){
                framesForPrediction.append(self.frames[i])
            }
            frames.removeFirst(4)
            DispatchQueue.global().async {
                self.startTime = CACurrentMediaTime()
                self.loadPrediction(frames:self.framesForPrediction) {
                    res in
                    let predictions: [[Float]] = []
                    self.delegate?.emitPredictions(predictions, res)
                }
                self.framesForPrediction.removeAll()
                self.modelRunning = false
            }
        }
    }
    public func loadPrediction(frames: [CVPixelBuffer], completionHandler: @escaping (MLMultiArray) -> Void) {
        let time = CACurrentMediaTime()
        let model_output = evaluateModelEfficientnet(frames: frames)
        self.cachedOutputs1 = self.cachedOutputs0
        self.cachedOutputs0 = model_output!
        debugPrint("TIMING: " + String(CACurrentMediaTime()) + " " + String(CACurrentMediaTime() - time))
        completionHandler(model_output!.output_globalclassifier)
    }
        
    public func evaluateModelEfficientnet(frames: [CVPixelBuffer]) -> sensenetOutput? {
        guard let cachedOutputs0Temp = cachedOutputs0, let cachedOutputs1Temp = cachedOutputs1 else {return nil}
        guard let senseOutput = try? model.prediction(new_frame: frames[3], frame_back_1: frames[2], frame_back_2: frames[1], frame_back_3: frames[0], cnn_3_history_0: cachedOutputs0Temp.cnn_3_save_0, cnn_3_history_1: cachedOutputs0Temp.cnn_3_save_1, cnn_7_history_0: cachedOutputs0Temp.cnn_7_save_0, cnn_11_history_0: cachedOutputs0Temp.cnn_11_save_0, cnn_11_history_1: cachedOutputs0Temp.cnn_11_save_1, cnn_14_history_0: cachedOutputs0Temp.cnn_14_save_0, cnn_17_history_0: cachedOutputs0Temp.cnn_17_save_0, cnn_17_history_1: cachedOutputs1Temp.cnn_17_save_0, cnn_20_history_0: cachedOutputs0Temp.cnn_20_save_0, cnn_20_history_1: cachedOutputs1Temp.cnn_20_save_0, cnn_23_history_0: cachedOutputs0Temp.cnn_23_save_0, cnn_23_history_1: cachedOutputs1Temp.cnn_23_save_0, cnn_25_history_0: cachedOutputs0Temp.cnn_25_save_0, cnn_25_history_1: cachedOutputs1Temp.cnn_25_save_0) else {
            return nil
        }

        return senseOutput
    }
}
