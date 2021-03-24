//
//  MainMenu.swift
//  local-pal
//
//  Created by Schimweg, Luca on 15/03/2021.
//

import SwiftUI
import MultipeerConnectivity

struct MainMenu: View {
    @State private var service: LocalPalService?
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("Welcome to local-pal!")
                    .padding()
                Spacer()
                NavigationLink(destination: Chat()) {
                    Text("Start Room")
                }.padding()
                NavigationLink(destination: FindRoom()) {
                    Text("Join Room")
                }.padding()

                Spacer()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MainMenu_Previews: PreviewProvider {
    static var previews: some View {
        MainMenu()
    }
}
