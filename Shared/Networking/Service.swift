//
//  Server.swift
//  local-pal
//
//  Created by Schimweg, Luca on 15/03/2021.
//

import Foundation
import MultipeerConnectivity

public let LocalPalServiceType = "local-pal"

class LocalPalService : NSObject {

    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    var session : MCSession
    
    init(peerId: MCPeerID, session: MCSession) {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: nil, serviceType: LocalPalServiceType)
        self.session = session
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
    }
}

extension LocalPalService : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
    
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
}
