
import MultipeerConnectivity

protocol LocalPalCommunicatorDelegate {
    func receivedPacket(packet: Packet, from peerID: MCPeerID)
    func connected()
    func lostConnection(to peerId: MCPeerID)
}

class LocalPalCommunicator : NSObject, ObservableObject {
    var sessions : Dictionary<MCPeerID, MCSession> = Dictionary()
    var connectedPeers: Set<MCPeerID> = Set()
    var service : LocalPalService?
    var myPeerId: MCPeerID =  MCPeerID(displayName: UIDevice.current.name)
    var delegate: LocalPalCommunicatorDelegate?
    var loggedIn: Bool = false
    @Published var connected: Bool = false
    
    override init() {
        super.init()
    }
    
    func create() {
        self.loggedIn = true
        
        startService()
        connected = true
    }
    
    func createSession(peerId: MCPeerID) -> MCSession {
        let session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        sessions[peerId] = session
        return session
    }
    
    private func startService() {
        self.service = LocalPalService(peerId: myPeerId, sessionFactory: self.createSession)
    }
    
    func broadcastPacket(packet: Packet) throws {
        try broadcastPacket(packet: packet, exclude: nil)
    }
    
    func sendPacket(packet: Packet, to peerID: MCPeerID) throws {
        NSLog("%@", "Sending packet \(packet)")
    
        if let session = sessions[peerID] {
            let data = try JSONEncoder().encode(PacketContainer(pack: packet))
            try session.send(data, toPeers: [peerID], with: .reliable)
        } else {
            NSLog("%@", "Did not find peer \(peerID)! Not sending packet")
        }
        
    }
    
    func broadcastPacket(packet: Packet, exclude excludedPeerID: MCPeerID?) throws {
        NSLog("%@", "Broadcasting packet \(packet)")
        let data = try JSONEncoder().encode(PacketContainer(pack: packet))
        
        for peerID in connectedPeers {
            if peerID == excludedPeerID {
               continue
            }
            
            guard let sess = sessions[peerID] else {
                continue
            }
            
            try sess.send(data, toPeers: [peerID], with: .reliable)
        }
    }
}

extension LocalPalCommunicator : MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
        if state == MCSessionState.connected {
            connectedPeers.insert(peerID)
            DispatchQueue.main.async {
                self.connected = true
                NSLog("%@", "Connected")
            }
            self.delegate?.connected()
        } else {
            if connectedPeers.contains(peerID) {
                connectedPeers.remove(peerID)
                delegate?.lostConnection(to: peerID)
                NSLog("%@", "Lost connection to \(peerID), session contains \(session.connectedPeers)")
            }
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


