import Foundation
import Accelerate

func resizePixelBuffer(_ srcPixelBuffer: CVPixelBuffer,
                       cropX: Int,
                       cropY: Int,
                       cropWidth: Int,
                       cropHeight: Int,
                       scaleWidth: Int,
                       scaleHeight: Int) -> CVPixelBuffer? {

  CVPixelBufferLockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
  defer { CVPixelBufferUnlockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0)) }
  
  guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer) else {
    print("Error: could not get pixel buffer base address")
    return nil
  }
    
  let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
  let offset = cropY*srcBytesPerRow + cropX*4
  var srcBuffer = vImage_Buffer(data: srcData.advanced(by: offset),
                                height: vImagePixelCount(cropHeight),
                                width: vImagePixelCount(cropWidth),
                                rowBytes: srcBytesPerRow)

  let destBytesPerRow = scaleWidth*4
  guard let destData = malloc(scaleHeight*destBytesPerRow) else {
    print("Error: out of memory")
    return nil
  }
  var destBuffer = vImage_Buffer(data: destData,
                                 height: vImagePixelCount(scaleHeight),
                                 width: vImagePixelCount(scaleWidth),
                                 rowBytes: destBytesPerRow)

  let error = vImageScale_ARGB8888(&srcBuffer, &destBuffer, nil, vImage_Flags(0))
    
  CVPixelBufferUnlockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
  if error != kvImageNoError {
    print("Error: ", error)
    free(destData)
    return nil
  }
    
//
  let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
    if let ptr = ptr {
      free(UnsafeMutableRawPointer(mutating: ptr))
    }
  }

  let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
  var dstPixelBuffer: CVPixelBuffer?
  let status = CVPixelBufferCreateWithBytes(nil, scaleWidth, scaleHeight,
                                            pixelFormat, destData,
                                            destBytesPerRow, releaseCallback,
                                            nil, nil, &dstPixelBuffer)
  if status != kCVReturnSuccess {
    print("Error: could not create new pixel buffer")
    free(destData)
    return nil
  }
  return dstPixelBuffer
}

func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer,
                       width: Int, height: Int) -> CVPixelBuffer? {
  return resizePixelBuffer(pixelBuffer, cropX: 0, cropY: 0,
                           cropWidth: CVPixelBufferGetWidth(pixelBuffer),
                           cropHeight: CVPixelBufferGetHeight(pixelBuffer),
                           scaleWidth: width, scaleHeight: height)
}

func rotate90PixelBuffer(_ srcPixelBuffer: CVPixelBuffer, factor: UInt8) -> CVPixelBuffer? {
    let flags = CVPixelBufferLockFlags(rawValue: 0)
    guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(srcPixelBuffer, flags) else {
        return nil
    }
    defer { CVPixelBufferUnlockBaseAddress(srcPixelBuffer, flags) }
    
    guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer) else {
        print("Error: could not get pixel buffer base address")
        return nil
    }
    let sourceWidth = CVPixelBufferGetWidth(srcPixelBuffer)
    let sourceHeight = CVPixelBufferGetHeight(srcPixelBuffer)
    var destWidth = sourceHeight
    var destHeight = sourceWidth
    var color = UInt8(0)
    
    if factor % 2 == 0 {
        destWidth = sourceWidth
        destHeight = sourceHeight
    }
    
    let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
    var srcBuffer = vImage_Buffer(data: srcData,
                                  height: vImagePixelCount(sourceHeight),
                                  width: vImagePixelCount(sourceWidth),
                                  rowBytes: srcBytesPerRow)
    
    let destBytesPerRow = destWidth*4
    guard let destData = malloc(destHeight*destBytesPerRow) else {
        print("Error: out of memory")
        return nil
    }
    var destBuffer = vImage_Buffer(data: destData,
                                   height: vImagePixelCount(destHeight),
                                   width: vImagePixelCount(destWidth),
                                   rowBytes: destBytesPerRow)
    
    let error = vImageRotate90_ARGB8888(&srcBuffer, &destBuffer, factor, &color, vImage_Flags(0))
    if error != kvImageNoError {
        print("Error:", error)
        free(destData)
        return nil
    }
    
    let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
        if let ptr = ptr {
            free(UnsafeMutableRawPointer(mutating: ptr))
        }
    }
    
    let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
    var dstPixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreateWithBytes(nil, destWidth, destHeight,
                                              pixelFormat, destData,
                                              destBytesPerRow, releaseCallback,
                                              nil, nil, &dstPixelBuffer)
    if status != kCVReturnSuccess {
        print("Error: could not create new pixel buffer")
        free(destData)
        return nil
    }
    return dstPixelBuffer
}

func padPixelBuffer(_ srcPixelBuffer: CVPixelBuffer,
                    destWidth: Int,
                    destHeight: Int) -> CVPixelBuffer? {
    
    CVPixelBufferLockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    
    let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
    let srcWidth = CVPixelBufferGetWidth(srcPixelBuffer)
    let srcHeight = CVPixelBufferGetHeight(srcPixelBuffer)
    let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
    let srcBaseAddress = CVPixelBufferGetBaseAddress(srcPixelBuffer)
    
    var paddedPixelBuffer: CVPixelBuffer?
    
    let srcBytes = srcBaseAddress!.assumingMemoryBound(to: UInt8.self)
    let destBuffer = calloc(4*destHeight*destWidth, MemoryLayout<UInt8>.size)
    
    
    for row in 0..<srcHeight {
        let offset_dest = 4*MemoryLayout<UInt8>.size*((destWidth - srcWidth)/2 + row*destWidth)
        let offset_src = 4*MemoryLayout<UInt8>.size*(row*srcWidth)
        memcpy(destBuffer?.advanced(by: offset_dest), srcBytes.advanced(by: offset_src), srcBytesPerRow)
    }
    
    CVPixelBufferUnlockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    
    let destBytesPerRow = 4*destWidth
    
    let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
        if let ptr = ptr {
            free(UnsafeMutableRawPointer(mutating: ptr))
        }
    }
    
    let status = CVPixelBufferCreateWithBytes(nil, destWidth, destWidth,
                                 pixelFormat, destBuffer!,
                                 destBytesPerRow, releaseCallback,
                                 nil, nil, &paddedPixelBuffer)
    
    if status != kCVReturnSuccess {
        print("Error: could not create new pixel buffer")
        free(destBuffer)
        return nil
    }

    return paddedPixelBuffer
}
