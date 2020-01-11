//
//  CreatorsInfo.swift
//  Helen v1
//
//  Created by Amrutavarsh Kinagi on 11/1/2020.
//  Copyright © 2020 Helen. All rights reserved.
//

import SwiftUI

struct CreatorsInfo: View{
    var body: some View{
        ZStack{
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading){
                Text("Devs").foregroundColor(Color.white).font(.largeTitle).bold().padding(.top)
                
                HStack{
                    Image("amrut (1)").resizable().frame(width:100, height:100).cornerRadius(10).padding(.trailing)
                    
                    VStack(alignment: .leading){
                        Text("Amrutavarsh Kinagi").foregroundColor(Color.white).font(.title).bold()
                        
                        Text("askinagi@connect.ust.hk").foregroundColor(Color.white).font(.headline)
                    }
                }
                
                
                HStack{
                    Image("paddy1").resizable().frame(width:100, height:100).cornerRadius(10).padding(.trailing)
                    VStack(alignment: .leading){
                        Text("Padmanabhan Krishnamurthy").foregroundColor(Color.white).font(.title).bold()
                        
                        Text("pkaa@connect.ust.hk").foregroundColor(Color.white).font(.headline)
                    }
                }.padding(.top)
                
                Spacer()
            }
            
        }
    }
}

struct CreatorsInfo_Previews: PreviewProvider {
    static var previews: some View {
        CreatorsInfo()
    }
}
