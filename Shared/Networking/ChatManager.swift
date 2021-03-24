import Foundation
import SwiftUI
import Combine

class LocalPalChatManager : ObservableObject {
    @Published var router: LocalPalRouter
    @Published var messages: [MessageView] = [MessageView]()
    var anyCancellable: AnyCancellable? = nil
    
    init() {
        self.router = LocalPalRouter()
        self.router.delegate = self
        
        anyCancellable = self.router.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
    }
    
    private func addMessageView(view: MessageView) {
        DispatchQueue.main.async {
            self.messages.append(view)
        }
    }
    
    func sendBroadcastMessage(text: String) throws {
        do {
            try router.sendBroadcastMessage(text: text)
            addMessageView(view: MessageView(broadcastFromYou: text))
        } catch let e {
            NSLog("%@", "Error sending packet: \(e)")
        }
    }
    
}

extension LocalPalChatManager : LocalPalRouterDelegate {
    func userJoin(user: User) {
        addMessageView(view: MessageView(join: user))
    }
    
    func receiveBroadcastMessage(message: Message) {
        addMessageView(view: MessageView(broadcast: message))
    }
}
