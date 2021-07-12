//
//  Game.swift
//  VideoGameCollection
//
//  Created by Jonathon Lannon on 7/9/21.
//

import Foundation

struct GameResults: Codable{
    var count: Int
    var results: [GameSearch]
}

struct GameSearch: Codable, Identifiable{
    enum codingKey: CodingKey {
        case id, name, platforms
    }
    var id: Int
    let name: String
}