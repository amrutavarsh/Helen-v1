//
//  ContentView.swift
//  Helen v1
//
//  Created by Amrutavarsh Kinagi on 27/11/2019.
//  Copyright © 2019 Helen. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    let camView = CameraView()
    @State var startStream = false
    @State var showCreatorsInfo = false
    var body: some View {
        ZStack{
            camView
            
            //Use for UIViewDebug
            //Rectangle().fill(Color.green)
            
            VStack(alignment: .trailing) {
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
                        Button(action:{self.showCreatorsInfo.toggle()}){Text("</>").fontWeight(.bold).padding(7).foregroundColor(Color.white).background(Color.blue).cornerRadius(30).sheet(isPresented: $showCreatorsInfo, content: {CreatorsInfo()})
                        }
                    }.padding()
                    
                }
                
                Spacer()
                
                Group{
                    
                    VStack(alignment: .trailing){
                        Button(action:{self.camView.callSwitchCam()}){
                            Text("Flip cam").fontWeight(.bold).padding(7)
                                .foregroundColor(Color.white).background(Color.black).cornerRadius(10)
                        }.padding(.vertical)
                        
                        Button(action:{
                            self.camView.toggleStartStream()
                            self.startStream.toggle()
                        }){
                            Text(recordButtonText(streamState: self.startStream)).fontWeight(.bold).padding(7).foregroundColor(Color.white).background(recordButtonColor(streamState: self.startStream)).cornerRadius(10)
                        }
                    }.padding(.horizontal)
                    
                    ZStack{
                        
                        RoundedRectangle(cornerRadius:30).opacity(0.7).frame(height: 250)
                        
                        TextField(/*@START_MENU_TOKEN@*/"Placeholder"/*@END_MENU_TOKEN@*/, text: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Value@*/.constant("")/*@END_MENU_TOKEN@*/).frame(height: 160).padding()
                    }.offset(y:30).padding(.top, -30)
                }
            }
            
        }.edgesIgnoringSafeArea(.all)
    }
}

func recordButtonText(streamState: Bool) -> String {return (streamState ? "Stop" : "Start")}
func recordButtonColor(streamState: Bool) -> Color {return (streamState ? Color.red : Color.blue)}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
