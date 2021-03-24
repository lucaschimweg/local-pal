//
//  FindRoom.swift
//  local-pal
//
//  Created by Schimweg, Luca on 15/03/2021.
//

import SwiftUI

struct FindRoom: View {
    @StateObject private var connector: LocalPalConnector = LocalPalConnector()
    
    init() {
    }
    
    var body: some View {
        List {
            ForEach(self.connector.foundRooms) { room in
                NavigationLink(destination: Chat(connector: connector, foundRoom: room)) {
                    Text(room.name)
                }
            }
        }.navigationTitle("Join Room")
    }
}

struct FindRoom_Previews: PreviewProvider {
    static var previews: some View {
        FindRoom()
    }
}
