//
//  ConversationsModels.swift
//  Messenger
//
//  Created by Ezequiel Parada Beltran on 01/09/2020.
//  Copyright © 2020 Ezequiel Parada. All rights reserved.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
