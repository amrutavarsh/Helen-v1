//
//  CameraController.swift
//  Helen v1
//
//  Created by Amrutavarsh Kinagi on 9/1/2020.
//  Copyright © 2020 Helen. All rights reserved.
//

import UIKit
import SwiftUI
import AVFoundation
import Vision

import AWSS3
import Amplify

var useAudio:Bool = false

public enum CameraPosition {
    case front
    case rear
}

struct CameraView : UIViewControllerRepresentable {
    // Init ViewController
    let controller = CameraViewController()
    
    func makeUIViewController(context: Context) -> UIViewController {
        controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    
    func callSwitchCam() {controller.switchCamera()}
    func toggleStartStream() {
        controller.startStream.toggle()
//        controller.upload()
    }
    func faceFound()-> Bool{return controller.frameFaceFound}
    
}

class CameraViewController : UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        //nothing
    }
    
    var startStream = false
    var prevStartStream = false
    var frame_counter = 1
    var videoID = 1
    var frameFaceFound: Bool = true
    
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    
    var avSession: AVCaptureSession!
    
    var currentCameraPosition: CameraPosition?
    
    var frontCamera: AVCaptureDevice?
    var frontCameraInput: AVCaptureDeviceInput?
    
    var rearCamera: AVCaptureDevice?
    var rearCameraInput: AVCaptureDeviceInput?
    
    var audioDevice :AVCaptureDevice?
    var captureAudioInput :AVCaptureDeviceInput?
    var captureDeviceAudioFound:Bool = false
    
    var cameraPreview :AVCaptureVideoPreviewLayer?
    
    let context =  CIContext()
    let outputSize = CGSize(width: 1920, height: 1280)
    let imagesPerSecond: TimeInterval = 0.04 //each image will be stay for 3 secs
    var selectedPhotosArray = [UIImage]()
    var imageArrayToVideoURL: URL!
    var asset: AVAsset!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCamera()
    }
    
    func loadCamera() {
        avSession = AVCaptureSession()
        
        findCameras()
        configureVideoInputs()
        configureVideoOutput()
        
        if useAudio{configureAudioInputs()}
        
        cameraPreview = AVCaptureVideoPreviewLayer(session: avSession!)
        cameraPreview?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(cameraPreview!)
        cameraPreview?.frame = view.frame
        avSession!.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.cameraPreview?.frame = view.frame
    }
    
    func findCameras(){
        let session: AVCaptureDevice.DiscoverySession? = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        guard let cameras = (session?.devices.compactMap { $0 }), !cameras.isEmpty else{ return }
        
        for camera in cameras {
            if camera.position == .front {
                self.frontCamera = camera
                try! camera.lockForConfiguration()
                self.frontCamera!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(30))
                self.frontCamera!.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(30))
                camera.unlockForConfiguration()
            }
            
            if camera.position == .back {
                self.rearCamera = camera
                
                try! camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                self.rearCamera!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(30))
                self.rearCamera!.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(30))
                camera.unlockForConfiguration()
            }
        }
    }
    
    func configureVideoInputs(){
        guard let captureSession = self.avSession else { return }
        if let rearCamera = self.rearCamera {
            self.rearCameraInput = try! AVCaptureDeviceInput(device: rearCamera)
                        
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
            }
            
            self.currentCameraPosition = .rear
        }
            
        else if let frontCamera = self.frontCamera {
            self.frontCameraInput = try! AVCaptureDeviceInput(device: frontCamera)
            
            if captureSession.canAddInput(self.frontCameraInput!){
                captureSession.addInput(self.frontCameraInput!)
            }
            else { return }
            
            self.currentCameraPosition = .front
        }
    }
    
    func configureVideoOutput(){
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames=true
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
        
        if avSession.canAddOutput(self.videoDataOutput){
            avSession.addOutput(self.videoDataOutput)
        }
        
        videoDataOutput.connection(with: .video)?.isEnabled = true
    }
    
    func configureAudioInputs(){
        do{
            self.audioDevice = AVCaptureDevice.default(for: .audio)
            self.captureAudioInput = try AVCaptureDeviceInput(device: audioDevice!)
            if avSession!.canAddInput(captureAudioInput!) {
                avSession!.addInput(captureAudioInput!)
            } else {
                print("Could not add audio device input to the session")
            }
        }
        catch{
            print("Could not create audio device input")
        }
    }
    
    func switchCamera() {
        guard let currentCameraPosition = currentCameraPosition, let avSession = self.avSession, avSession.isRunning else { return }
        
        avSession.beginConfiguration()
        
        func switchToFrontCamera() {
            let rearCameraInput = self.rearCameraInput
            let frontCamera = self.frontCamera
            
            self.frontCameraInput = try! AVCaptureDeviceInput(device: frontCamera!)
            
            avSession.removeInput(rearCameraInput!)
            
            if avSession.canAddInput(self.frontCameraInput!) {
                avSession.addInput(self.frontCameraInput!)
                
                self.currentCameraPosition = .front
            }
        }
        func switchToRearCamera() {
            let frontCameraInput = self.frontCameraInput
            let rearCamera = self.rearCamera
            
            self.rearCameraInput = try! AVCaptureDeviceInput(device: rearCamera!)
            
            avSession.removeInput(frontCameraInput!)
            
            if avSession.canAddInput(self.rearCameraInput!) {
                avSession.addInput(self.rearCameraInput!)
                
                self.currentCameraPosition = .rear
            }
        }
        
        switch currentCameraPosition {
        case .front:
            switchToRearCamera()
            
        case .rear:
            switchToFrontCamera()
        }
        
        avSession.commitConfiguration()
    }
    
    private func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation], results.count > 0 {
                    self.frameFaceFound = true
                } else {
                    self.frameFaceFound = false                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
    func imageFromSampleBuffer(sampleBuffer : CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        self.detectFace(in: imageBuffer)
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
         
        guard let uiImage = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        if (self.startStream){
            //UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil);
            selectedPhotosArray.append(uiImage)
            //guard let data = uiImage.jpegData(compressionQuality: 1) ?? uiImage.pngData() else {return}
            //let frameKey = "fileName\(self.frame_counter).png"
            //let fileName = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(frameKey)
            //do {
            //    try data.write(to: fileName)
            //} catch {   
            //    print(error.localizedDescription)
            //    return 
            //}
            //uploadFile(fileNameKey : frameKey, filename : fileName)
            self.frame_counter = self.frame_counter + 1
        }
        else{
            startStream = false
            if prevStartStream == true{
            buildVideoFromImageArray()
            }    
        }
        prevStartStream = startStream
    }
    
    func buildVideoFromImageArray() {
        let fileKey = "file\(videoID).MP4"
        videoID += 1
        imageArrayToVideoURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileKey)
        guard let videoWriter = try? AVAssetWriter(outputURL: imageArrayToVideoURL as URL, fileType: AVFileType.mp4) else {
            fatalError("AVAssetWriter error")
        }
        let outputSettings = [AVVideoCodecKey : AVVideoCodecType.h264, AVVideoWidthKey : NSNumber(value: Float(outputSize.width)), AVVideoHeightKey : NSNumber(value: Float(outputSize.height))] as [String : Any]
        guard videoWriter.canApply(outputSettings: outputSettings, forMediaType: AVMediaType.video) else {
            fatalError("Negative : Can't apply the Output settings...")
        }
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        let sourcePixelBufferAttributesDictionary = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32ARGB), kCVPixelBufferWidthKey as String: NSNumber(value: Float(outputSize.width)), kCVPixelBufferHeightKey as String: NSNumber(value: Float(outputSize.height))]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        if videoWriter.startWriting() {
            let zeroTime = CMTimeMake(value: Int64(imagesPerSecond),timescale: Int32(1))
            videoWriter.startSession(atSourceTime: zeroTime)

            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            let media_queue = DispatchQueue(label: "mediaInputQueue")
            videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
                let fps: Int32 = 1
                let framePerSecond: Int64 = Int64(self.imagesPerSecond)
                let frameDuration = CMTimeMake(value: Int64(self.imagesPerSecond), timescale: fps)
                var frameCount: Int64 = 0
                var appendSucceeded = true
                while (!self.selectedPhotosArray.isEmpty) {
                    if (videoWriterInput.isReadyForMoreMediaData) {
                        let nextPhoto = self.selectedPhotosArray.remove(at: 0)
                        let lastFrameTime = CMTimeMake(value: frameCount * framePerSecond, timescale: fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        var pixelBuffer: CVPixelBuffer? = nil
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                        if let pixelBuffer = pixelBuffer, status == 0 {
                            let managedPixelBuffer = pixelBuffer
                            CVPixelBufferLockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            let data = CVPixelBufferGetBaseAddress(managedPixelBuffer)
                            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                            let context = CGContext(data: data, width: Int(self.outputSize.width), height: Int(self.outputSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(managedPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
                            context!.clear(CGRect(x: 0, y: 0, width: CGFloat(self.outputSize.width), height: CGFloat(self.outputSize.height)))
                            let horizontalRatio = CGFloat(self.outputSize.width) / nextPhoto.size.width
                            let verticalRatio = CGFloat(self.outputSize.height) / nextPhoto.size.height
                            //let aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
                            let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
                            let newSize: CGSize = CGSize(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)
                            let x = newSize.width < self.outputSize.width ? (self.outputSize.width - newSize.width) / 2 : 0
                            let y = newSize.height < self.outputSize.height ? (self.outputSize.height - newSize.height) / 2 : 0
                            context?.draw(nextPhoto.cgImage!, in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
                            CVPixelBufferUnlockBaseAddress(managedPixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                        } else {
                            print("Failed to allocate pixel buffer")
                            appendSucceeded = false
                        }
                    }
                    if !appendSucceeded {
                        break
                    }
                    frameCount += 1
                }
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting { () -> Void in
                    print("-----video1 url = \(String(describing: self.imageArrayToVideoURL))")
                    self.asset = AVAsset(url: self.imageArrayToVideoURL as URL)
                }
            })
        }
        uploadFile(fileNameKey: fileKey, filename: imageArrayToVideoURL as URL)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func stopCamera(){
        avSession.stopRunning()
    }
    
    //aws stuff
    
    func uploadData() {
        print("called")
        let dataString = "My Data"
        let data = dataString.data(using: .utf8)!
        Amplify.Storage.uploadData(key: "myKey", data: data) { (event) in
            switch event {
            case .completed(let data):
                print("Completed: \(data)")
            case .failed(let storageError):
                print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
            case .inProcess(let progress):
                print("Progress: \(progress)")
            default:
                break
            }
        }
    }
    
   func uploadFile(fileNameKey: String, filename: URL) {
      print("upload file called")
  _ = Amplify.Storage.uploadFile(key: fileNameKey, local: filename) { (event) in
      switch event {
      case .completed(let data):
          print("Completed: \(data)")
      case .failed(let storageError):
          print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
      case .inProcess(let progress):
          print("Progress: \(progress)")
      default:
          break
          }
       }
    } 
}
