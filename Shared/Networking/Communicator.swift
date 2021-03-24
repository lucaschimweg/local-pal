
import MultipeerConnectivity

protocol LocalPalCommunicatorDelegate {
    func receivedPacket(packet: Packet, from peerID: MCPeerID)
    func connected()
}

class LocalPalCommunicator : NSObject, ObservableObject {
    var session : MCSession?
    var service : LocalPalService?
    var myPeerId: MCPeerID?
    var delegate: LocalPalCommunicatorDelegate?
    var loggedIn: Bool = false
    
    @Published var connected: Bool = false
    
    func connect(peerId: MCPeerID) {
        self.myPeerId = peerId
        session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
    }
    
    func create() {
        self.loggedIn = true
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
        try broadcastPacket(packet: packet, exclude: nil)
    }
    
    func sendPacket(packet: Packet, to peerID: MCPeerID) throws {
        NSLog("%@", "Sending packet \(packet)")
        if let sess = session {
            let data = try JSONEncoder().encode(PacketContainer(pack: packet))
            try sess.send(data, toPeers: [peerID], with: .reliable)
        }
    }
    
    func broadcastPacket(packet: Packet, exclude excludedPeerID: MCPeerID?) throws {
        NSLog("%@", "Broadcasting packet \(packet)")
        if let sess = session {
            var to = sess.connectedPeers
            if let peerId = excludedPeerID {
                to.removeAll { (p) -> Bool in p == peerId }
            }
            
            let data = try JSONEncoder().encode(PacketContainer(pack: packet))
            try sess.send(data, toPeers: to, with: .reliable)
        }
    }
}

extension LocalPalCommunicator : MCSessionDelegate {

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
        if state == MCSessionState.connected {
            DispatchQueue.main.async {
                self.connected = true
                NSLog("%@", "Connected")
            }
            self.delegate?.connected()
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


