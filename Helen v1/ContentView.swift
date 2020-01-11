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
    @State var showCreatorsInfo = false
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
                Button(action:{self.showCreatorsInfo.toggle()}){Text("</>").fontWeight(.bold).padding(7).foregroundColor(Color.white).background(Color.blue).cornerRadius(30)
                }
            }.padding(.horizontal)
            
            ZStack(alignment: .trailing){
                camView
                
                //Use for UIViewDebug
                //Rectangle().fill(Color.green)
                
                VStack(alignment: .trailing){
                    Spacer()
                    
                    VStack(alignment: .trailing){
                    Button(action:{self.camView.callSwitchCam()}){
                        Text("Flip cam").fontWeight(.bold).padding(7)
                        .foregroundColor(Color.white).background(Color.black).cornerRadius(10)
                    }.padding(.vertical)
                    
                        Button(action:{}){
                        Text("Start/Stop").fontWeight(.bold).padding(7)
                        .foregroundColor(Color.white).background(Color.blue).cornerRadius(10)
                    }
                    }.padding(.horizontal)
                
                    RoundedRectangle(cornerRadius:30).opacity(0.7).frame(height: 220)
                }.offset(y:30)
                
            }.edgesIgnoringSafeArea(.bottom)
            
        }.sheet(isPresented: $showCreatorsInfo, content: {CreatorsInfo()})
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
