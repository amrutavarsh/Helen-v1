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
    func toggleStartStream() {controller.startStream.toggle()}
    
}

class CameraViewController : UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        //nothing
    }
    
    var startStream = false
    
    var frame_counter = 1
    
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
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if self.startStream{
            print("Got a frame \(frame_counter)")
            DispatchQueue.main.async { [unowned self] in
                guard let uiImage = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
                //if let data = uiImage.jpegData(compressionQuality: 0.8) {
                    //let filename = self.getDocumentsDirectory().appendingPathComponent("frame component \(self.frame_counter).jpeg")
                    //try? data.write(to: filename)
                    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil);
                    self.frame_counter = self.frame_counter + 1
                //}
            }
        }
    }
    
    func imageFromSampleBuffer(sampleBuffer : CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func stopCamera(){
        avSession.stopRunning()
    }
    
}
