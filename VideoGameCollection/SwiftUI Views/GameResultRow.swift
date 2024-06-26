//
//  GameResultRow.swift
//  VideoGameCollection
//
//  Created by Jon Iger on 7/11/21.
//

import SwiftUI

/**
 View that displays a singular row of game data when searching with the AddGameView
 */
struct GameResultRow: View {
    // MARK: Constants and Variables
    let title: String   //name of the game to be displayed
    let id: Int
    let platformArray: [PlatformSearchResult]   //array of platform search results
    var stringPlatforms: String {
        //for every platform a game has (except the last one in the array), add a comma next to the platform's name, and put it into the string to be used to the display the list of platforms in the view
        var tempString = String()
        var index = 0
        for platform in platformArray{
            tempString.append(platform.platform.name)
            if index != platformArray.count - 1{
                tempString.append(", ")
            }
            index += 1
        }
        return tempString
    }
    
    // MARK: SwiftUI Body
    var body: some View {
        NavigationLink(destination: GameDetailsView(gameId: id)){
            VStack{
                Text(title)
                    .padding()
                    .multilineTextAlignment(.center)
                Text(stringPlatforms)
                    .font(.caption)
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: Content Preview
struct GameResultRow_Previews: PreviewProvider {
    static var previews: some View {
        GameResultRow(title: "Sonic the Hedgehog", id: 0, platformArray: [])
    }
}
