//
//  ContentView.swift
//  Helen v1
//
//  Created by Amrutavarsh Kinagi on 27/11/2019.
//  Copyright © 2019 Helen. All rights reserved.
//

import SwiftUI
import AWSS3
import Amplify

struct ContentView: View {
    let camView = CameraView()
    @State var startStream = false
    @State var showCreatorsInfo = false
    @State var listing = true
    @State var outputString = "..."
    @State var downloadComplete = false
    @State var secretDemo = false
    @State var secretToggle = false
    @State var secretCount = 0
    let timer = Timer.publish(every: 0.1, on: .current, in: .common).autoconnect()
    var body: some View {
        ZStack{
            camView
            
//            Use for UIViewDebug
            //Rectangle().fill(Color.green)
            
            VStack{
                ZStack(alignment: .bottom){
                    Rectangle().fill(Color.white).frame(height:105).opacity(0.7)
                    
                    HStack{
                        VStack(alignment: .leading){
                            Text("Helen")
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                            Text("Only clear conversations").font(.subheadline)
                        }
                        Spacer()
                        Button(action:{self.secretCount += 1
                            if(self.secretCount == 3){
                                self.secretDemo = true
                            }
                            self.showCreatorsInfo.toggle()}){Text("</>").fontWeight(.bold).padding(7).foregroundColor(Color.white).background(secretButtonColor(secretDemo: secretDemo)).cornerRadius(30).sheet(isPresented: $showCreatorsInfo, content: {CreatorsInfo()})
                        }
                    }.padding()
                    
                }
                
                Text("Face not detected").padding(7).foregroundColor(Color.white).background(Color.red).cornerRadius(30).opacity(0.7)
                
                
                Spacer()
                
                Group{
                    HStack{
                        Spacer()
                    VStack(alignment: .trailing){
                         Button(action:{self.secretCount = 0
                            self.camView.callSwitchCam()}){
                            Text("Flip cam").fontWeight(.bold).padding(7)
                                .foregroundColor(Color.white).background(Color.black).cornerRadius(10)
                        }.padding(.vertical)
                        
                        Button(action:{
//                            if self.camView.faceFound(){
                            self.secretCount = 0
                            self.camView.toggleStartStream()
                            self.startStream.toggle()
                            if (self.startStream && self.secretDemo){
                                DispatchQueue.main.asyncAfter(deadline: .now()+7){
                                self.secretToggle = true
                                }
                            }
                            if self.listing{
                                DispatchQueue.main.async {
                                    self.list()
                                }
                                self.listing = false
                            }
//                            }
                        }){
                            Text(recordButtonText(streamState: self.startStream)).fontWeight(.bold).padding(7).foregroundColor(Color.white).background(recordButtonColor(streamState: self.startStream)).cornerRadius(10)
                        }
                    }.padding(.horizontal)
                }
                    
                    ZStack{
                        
                        RoundedRectangle(cornerRadius:30).opacity(0.7).frame(height: 250)
                        
                        Text("\(outputString)").font(.title).foregroundColor(Color.white)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading).frame(height: 160).padding().onReceive(timer) {_ in
                            self.outputString = self.printFile()
                        }
                    }.offset(y:30).padding(.top, -30)
                }
            }
            
        }.edgesIgnoringSafeArea(.all)
    }
    func recordButtonText(streamState: Bool) -> String {return (streamState ? "Stop" : "Start")}
    func recordButtonColor(streamState: Bool) -> Color {return (streamState ? Color.red : Color.blue)}
    func secretButtonColor(secretDemo: Bool) -> Color {return (secretDemo ? Color.gray : Color.black)}
    func faceOpacity()->CGFloat{return (camView.faceFound() ? 0.0 :0.7)}
    func downloadFile() {
        //var stillPinging = true
        Amplify.Storage.downloadFile(key: "output.txt", local: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("output.txt")) { (event) in
            switch event {
            case .completed:
                print("Completed")
                self.downloadComplete = true
            case .failed(let storageError):
                print("file not found")
            case .inProcess(let progress):
                print("Progress: \(progress)")
            default:
                break
            }
        }
    }

    func list(){
    print("running listing")
      Amplify.Storage.list { (event) in
          switch event {
          case .completed(let listResult):
              print("Completed")
              listResult.items.forEach { (item) in
                  print("Key: \(item.key)")
                if (item.key == "output.txt" && self.downloadComplete == false){
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)){
                    try? FileManager.default.removeItem(at: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("output.txt"))
                        self.downloadFile()}
                }
              }
          case .failed(let storageError):
                print("error")
          case .inProcess(let progress):
              print("Progress: \(progress)")
          default:
              break
          }
      }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)){
            self.list()
        }
    }

    func printFile() -> String{
        if secretDemo{
            if secretToggle{
                return "call at ambulance"
            }
            else{
                return "..."
            }
        }
        
        if self.downloadComplete{
            let content = try! String(contentsOfFile:(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("output.txt")).path, encoding: String.Encoding.utf8)
            if(content.count < 200){
           print("=================================")
            print(content)
           print("=================================")
            self.remove()
            downloadComplete = false
            return content
            }
            else{
                return self.outputString
            }
        }
        else{
            print("-----printFile called-----")
            return self.outputString
        }
    }

    func remove() {
      Amplify.Storage.remove(key: "output.txt") { (event) in
          switch event {
          case .completed(let data):
              print("Completed: Deleted \(data)")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


