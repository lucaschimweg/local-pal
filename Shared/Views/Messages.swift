//
//  Messages.swift
//  local-pal
//
//  Created by Schimweg, Luca on 24/03/2021.
//

import SwiftUI

enum TextMessageType {
    case UserJoin
    case BroadcastMessage
}

struct MessageView : View, Identifiable {
    let id = UUID()
    let type: TextMessageType
    
    let user: User?
    let message: Message?
    
    var body: some View {
        switch type {
        case .BroadcastMessage:
            broadcastMessageView
        case .UserJoin:
            userJoinView
        default:
            Text("Unimplemented message type")
        }
    }
    
    var broadcastMessageView: some View {
        Text("\(message!.from.name): \(message!.text)")
    }

    var userJoinView: some View {
        Text("\(user!.name) joined the chat")
    }
    
    init(broadcast message: Message) {
        self.type = .BroadcastMessage
        self.message = message
        self.user = nil
    }
    
    init (join user: User) {
        self.type = .UserJoin
        self.user = user
        self.message = nil
    }
}
