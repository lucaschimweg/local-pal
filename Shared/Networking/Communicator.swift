
import MultipeerConnectivity

protocol LocalPalCommunicatorDelegate {
    func receivedPacket(packet: Packet, from peerID: MCPeerID)
}

class LocalPalCommunicator : NSObject, ObservableObject {
    var session : MCSession?
    var service : LocalPalService?
    var myPeerId: MCPeerID?
    var delegate: LocalPalCommunicatorDelegate?
    
    @Published var connected: Bool = false
    
    func connect(peerId: MCPeerID) {
        self.myPeerId = peerId
        session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
    }
    
    func create() {
        self.myPeerId = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: self.myPeerId!, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        
        startService()
        connected = true
    }
    
    private func startService() {
        if let unwrapped = self.myPeerId {
            self.service = LocalPalService(peerId: unwrapped, session: session!)
        }
    }
    
    func broadcastPacket(packet: Packet) throws {
        if let sess = session {
            let data = try JSONEncoder().encode(PacketContainer(pack: packet))
            try sess.send(data, toPeers: sess.connectedPeers, with: .reliable)
        }
    }
}

extension LocalPalCommunicator : MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
        DispatchQueue.main.async {
            if state == MCSessionState.connected {
                self.connected = true
            }
            DispatchQueue.global().async {
                do {
                    try self.broadcastPacket(packet: UserJoinPacket(user: User(name: "Duc", uuid: UUID.init())))
                    try self.broadcastPacket(packet: PropagateConnectedUsersPacket())
                    try self.broadcastPacket(packet: BroadcastMessagePacket(message: Message(from: User(name: "Duc", uuid: UUID.init()), text: "😏")))
                } catch let e {
                    NSLog("%@", "error sending packet: \(e)")
                }

            }
            NSLog("%@", "Connected")
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        do {
            let pack = try JSONDecoder().decode(PacketContainer.self, from: data)
            NSLog("%@", "got packet: \(pack)")
            self.delegate?.receivedPacket(packet: pack.packet, from: peerID)
        } catch let e {
            NSLog("%@", "error: \(e)")
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }

}


