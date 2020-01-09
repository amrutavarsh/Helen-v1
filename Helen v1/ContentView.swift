//
//  ContentView.swift
//  Helen v1
//
//  Created by Amrutavarsh Kinagi on 27/11/2019.
//  Copyright © 2019 Helen. All rights reserved.
//

import SwiftUI
import UIKit
import AVFoundation

struct ContentView: View {
    var body: some View {
        VStack {
            HStack{
                VStack(alignment: .leading){
                Text("Helen")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    Text("Only clear conversations").font(.subheadline)
                }
                Spacer()
            }.padding().offset(y:10)
            
            ZStack(alignment: .trailing){
            CameraView().frame(height:600).offset(y:70).padding(.top, -80)
                
                
                
                Button(action:{}){
                    Text("Start/Stop").fontWeight(.bold).padding(7)
                    .foregroundColor(Color.white).background(Color.blue).cornerRadius(10)
                }.offset(x:-15,y:235)
                
                Button(action:{}){
                    Text("Flip cam").fontWeight(.bold).padding(7)
                    .foregroundColor(Color.white).background(Color.black).cornerRadius(10)
                }.offset(x:-15,y:185)
                
            }
            
            RoundedRectangle(cornerRadius:30).edgesIgnoringSafeArea(.bottom)
            .frame(height: 250)
         
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CameraView : UIViewControllerRepresentable {
    // Init ViewController
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIViewController {
        let controller = CameraViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraView.UIViewControllerType, context: UIViewControllerRepresentableContext<CameraView>) {
        
    }
}

class CameraViewController : UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCamera()
    }
    
    func loadCamera() {
        let avSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device : captureDevice) else { return }
        avSession.addInput(input)
        avSession.startRunning()
        
        let cameraPreview = AVCaptureVideoPreviewLayer(session: avSession)
        view.layer.addSublayer(cameraPreview)
        cameraPreview.frame = view.frame
    }
}

