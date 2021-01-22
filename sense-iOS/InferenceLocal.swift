import Foundation
import Accelerate
import AVFoundation
import TensorFlowLite

class InferenceLocal {
	
	var delegate: GUIControllerDelegate?
	var modelRunning = false
	public static let inputWidth: Int = 160
	public static let inputHeight: Int = 224
	let batchSize = 1
	let inputChannels = 3

	
	struct Prediction {
		let classIndex: Int
		let score: Float
		let rect: CGRect
	}
	
	var startTime = CACurrentMediaTime()

	var numFrames = -2
	var frames = [Data?]()
	var framesForPrediction = [Data?]()
	var cache_initialized = false
	var cachedOutputs0: [Data] = [Data]()
	var cachedOutputs1: [Data] = [Data]()
	var numFramePrediction = 4
	let modelPath = Bundle.main.path(forResource: "model", ofType: "tflite")
	var threadCount = 2
	var interpreter: Interpreter? = nil
	let queue1 = DispatchQueue(label: "com.sense-iOS.inference", qos: .userInteractive)
	
   init() {
	// Specify the options for the `Interpreter`.
	var options = Interpreter.Options()
	options.threadCount = threadCount
	do {
	  // Create the `Interpreter`.
	   let coremlDelegate = CoreMLDelegate()
	  if let coremlDelegate = coremlDelegate {
		interpreter = try Interpreter(modelPath: modelPath!,
									  options: options, delegates: [coremlDelegate])
	  } else {
		let delegate = MetalDelegate()
		interpreter = try Interpreter(modelPath: modelPath!,
									  options: options, delegates: [delegate])
	  }
	   
	  // Allocate memory for the model's input `Tensor`s.
	  try interpreter!.allocateTensors()
	} catch let error {
	  print("Failed to create the interpreter with error: \(error.localizedDescription)")
	}

	do {
	  var startDate = Date()
	  try interpreter!.invoke()
	  var interval = Date().timeIntervalSince(startDate) * 1000
	  print(interval)
	} catch let error {
	  print("Failed to invoke interpretor: \(error.localizedDescription)")
	}
	cachedOutputs0 = copyOutput()
	cachedOutputs1 = copyOutput()
  }
  
  private func copyOutput() -> Array<Data> {
	let numOutput = interpreter!.outputTensorCount
	var outputArray = [Data]()
	for i in 0 ... Int((numOutput / 2) - 1) {
	  let output = try! interpreter!.output(at: i)
	  outputArray.append(copyData(tensor: output))
	}
	return outputArray
  }
  
  func copyData(tensor: Tensor) -> Data {
	let res = Data(copyingBufferOf: copyArrayOutput(tensor: tensor))
	return res
  }
  
  func copyArrayOutput(tensor: Tensor) -> Array<Float32> {
	let outputSize = tensor.shape.dimensions.reduce(1, {x, y in x * y})
	  let outputData =
			UnsafeMutableBufferPointer<Float32>.allocate(capacity: outputSize)
	tensor.data.copyBytes(to: outputData)
	let array = Array(outputData)
	outputData.deallocate()
	return array
  }
	
	
	public func collectFrames(imageBuffer: CVPixelBuffer) {
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
		self.frames.append( rgbDataFromBuffer(
		  imageBuffer,
		  byteCount: batchSize * InferenceLocal.inputWidth * InferenceLocal.inputHeight * inputChannels,
		  isModelQuantized: false))
		if (self.frames.count >= numFramePrediction && modelRunning == false) {
			self.modelRunning = true
			// do the copy of the frame here to  avoid replacing some frames before prediction

			for i in 0 ... (numFramePrediction - 1){
				framesForPrediction.append(self.frames[i])
			}
			frames.removeFirst(4)
			queue1.async {
				self.startTime = CACurrentMediaTime()
				self.loadPrediction(frames:self.framesForPrediction) {
					res in
				  self.delegate?.emitPredictions(global_output: res)
				}
				self.framesForPrediction.removeAll()
				self.modelRunning = false
			}
		}
	}
	public func loadPrediction(frames: [Data?], completionHandler: @escaping (Array<Float32>) -> Void) {
		let time = CACurrentMediaTime()
		let model_output = evaluateModelEfficientnet(frames: frames)
		self.cachedOutputs1 = self.cachedOutputs0
		self.cachedOutputs0 = model_output
		debugPrint("TIMING: " + String(CACurrentMediaTime()) + " " + String(CACurrentMediaTime() - time))
	  let array = copyArrayOutput(tensor: try! interpreter!.output(at: 10))
		completionHandler(array)
	}
		
