//
//  Messages.swift
//  local-pal
//
//  Created by Schimweg, Luca on 24/03/2021.
//

import SwiftUI

enum TextMessageType {
    case UserJoin
    case Message
    case MessageFromYou
}

let OthersBubbleColor = Color("OthersBubbleColor")
let MyBubbleColor = Color("MyBubbleColor")

struct MessageView : View, Identifiable {
    let id = UUID()
    let type: TextMessageType
    
    let user: User?
    let message: Message?
    let isPrivate: Bool?
    let text: String?
    
    var body: some View {
        switch type {
        case .Message:
            messageView
        case .UserJoin:
            userJoinView
        case .MessageFromYou:
            messageFromYouView
        }
    }
    
    var messageFromYouView: some View {
        VStack {
            Text((user != nil) ? "To \(user!.name): " : "" + text!)
                .padding().background(MyBubbleColor).clipShape(Capsule(style: .continuous))
        }.frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    var messageView: some View {
        VStack {
            Text("\(message!.from.name)" + ((isPrivate!) ? " (private) " : "") + ": \(message!.text)")
                .padding().background(OthersBubbleColor).clipShape(Capsule(style: .continuous))
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    var userJoinView: some View {
        Text("\(user!.name) joined the chat").frame(maxWidth: .infinity, alignment: .center)
    }
    
    init(received message: Message, isPrivate: Bool = false) {
        self.type = .Message
        self.message = message
        self.isPrivate = isPrivate
        self.text = nil
        self.user = nil
    }
    
    init(sent messageText: String, recipient: User? = nil) {
        self.type = .MessageFromYou
        self.text = messageText
        self.user = recipient
        self.message = nil
        self.isPrivate = nil
    }
    
    init (join user: User) {
        self.type = .UserJoin
        self.user = user
        self.message = nil
        self.text = nil
        self.isPrivate = nil
    }
}
