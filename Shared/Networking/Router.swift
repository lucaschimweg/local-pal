import Foundation
import MultipeerConnectivity
import Combine

protocol LocalPalRouterDelegate {
    func userJoin(user: User)
    func receiveBroadcastMessage(message: Message)
    func receivePrivateMessage(message: Message)
}

class LocalPalRouter : LocalPalCommunicatorDelegate, ObservableObject {
    @Published var comm: LocalPalCommunicator
    let ownUser : UserWithKey
    var userPeers: Dictionary<UUID, MCPeerID> = Dictionary()
    var users: [UserWithKey] = [UserWithKey]()
    var delegate: LocalPalRouterDelegate?
    var cryptoProvider: LocalPalCryptoProvider
    
    
    var anyCancellable: AnyCancellable? = nil
    
    init() {
        self.cryptoProvider = try! LocalPalCryptoProvider()
        
        let comm = LocalPalCommunicator()
        self.comm = comm
        
        ownUser = UserWithKey(user: User(name: UIDevice.current.name, uuid: UUID()), publicKey: cryptoProvider.publicKeyRepr)
        users.append(ownUser)
        
        self.comm.delegate = self
        
        anyCancellable = self.comm.objectWillChange.sink { [self] (_) in
            self.objectWillChange.send()
        }
    }
    
    func receivedPacket(packet: Packet, from peerID: MCPeerID) {
        switch packet {
        case let pack as PropagateConnectedUsersPacket:
            receivedPropagateConnectedUsersPacket(packet: pack, from: peerID)
        case let pack as UserJoinPacket:
            receivedUserJoinPacket(packet: pack, from: peerID)
        case let pack as BroadcastMessagePacket:
            receivedBroadcastMessagePacket(packet: pack, from: peerID)
        case let pack as PrivateMessagePacket:
            receivePrivateMessagePacket(packet: pack, from: peerID)
        default:
            NSLog("Invalid packet!")
        }
    }
    
    private func receivedPropagateConnectedUsersPacket(packet: PropagateConnectedUsersPacket, from peerID: MCPeerID) {
        for user in packet.users {
            userPeers[user.user.uuid] = peerID
            users.append(user)
            cryptoProvider.registerUser(id: user.user.uuid, key: user.publicKey)
            NSLog("[PropagateConnectedUsersPacket] %@", "set userPeers[\(user.user.uuid)] = \(peerID)")
        }
    }
    
    private func receivedUserJoinPacket(packet: UserJoinPacket, from peerID: MCPeerID) {
        userPeers[packet.user.user.uuid] = peerID
        cryptoProvider.registerUser(id: packet.user.user.uuid, key: packet.user.publicKey)
        NSLog("[UserJoinPacket] %@", "set userPeers[\(packet.user.user.uuid)] = \(peerID)")
        delegate?.userJoin(user: packet.user.user)
        
        do {
            try comm.broadcastPacket(packet: packet, exclude: peerID)
            try comm.sendPacket(packet: PropagateConnectedUsersPacket(users: users), to: peerID)
        } catch let e {
            NSLog("%@", "Error sending packet: \(e)")
        }
        
        users.append(packet.user)
    }
    
    private func receivedBroadcastMessagePacket(packet: BroadcastMessagePacket, from peerID: MCPeerID) {
        delegate?.receiveBroadcastMessage(message: packet.message)
        do {
            NSLog("[BroadcastMessagePacket] %@", "broadcasting packet: \(packet)")
            try comm.broadcastPacket(packet: packet, exclude: peerID)
        } catch let e {
            NSLog("%@", "Error sending packet: \(e)")
        }
    }
    
    private func receivePrivateMessagePacket(packet: PrivateMessagePacket, from peerId: MCPeerID) {
        if packet.recipient != ownUser.user.uuid {
            // Packet not for us
            if let peerId = userPeers[packet.recipient] {
                do {
                    try self.comm.sendPacket(packet: packet, to: peerId)
                } catch let e {
                    NSLog("%@", "Error sending packet: \(e)")
                }
            }
        } else {
            // Packet for us
            do {
                let text = try cryptoProvider.decryptMessage(data: packet.message.text)
                delegate?.receivePrivateMessage(message: Message(from: packet.message.from, text: text))
            } catch let e {
                NSLog("%@", "Error decrypting packet: \(e)")
            }
        }
    }
    
    func sendBroadcastMessage(text: String) throws {
        try self.comm.broadcastPacket(packet: BroadcastMessagePacket(message: Message(from: ownUser.user, text: text)))
    }
    
    func sendPrivateMessage(to recipientUuid: UUID, text: String) throws {
        let encrypted = try cryptoProvider.encryptMessage(to: recipientUuid, text: text)
        
        guard let peerId = userPeers[recipientUuid] else {
            throw LocalPalError.unknownUser
        }
        
        try self.comm.sendPacket(packet: PrivateMessagePacket(recipient: recipientUuid, message: PrivateMessage(from: ownUser.user, text: encrypted)), to: peerId)
    }
    
    func connected() {
        if !comm.loggedIn {
            do {
                comm.loggedIn = true
                try comm.broadcastPacket(packet: UserJoinPacket(user: ownUser))
                self.comm.create()
            } catch let e {
                NSLog("%@", "Error sending packet: \(e)")
                comm.loggedIn = false
            }
        }
    }
}
