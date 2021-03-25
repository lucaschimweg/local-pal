//
//  Server.swift
//  local-pal
//
//  Created by Schimweg, Luca on 15/03/2021.
//

import Foundation
import MultipeerConnectivity

public let LocalPalServiceType = "local-pal"

typealias SessionFactory = (MCPeerID) -> MCSession

class LocalPalService : NSObject {

    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    var sessionFactory : SessionFactory
    
    init(peerId: MCPeerID, sessionFactory: @escaping SessionFactory) {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: nil, serviceType: LocalPalServiceType)
        self.sessionFactory = sessionFactory
        
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
        let session = self.sessionFactory(peerID)
        invitationHandler(true, session)
    }
    
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
}
