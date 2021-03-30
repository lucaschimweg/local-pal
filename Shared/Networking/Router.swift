import Foundation
import MultipeerConnectivity
import Combine

protocol LocalPalRouterDelegate {
    func userJoin(user: User)
    func receiveBroadcastMessage(message: Message)
    func receivePrivateMessage(message: Message)
    func usersLeft(users: [User])
}

class LocalPalRouter : LocalPalCommunicatorDelegate, ObservableObject {
    @Published var comm: LocalPalCommunicator
    let ownUser : UserWithKey
    var userPeers: Dictionary<UUID, MCPeerID> = Dictionary()
    @Published var users: [UserWithKey] = [UserWithKey]()
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
        case let pack as UserLeavePacket:
            receiveUserLeavePacket(packet: pack, from: peerID)
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
            let pack = UserJoinPacket(user: packet.user, initial: false)
            try comm.broadcastPacket(packet: pack, exclude: peerID)
            if packet.initial {
                try comm.sendPacket(packet: PropagateConnectedUsersPacket(users: users), to: peerID)
            }
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
    
    private func receiveUserLeavePacket(packet: UserLeavePacket, from peerID: MCPeerID) {
        do {
            try comm.broadcastPacket(packet: packet, exclude: peerID)
        } catch let e {
            NSLog("%@", "Error sending packet: \(e)")
        }
        
        var lostUUIDs = Set<UUID>()
        for user in packet.users {
            lostUUIDs.insert(user.uuid)
        }
        
        for uuid in lostUUIDs {
            userPeers.removeValue(forKey: uuid)
        }
            
        users.removeAll(where: { user in lostUUIDs.contains(user.user.uuid)} )
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        cryptoProvider.usersLeave(users: packet.users)
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
                try comm.broadcastPacket(packet: UserJoinPacket(user: ownUser, initial: true))
                self.comm.create()
            } catch let e {
                NSLog("%@", "Error sending packet: \(e)")
                comm.loggedIn = false
            }
        }
    }
    
    func lostConnection(to peerId: MCPeerID) {
        do {
            var lostUUIDs = Set<UUID>()
            for entry in userPeers {
                if entry.value == peerId {
                    lostUUIDs.insert(entry.key)
                }
            }
            
            var lostUsers = [User]()
            for user in users {
                if lostUUIDs.contains(user.user.uuid) {
                    lostUsers.append(user.user)
                }
            }
            
            for uuid in lostUUIDs {
                userPeers.removeValue(forKey: uuid)
            }
            
            users.removeAll(where: { user in lostUUIDs.contains(user.user.uuid)} )
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            
            cryptoProvider.usersLeave(users: lostUsers)
            
            try comm.broadcastPacket(packet: UserLeavePacket(users: lostUsers))
            delegate?.usersLeft(users: lostUsers)
            
        } catch let e {
            NSLog("%@", "Error processing connection loss: \(e)")
            comm.loggedIn = false
        }
    }
}
