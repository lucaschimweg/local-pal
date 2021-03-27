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
    @State private var recipientIndex: Int = 0
    @State private var recipientPickerOpen: Bool = false
    
    private let recipients = ["Global", "Duc", "Luca", "Fabi"]
    
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
                VStack {
                    HStack {
                        Text("Recipient: ")
                        Button(recipients[recipientIndex], action: {
                            recipientPickerOpen = true
                        })
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        TextField("Type a message...", text: $chatInput)
                            .textFieldStyle(PlainTextFieldStyle())
                        Button("Send", action: {
                            print("Sending \(chatInput)")
                            send()
                        })
                    }
                }.padding().sheet(isPresented: $recipientPickerOpen) {
                    VStack {
                        Spacer()
                        Text("Choose recipient")
                        Picker("Recipient", selection: $recipientIndex) {
                            Text("Global").tag(0)
                            ForEach(1..<chatManager.router.users.count) { index in // Starting from 1 because index 0 = ownUser
                                Text(chatManager.router.users[index].user.name)
                            }
                        }
                        
                        Text(recipientIndex != 0 ? "\(recipients[recipientIndex])'s public key hash" : " ")
                        Text(recipientIndex != 0 ? String(chatManager.router.cryptoProvider.publicKeyHash) : " ")
                            .font(.system(.body, design: .monospaced))
                    
                        Button("OK", action: {
                            recipientPickerOpen = false
                        }).padding()
                        
                        Spacer()
                        Text("Your public key hash")
                        Text(String(chatManager.router.cryptoProvider.publicKeyHash)).font(.system(.body, design: .monospaced))
                    }
                }
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
            if recipientIndex == 0 {
                try self.chatManager.sendBroadcastMessage(text: chatInput)
            } else {
                try self.chatManager.sendPrivateMessage(to: chatManager.router.users[recipientIndex].user, text: chatInput)
            }
            
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

extension View {
    @ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
        switch shouldHide {
        case true: self.hidden()
        case false: self
        }
    }
}
