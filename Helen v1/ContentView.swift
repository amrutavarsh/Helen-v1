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
                Button(action:{}){
                    Text("</>").fontWeight(.bold).padding(7)
                    .foregroundColor(Color.white).background(Color.blue).cornerRadius(30)
                }
            }.padding().offset(y:5)
            
            ZStack(alignment: .trailing){
                camView.frame(height:550).offset(y:70).padding(.top, -70)
                
                Button(action:{}){
                    Text("Start/Stop").fontWeight(.bold).padding(7)
                    .foregroundColor(Color.white).background(Color.blue).cornerRadius(10)
                }.offset(x:-15,y:235)
            
                Button(action:{self.camView.callSwitchCam()}){
                    Text("Flip cam").fontWeight(.bold).padding(7)
                    .foregroundColor(Color.white).background(Color.black).cornerRadius(10)
                }.offset(x:-15,y:185)
                
            }.offset(y:-5)
            
            RoundedRectangle(cornerRadius:30).edgesIgnoringSafeArea(.bottom)
                .frame(height: 200).offset(y:10)
         
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
