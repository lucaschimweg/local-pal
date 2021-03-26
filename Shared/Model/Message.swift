//
//  Message.swift
//  local-pal
//
//  Created by Schimweg, Luca on 16/03/2021.
//

import Foundation
import SwiftUI

struct Message : Codable {
    let from: User
    let text: String
}

struct PrivateMessage : Codable {
    let from: User
    let text: Data
}
