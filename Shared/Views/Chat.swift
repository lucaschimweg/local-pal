//
//  Chat.swift
//  local-pal
//
//  Created by Schimweg, Luca on 15/03/2021.
//

import SwiftUI

struct Chat: View {
    let connector: LocalPalConnector?
    let foundRoom: FoundRoom?
    
    @StateObject var communicator : LocalPalCommunicator = LocalPalCommunicator()
    @State private var chatInput: String = ""
    
    var body: some View {
        VStack {
            if !communicator.connected {
                ProgressView().padding()
                Text("Connecting")
            } else {
                ScrollView() {
                    Text("Hi")
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.leading)
                }.frame(maxWidth: .infinity)
                Spacer()
                HStack {
                    TextField("Type a message...", text: $chatInput)
                        .textFieldStyle(PlainTextFieldStyle())
                    Button("Send", action: {
                        print("Sending \(chatInput)")
                    })
                }.padding()
            }
        }
        .navigationTitle("Local Pal Chat")
        .onAppear {
            if connector != nil {
                connector!.connect(room: foundRoom!, comm: communicator)
            } else {
                communicator.create()
            }
        }
    }
    
    init(connector: LocalPalConnector, foundRoom: FoundRoom) {
        self.connector = connector
        self.foundRoom = foundRoom
    }
    
    init() {
        self.connector = nil
        self.foundRoom = nil
    }
}

