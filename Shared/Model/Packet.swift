//
//  Packet.swift
//  local-pal
//
//  Created by Schimweg, Luca on 16/03/2021.
//

import Foundation

enum PacketType : Int8 {
    case PropagateConnectedUsersPacket = 1
    case UserJoinPacket = 2
    case BroadcastMessagePacket = 3
}

struct PacketContainer : Codable {
    let packet: Packet
    
    enum CodingKeys: String, CodingKey {
        case packetType
        case packet
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch packet {
        case let pack as PropagateConnectedUsersPacket:
            try container.encode(PacketType.PropagateConnectedUsersPacket.rawValue, forKey: .packetType)
            try container.encode(pack, forKey: .packet)
        case let pack as UserJoinPacket:
            try container.encode(PacketType.UserJoinPacket.rawValue, forKey: .packetType)
            try container.encode(pack, forKey: .packet)
        case let pack as BroadcastMessagePacket:
            try container.encode(PacketType.BroadcastMessagePacket.rawValue, forKey: .packetType)
            try container.encode(pack, forKey: .packet)
        default:
            NSLog("Invalid packet!")
        }
    }
    
    init (pack: Packet) {
        packet = pack
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let packetType = PacketType(rawValue: try container.decode(Int8.self, forKey: .packetType))!
        
        switch packetType {
        case .PropagateConnectedUsersPacket:
            packet = try container.decode(PropagateConnectedUsersPacket.self, forKey: .packet)
        case .UserJoinPacket:
            packet = try container.decode(UserJoinPacket.self, forKey: .packet)
        case .BroadcastMessagePacket:
            packet = try container.decode(BroadcastMessagePacket.self, forKey: .packet)
        }
    }
}

protocol Packet : Codable {
}

class PropagateConnectedUsersPacket : Packet {
    let users: [User]
    
    init() {
        users = []
    }
    
}

struct UserJoinPacket : Packet {
    let user: User
}

struct BroadcastMessagePacket : Packet {
    let message: Message
}

struct User : Codable {
    let name: String
    let uuid: UUID
}