	public func evaluateModelEfficientnet(frames: [Data?]) -> [Data] {
	  try! interpreter!.copy(frames[3]!, toInputAt: 0)
	  try! interpreter!.copy(frames[2]!, toInputAt: 1)
	  try! interpreter!.copy(frames[1]!, toInputAt: 2)
	  try! interpreter!.copy(frames[0]!, toInputAt: 3)
	  try! interpreter!.copy(cachedOutputs0[0], toInputAt: 4)
	  try! interpreter!.copy(cachedOutputs0[1], toInputAt: 5)
	  try! interpreter!.copy(cachedOutputs0[2], toInputAt: 6)
	  try! interpreter!.copy(cachedOutputs0[3], toInputAt: 7)
	  try! interpreter!.copy(cachedOutputs0[4], toInputAt: 8)
	  try! interpreter!.copy(cachedOutputs0[5], toInputAt: 9)
	  try! interpreter!.copy(cachedOutputs0[6], toInputAt: 10)
	  try! interpreter!.copy(cachedOutputs1[6], toInputAt: 11)
	  try! interpreter!.copy(cachedOutputs0[7], toInputAt: 12)
	  try! interpreter!.copy(cachedOutputs1[7], toInputAt: 13)
	  try! interpreter!.copy(cachedOutputs0[8], toInputAt: 14)
	  try! interpreter!.copy(cachedOutputs1[8], toInputAt: 15)
	  try! interpreter!.copy(cachedOutputs0[9], toInputAt: 16)
	  try! interpreter!.invoke()
	  return copyOutput()
	}
  
  
  
  /// Returns the RGB data representation of the given image buffer with the specified `byteCount`.
   ///
   /// - Parameters
   ///   - buffer: The pixel buffer to convert to RGB data.
   ///   - byteCount: The expected byte count for the RGB data calculated using the values that the
   ///       model was trained on: `batchSize * imageWidth * imageHeight * componentsCount`.
   ///   - isModelQuantized: Whether the model is quantized (i.e. fixed point values rather than
   ///       floating point values).
   /// - Returns: The RGB data representation of the image buffer or `nil` if the buffer could not be
   ///     converted.
   private func rgbDataFromBuffer(
	 _ buffer: CVPixelBuffer,
	 byteCount: Int,
	 isModelQuantized: Bool
   ) -> Data? {
	 CVPixelBufferLockBaseAddress(buffer, .readOnly)
	 defer {
	   CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
	 }
	 guard let sourceData = CVPixelBufferGetBaseAddress(buffer) else {
	   return nil
	 }
	 
	 let width = CVPixelBufferGetWidth(buffer)
	 let height = CVPixelBufferGetHeight(buffer)
	 let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
	 let destinationChannelCount = 3
	 let destinationBytesPerRow = destinationChannelCount * width
	 
	 var sourceBuffer = vImage_Buffer(data: sourceData,
									  height: vImagePixelCount(height),
									  width: vImagePixelCount(width),
									  rowBytes: sourceBytesPerRow)
	 
	 guard let destinationData = malloc(height * destinationBytesPerRow) else {
	   print("Error: out of memory")
	   return nil
	 }
	 
	 defer {
		 free(destinationData)
	 }

	 var destinationBuffer = vImage_Buffer(data: destinationData,
										   height: vImagePixelCount(height),
										   width: vImagePixelCount(width),
										   rowBytes: destinationBytesPerRow)

	 let pixelBufferFormat = CVPixelBufferGetPixelFormatType(buffer)

	 switch (pixelBufferFormat) {
	 case kCVPixelFormatType_32BGRA:
		 vImageConvert_BGRA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
	 case kCVPixelFormatType_32ARGB:
		 vImageConvert_ARGB8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
	 case kCVPixelFormatType_32RGBA:
		 vImageConvert_RGBA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
	 default:
		 // Unknown pixel format.
		 return nil
	 }

	 let byteData = Data(bytes: destinationBuffer.data, count: destinationBuffer.rowBytes * height)
	 if isModelQuantized {
		 return byteData
	 }

	 // Not quantized, convert to floats
	 let bytes = Array<UInt8>(unsafeData: byteData)!
	 var floats = [Float]()
	 for i in 0..<bytes.count {
		 floats.append(Float(bytes[i]) / 255.0)
	 }
	 return Data(copyingBufferOf: floats)
   }
}


extension Data {
  /// Creates a new buffer by copying the buffer pointer of the given array.
  ///
  /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
  ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
  ///     data from the resulting buffer has undefined behavior.
  /// - Parameter array: An array with elements of type `T`.
  init<T>(copyingBufferOf array: [T]) {
	self = array.withUnsafeBufferPointer(Data.init)
  }
}

extension Array {
  /// Creates a new array from the bytes of the given unsafe data.
  ///
  /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
  ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
  ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
  /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
  ///     `MemoryLayout<Element>.stride`.
  /// - Parameter unsafeData: The data containing the bytes to turn into an array.
  init?(unsafeData: Data) {
	guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
	#if swift(>=5.0)
	self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
	#else
	self = unsafeData.withUnsafeBytes {
	  .init(UnsafeBufferPointer<Element>(
		start: $0,
		count: unsafeData.count / MemoryLayout<Element>.stride
	  ))
	}
	#endif  // swift(>=5.0)
  }
}
