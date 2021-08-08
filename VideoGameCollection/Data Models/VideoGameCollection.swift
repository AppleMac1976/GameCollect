//
//  VideoGameCollection.swift
//  VideoGameCollection
//
//  Created by Jonathon Lannon on 7/9/21.
//

import Foundation
import CloudKit

class VideoGameCollection: ObservableObject{
    @Published var gameCollection: [Game]
    
    init(){
        self.gameCollection = []
    }
    
    static func loadiCloudGames()->VideoGameCollection{
        let finalCollect: VideoGameCollection = VideoGameCollection()
        let pred = NSPredicate(value: true)
        let query = CKQuery(recordType: "Game", predicate: pred)
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["title", "id", "dateAdded"]
        
        var finalCollection: [Game] = []
        
        operation.recordFetchedBlock = { record in
            let game = Game()
            game.title = record["title"]
            game.gameId = record["id"]
            game.recordID = record.recordID
            game.dateAdded = record["dateAdded"]
            finalCollection.append(game)
        }
        
        operation.queryCompletionBlock = {(cursor, error) in
            DispatchQueue.main.async {
                if error == nil {
                    print("Cloud load success!")
                    finalCollect.gameCollection = finalCollection
                } else {
                    print("Cloud load failed!")
                }
            }
        }
        CKContainer(identifier: "iCloud.com.Jonathon-Lannon.VideoGameCollection").publicCloudDatabase.add(operation)
        return finalCollect
    }
    
    static func saveiCloudGame(newGame: Game){
        let gameRecord = CKRecord(recordType: "Game")
        gameRecord["title"] = newGame.title as CKRecordValue
        gameRecord["dateAdded"] = newGame.dateAdded as CKRecordValue
        gameRecord["id"] = newGame.gameId as CKRecordValue
        CKContainer(identifier: "iCloud.com.Jonathon-Lannon.VideoGameCollection").publicCloudDatabase.save(gameRecord) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Success in the Cloud!")
                }
            }
        }
    }
    
    static func deleteiCloudGame(oldGame: Game){
        CKContainer(identifier: "iCloud.com.Jonathon-Lannon.VideoGameCollection").publicCloudDatabase.delete(withRecordID: oldGame.recordID){(recordID, error) in
            if error == nil{
                print("Cloud delete success!")
            }
            else{
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    func isEmpty()->Bool{
        if self.gameCollection.count == 0{
            return true
        }
        else{
            return false
        }
    }
}
