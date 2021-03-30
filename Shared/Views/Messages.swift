//
//  Messages.swift
//  local-pal
//
//  Created by Schimweg, Luca on 24/03/2021.
//

import SwiftUI

enum TextMessageType {
    case UserJoin
    case UserLeave
    case Message
    case MessageFromYou
}

let OthersBubbleColor = Color("OthersBubbleColor")
let MyBubbleColor = Color("MyBubbleColor")

struct MessageView : View, Identifiable {
    let id = UUID()
    let type: TextMessageType
    
    var user: User? = nil
    var users: [User]? = nil
    var message: Message? = nil
    var isPrivate: Bool? = nil
    var text: String? = nil
    
    var body: some View {
        switch type {
        case .Message:
            messageView
        case .UserJoin:
            userJoinView
        case .UserLeave:
            userLeaveView
        case .MessageFromYou:
            messageFromYouView
        }
    }
    
    var messageFromYouView: some View {
        VStack {
            Text(((user != nil) ? "To \(user!.name): " : "") + text!)
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
        Text("\(user!.name) joined the chat").padding().frame(maxWidth: .infinity, alignment: .center)
    }
    
    var userLeaveView: some View {
        Text(users!.map({user in user.name}).joined(separator: ", ") + " left the chat").padding().frame(maxWidth: .infinity, alignment: .center)
    }
    
    init(received message: Message, isPrivate: Bool = false) {
        self.type = .Message
        self.message = message
        self.isPrivate = isPrivate
    }
    
    init(sent messageText: String, recipient: User? = nil) {
        self.type = .MessageFromYou
        self.text = messageText
        self.user = recipient
    }
    
    init(join user: User) {
        self.type = .UserJoin
        self.user = user
    }
    
    init(leave users: [User]) {
        self.type = .UserLeave
        self.users = users
    }
}
