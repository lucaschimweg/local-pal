import Foundation
import MultipeerConnectivity
import Combine

protocol LocalPalRouterDelegate {
    func userJoin(user: User)
    func receiveBroadcastMessage(message: Message)
}

class LocalPalRouter : LocalPalCommunicatorDelegate, ObservableObject {
    @Published var comm: LocalPalCommunicator
    let ownUuid = UUID.init()
    var userPeers: Dictionary<UUID, MCPeerID> = Dictionary()
    var delegate: LocalPalRouterDelegate?
    
    var anyCancellable: AnyCancellable? = nil
    
    init() {
        comm = LocalPalCommunicator()
        comm.delegate = self
        
        anyCancellable = self.comm.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
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
        default:
            NSLog("Invalid packet!")
        }
    }
    
    private func receivedPropagateConnectedUsersPacket(packet: PropagateConnectedUsersPacket, from peerID: MCPeerID) {
        for user in packet.users {
            userPeers[user.uuid] = peerID
            NSLog("[PropagateConnectedUsersPacket] %@", "set userPeers[\(user.uuid)] = \(peerID)")
        }
    }
    
    private func receivedUserJoinPacket(packet: UserJoinPacket, from peerID: MCPeerID) {
        userPeers[packet.user.uuid] = peerID
        NSLog("[UserJoinPacket] %@", "set userPeers[\(packet.user.uuid)] = \(peerID)")
        delegate?.userJoin(user: packet.user)
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
}
