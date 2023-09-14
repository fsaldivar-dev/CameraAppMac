//
//  CameraManager.swift
//  CameraApp
//
//  Created by Saldivar on 14/09/23.
//

import AVFoundation
import Cocoa
enum CameraError: LocalizedError {
  case cannotDetectCameraDevice, cannotAddInput, previewLayerConnectionError, cannotAddOutput, videoSessionNil
  
  var localizedDescription: String {
    switch self {
    case .cannotDetectCameraDevice: return "Cannot detect camera device"
    case .cannotAddInput: return "Cannot add camera input"
    case .previewLayerConnectionError: return "Preview layer connection error"
    case .cannotAddOutput: return "Cannot add video output"
    case .videoSessionNil: return "Camera video session is nil"
    }
  }
}

typealias CameraCaptureOutput = AVCaptureOutput
typealias CameraSampleBuffer = CMSampleBuffer
typealias CameraCaptureConnection = AVCaptureConnection

protocol CameraManagerDelegate: AnyObject {
  func cameraManager(_ output: CameraCaptureOutput, didOutput sampleBuffer: CameraSampleBuffer, from connection: CameraCaptureConnection)
}

protocol CameraManagerProtocol: AnyObject {
  var delegate: CameraManagerDelegate? { get set }
  func startSession() throws
  func stopSession() throws
}

final class CameraManager: NSObject, CameraManagerProtocol {
  
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private var videoSession: AVCaptureSession!
  private var cameraDevice: AVCaptureDevice!
  private let cameraQueue: DispatchQueue
  private let containerView: NSView
  private let ciContext = CIContext()
  
  weak var delegate: CameraManagerDelegate?
  
  init(containerView: NSView) throws {
    self.containerView = containerView
    cameraQueue = DispatchQueue(label: "sample buffer delegate")
    super.init()
    try prepareCamera()
  }
  
  private func prepareCamera() throws {
    videoSession = AVCaptureSession()
    videoSession.sessionPreset = .photo
    previewLayer = AVCaptureVideoPreviewLayer(session: videoSession)
    previewLayer.videoGravity = .resizeAspectFill
    cameraDevice = AVCaptureDevice.devices().filter { $0.hasMediaType(.video) }.first
    
    if let cameraDevice = cameraDevice {
      let input = try AVCaptureDeviceInput(device: cameraDevice)
      if videoSession.canAddInput(input) {
        videoSession.addInput(input)
      } else {
        throw CameraError.cannotAddInput
      }
      
      let videoOutput = AVCaptureVideoDataOutput()
      videoOutput.setSampleBufferDelegate(self, queue: cameraQueue)
      if videoSession.canAddOutput(videoOutput) {
        videoSession.addOutput(videoOutput)
      } else {
        throw CameraError.cannotAddOutput
      }
    } else {
      throw CameraError.cannotDetectCameraDevice
    }
  }
  
  func startSession() throws {
    if videoSession.isRunning { return }
    cameraQueue.async { self.videoSession.startRunning() }
  }
  
  func stopSession() throws {
    if !videoSession.isRunning { return }
    cameraQueue.async { self.videoSession.stopRunning() }
  }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.cameraManager(output, didOutput: sampleBuffer, from: connection)
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        var cacheFilterImage = cIColorMonochrome(to: ciImage)
        cacheFilterImage = cIColorMonochrome(to: cacheFilterImage ?? ciImage)
        cacheFilterImage = cIColorMonochrome(to: cacheFilterImage ?? ciImage)
        cacheFilterImage = applyNoiseReductionFilter(to: ciImage)
        cacheFilterImage = applyUnsharpMask(to: cacheFilterImage ?? ciImage)
        cacheFilterImage = applyMedianFilter(to: cacheFilterImage ?? ciImage)
        cacheFilterImage = applyGaussianBlur(to: cacheFilterImage ?? ciImage)
        let filteredImage = cacheFilterImage ?? ciImage
        let squareImage = cropImageToSquare(filteredImage)
        let flippedImage = flipImageHorizontally(squareImage)
        
        if let cgImage = ciContext.createCGImage(flippedImage, from: flippedImage.extent) {
            DispatchQueue.main.async {
                self.containerView.layer?.contents = cgImage
                self.containerView.layer?.contentsGravity = .resizeAspect
            }
        }
    }
    
    private func cIColorMonochrome(to ciImage: CIImage) -> CIImage? {
        let bwFilter = CIFilter(name: "CIColorMonochrome")
        bwFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        bwFilter?.setValue(CIColor(red: 0.75, green: 0.75, blue: 0.75), forKey: kCIInputColorKey)
        bwFilter?.setValue(1.0, forKey: kCIInputIntensityKey)
        return bwFilter?.outputImage
    }

    func applyNoiseReductionFilter(to ciImage: CIImage) -> CIImage? {
        let noiseReductionFilter = CIFilter(name: "CINoiseReduction")
        noiseReductionFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        // Estos son los valores por defecto, pero puedes ajustarlos según tus necesidades.
        noiseReductionFilter?.setValue(0.02, forKey: "inputNoiseLevel")
        noiseReductionFilter?.setValue(0.40, forKey: "inputSharpness")
        return noiseReductionFilter?.outputImage
    }
    
    func applyUnsharpMask(to ciImage: CIImage, radius: Double = 0.5, intensity: Double = 0.8) -> CIImage? {
        let unsharpMaskFilter = CIFilter(name: "CIUnsharpMask")
        unsharpMaskFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        unsharpMaskFilter?.setValue(radius, forKey: "inputRadius")
        unsharpMaskFilter?.setValue(intensity, forKey: "inputIntensity")
        return unsharpMaskFilter?.outputImage
    }

    func applyMedianFilter(to ciImage: CIImage) -> CIImage? {
        let medianFilter = CIFilter(name: "CIMedianFilter")
        medianFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        return medianFilter?.outputImage
    }
    
    func applyGaussianBlur(to ciImage: CIImage, radius: Double = 2.0) -> CIImage? {
        let gaussianBlurFilter = CIFilter(name: "CIGaussianBlur")
        gaussianBlurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        gaussianBlurFilter?.setValue(radius, forKey: "inputRadius")
        return gaussianBlurFilter?.outputImage
    }

    func cropImageToSquare(_ image: CIImage) -> CIImage {
        let shortestSide = min(image.extent.width, image.extent.height)
        let centeredRect = CGRect(x: (image.extent.width - shortestSide) / 2.0,
                                  y: (image.extent.height - shortestSide) / 2.0,
                                  width: shortestSide, height: shortestSide)
        return image.cropped(to: centeredRect)
    }
    func flipImageHorizontally(_ image: CIImage) -> CIImage {
        let flipped = image.transformed(by: CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -image.extent.width, y: 0))
        return flipped
    }

}

