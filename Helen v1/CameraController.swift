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

import Foundation
import CoreServices
import Photos

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
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    
    func callSwitchCam() {controller.switchCamera()}
    func toggleStartStream() {
        controller.startRecording()
    }
    func faceFound()-> Bool{return controller.frameFaceFound}
    
}

class CameraViewController : UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    var startStream = false
    var frame_counter = 1
    var videoID = 1
    var frameFaceFound: Bool = true
    
    var avSession: AVCaptureSession!
    
    var currentCameraPosition: CameraPosition?
    
    let movieOutput = AVCaptureMovieFileOutput()
    
    var frontCamera: AVCaptureDevice?
    var frontCameraInput: AVCaptureDeviceInput?
    
    var rearCamera: AVCaptureDevice?
    var rearCameraInput: AVCaptureDeviceInput?
    
    var cameraPreview :AVCaptureVideoPreviewLayer?
    
    let context =  CIContext()
    var outputURL: URL!
    var outputURLkey: String!
    
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
                self.frontCamera!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(25))
                self.frontCamera!.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(25))
                camera.unlockForConfiguration()
            }
            
            if camera.position == .back {
                self.rearCamera = camera
                
                try! camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                self.rearCamera!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(25))
                self.rearCamera!.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(25))
                camera.unlockForConfiguration()
            }
        }
    }
    
    func configureVideoInputs(){
         self.avSession.sessionPreset = AVCaptureSession.Preset.medium
           if let rearCamera = self.rearCamera {
               self.rearCameraInput = try! AVCaptureDeviceInput(device: rearCamera)
                           
               if self.avSession.canAddInput(self.rearCameraInput!) {
                   self.avSession.addInput(self.rearCameraInput!)
               }
               
               self.currentCameraPosition = .rear
           }
               
           else if let frontCamera = self.frontCamera {
               self.frontCameraInput = try! AVCaptureDeviceInput(device: frontCamera)
               
               if self.avSession.canAddInput(self.frontCameraInput!){
                   self.avSession.addInput(self.frontCameraInput!)
               }
               else { return }
               
               self.currentCameraPosition = .front
           }
    }
    
    func configureVideoOutput(){
        if self.avSession.canAddOutput(movieOutput) {
            self.avSession.addOutput(movieOutput)
        }
    }
    
    func configureAudioInputs(){
        let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!

        do {
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if self.avSession.canAddInput(micInput) {
                self.avSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return
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
         
        //guard let uiImage = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        if (self.startStream){
            //UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil);
            //uploadFile(fileNameKey : frameKey, filename : fileName)
            self.frame_counter = self.frame_counter + 1
        }
    }
    
    func startRecording() {

        if movieOutput.isRecording == false {
            print("recording \(videoID) started")
            let connection = movieOutput.connection(with: AVMediaType.video)

            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            }

            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            
            if movieOutput.availableVideoCodecTypes.contains(.h264) {
                // Use the H.264 codec to encode the video.
                movieOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.h264], for: connection!)
            }
            outputURL = getURL()
            try? FileManager.default.removeItem(at: outputURL)
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
        else {
            stopRecording()
        }

    }
    
    func stopRecording() {
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
        print("recording \(videoID) ended")
        let videoID = self.videoID
//        DispatchQueue.main.async {
//            self.uploadFile(fileNameKey : "HelenVideo\(videoID).mp4", filename : self.outputURL)
//            print("file uploaded initiated")
//            self.downloadFile()
//        }
        
        self.videoID += 1
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
//        PHPhotoLibrary.shared().performChanges({
//            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.outputURL)
//        }) { saved, error in
//            if saved {
//                return
//            }
//        }
        self.uploadFile(fileNameKey : outputURLkey, filename : self.outputURL)
        print("file uploaded initiated")
    }
    
    func getURL() -> URL {
        outputURLkey = "HelenVideo\(videoID).mp4"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(outputURLkey)
        return path
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
          print("publishing video")
      default:
          break
          }
       }
    }
}
