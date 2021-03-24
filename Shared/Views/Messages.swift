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
    case BroadcastFromYou
}

let OthersBubbleColor = Color("OthersBubbleColor")
let MyBubbleColor = Color("MyBubbleColor")

struct MessageView : View, Identifiable {
    let id = UUID()
    let type: TextMessageType
    
    let user: User?
    let message: Message?
    let text: String?
    
    var body: some View {
        switch type {
        case .BroadcastMessage:
            broadcastMessageView
        case .UserJoin:
            userJoinView
        case .BroadcastFromYou:
            broadcastFromYouMessageView
        }
    }
    
    var broadcastFromYouMessageView: some View {
        VStack {
            Text(text!).padding().background(MyBubbleColor).clipShape(Capsule(style: .continuous))
        }.frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    var broadcastMessageView: some View {
        VStack {
            Text("\(message!.from.name): \(message!.text)").padding().background(OthersBubbleColor).clipShape(Capsule(style: .continuous))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    var userJoinView: some View {
        Text("\(user!.name) joined the chat").frame(maxWidth: .infinity, alignment: .center)
    }
    
    init(broadcast message: Message) {
        self.type = .BroadcastMessage
        self.message = message
        self.text = nil
        self.user = nil
    }
    
    init(broadcastFromYou messageText: String) {
        self.type = .BroadcastFromYou
        self.text = messageText
        self.message = nil
        self.user = nil
    }
    
    init (join user: User) {
        self.type = .UserJoin
        self.user = user
        self.message = nil
        self.text = nil
    }
}
