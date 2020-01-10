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

public enum CameraPosition {
    case front
    case rear
}

enum CameraControllerError: Swift.Error {
    case captureSessionAlreadyRunning
    case captureSessionIsMissing
    case inputsAreInvalid
    case invalidOperation
    case noCamerasAvailable
    case unknown
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
}

class CameraViewController : UIViewController {
    
   var avSession: AVCaptureSession?
    
   var currentCameraPosition: CameraPosition?

   var frontCamera: AVCaptureDevice?
   var frontCameraInput: AVCaptureDeviceInput?

   var rearCamera: AVCaptureDevice?
   var rearCameraInput: AVCaptureDeviceInput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCamera()
    }
    
    func loadCamera() {
        avSession = AVCaptureSession()
        
        findCameras()
        configureInputs()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device : captureDevice) else { return }
        //avoid creating multiple AV Inputs by destoying existing ones
        if let inputs = avSession?.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                avSession!.removeInput(input)
            }
        }
        avSession!.addInput(input)
        avSession!.startRunning()
        
        let cameraPreview = AVCaptureVideoPreviewLayer(session: avSession!)
        view.layer.addSublayer(cameraPreview)
        cameraPreview.frame = view.frame
    }
    
    func findCameras(){
        let session: AVCaptureDevice.DiscoverySession? = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        guard let cameras = (session?.devices.compactMap { $0 }), !cameras.isEmpty else{ return }
         
        for camera in cameras {
            if camera.position == .front {
                self.frontCamera = camera
            }
         
            if camera.position == .back {
                self.rearCamera = camera
                
                try! camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                camera.unlockForConfiguration()
            }
        }
    }
    
    func configureInputs(){
        guard let captureSession = self.avSession else { return }
        
       if let rearCamera = self.rearCamera {
        self.rearCameraInput = try! AVCaptureDeviceInput(device: rearCamera)

           if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(self.rearCameraInput!) }

           self.currentCameraPosition = .rear
       }

       else if let frontCamera = self.frontCamera {
        self.frontCameraInput = try! AVCaptureDeviceInput(device: frontCamera)

           if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!) }
           else { return }

           self.currentCameraPosition = .front
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
    
}
