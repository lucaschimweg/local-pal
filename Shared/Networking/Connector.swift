
import Foundation
import MultipeerConnectivity
import SwiftUI

class FoundRoom : Identifiable, ObservableObject {
    var id: ObjectIdentifier {
        return ObjectIdentifier(self)
    }
    public let name: String
    public let peerID: MCPeerID
    
    init(peerID: MCPeerID) {
        self.peerID = peerID
        self.name = peerID.displayName
    }
}

class LocalPalConnector : NSObject, ObservableObject {
    
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceBrowser : MCNearbyServiceBrowser
    
    @Published public var foundRooms: [FoundRoom] = [FoundRoom]()
    
    override init() {
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: LocalPalServiceType)
        
        super.init()
        
        NSLog("Starting to search!")
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    func connect(room: FoundRoom, comm: LocalPalCommunicator) {
        comm.myPeerId = myPeerId
        let sess = comm.createSession(peerId: room.peerID)
        self.serviceBrowser.invitePeer(room.peerID, to: sess, withContext: nil, timeout: 10)
    }
}

extension LocalPalConnector : MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        self.foundRooms.append(FoundRoom(peerID: peerID))
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
        self.foundRooms.removeAll(where: { room in room.peerID.displayName == peerID.displayName })
    }

}

