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
    
    @StateObject var chatManager = LocalPalChatManager()
    @State private var chatInput: String = ""
    
    
    var body: some View {
        VStack {
            if !chatManager.router.comm.connected {
                ProgressView().padding()
                Text("Connecting")
            } else {
                ScrollView() {
                    ForEach(self.chatManager.messages) { messageView in
                        messageView
                    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing).padding()
                }
                Spacer()
                HStack {
                    TextField("Type a message...", text: $chatInput)
                        .textFieldStyle(PlainTextFieldStyle())
                    Button("Send", action: {
                        print("Sending \(chatInput)")
                        send()
                    })
                }.padding()
            }
        }
        .navigationTitle("Local Pal Chat")
        .onAppear {
            if connector != nil {
                connector!.connect(room: foundRoom!, comm: chatManager.router.comm)
                
            } else {
                chatManager.router.comm.create()
            }
        }
    }
    
    func send() {
        do {
            try self.chatManager.sendBroadcastMessage(text: chatInput)
            chatInput = ""
        } catch let e {
            NSLog("%@", "Error sending message: \(e)")
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

