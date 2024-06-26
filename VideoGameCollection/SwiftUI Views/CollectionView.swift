//
//  CollectionView.swift
//  VideoGameCollection
//
//  Created by Jon Iger on 7/25/21.
//

import SwiftUI
import Foundation

/**
 View responsible for displaying the users game collection from the cloud database and search for games in the collection
 */
struct CollectionView: View {
    // MARK: Variables
    @EnvironmentObject var cloudContainer: CloudContainer  //environment object used for storing the current user
    @State var viewModel = ViewModel()
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // MARK: SwiftUI Body
    var body: some View {
        let bindSearch = Binding<String>(
            get: {viewModel.searchText},
            set: {
                viewModel.setBindSearch(string: $0, games: cloudContainer.gameCollection)
            }
        )
        NavigationView{
            if viewModel.canLoad{
                VStack{
                    if cloudContainer.gameCollection.count != 0{
                        if !viewModel.gridView{
                            List{
                                if viewModel.platformFilter{
                                    PlatformListView(platformDict: viewModel.platformDict)
                                }
                                else{
                                    HStack{
                                        Image(systemName: "magnifyingglass")
                                            .padding(4)
                                        TextField("Search", text: bindSearch)
                                            .onTapGesture {
                                                viewModel.activeSearch = true
                                            }
                                    }
                                    if !viewModel.activeSearch{
                                        ForEach(Array(cloudContainer.gameCollection), id: \.self){ game in
                                            GameCollectionRow(id: game.gameId)
                                        }
                                        .onDelete(perform: deleteGame)
                                    }
                                    else{
                                        ForEach(viewModel.searchResults, id: \.self){ gameId in
                                            GameCollectionRow(id: gameId)
                                        }
                                    }
                                }
                            }
                        }
                        else if viewModel.gridView{
                            ScrollView{
                                HStack{
                                    Image(systemName: "magnifyingglass")
                                        .padding(4)
                                    TextField("Search", text: bindSearch)
                                        .onTapGesture {
                                            viewModel.activeSearch = true
                                        }
                                }
                                .padding(7)
                                LazyVGrid(columns: columns){
                                    ForEach(Array(cloudContainer.gameCollection), id: \.self){ game in
                                        GameCollectionGrid(id: game.gameId)
                                    }
                                }
                            }
                        }
                    }
                    else{
                        Spacer()
                        Text("Welcome to Game Collect! Add some games to get started 🙂")
                            .padding()
                            .multilineTextAlignment(.center)
                        Image("Welcome Controller")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                        Spacer()
                    }
                    
                }
                .navigationTitle("Game Collection")
                .navigationBarItems(leading: EditButton(), trailing:
                                        Menu{
                                            Section{
                                                Button{
                                                    viewModel.gridView = false
                                                }
                                                label:{
                                                    Image(systemName: "list.bullet")
                                                    Text("List View")
                                                }
                                                Button{
                                                    viewModel.gridView = true
                                                }
                                                label:{
                                                    Image(systemName: "square.grid.2x2")
                                                    Text("Grid View")
                                                }
                                            }
                                            Section{
                                                Button{
                                                    viewModel.platformFilter = false
                                                    sortByDate()
                                                }
                                                label:{
                                                    Image(systemName: "clock")
                                                    Text("Recently Added")
                                                }
                                                Button{
                                                    viewModel.platformFilter = true
                                                }
                                                label:{
                                                    Image(systemName: "gamecontroller")
                                                    Text("Platform")
                                                }
                                                Button{
                                                    viewModel.platformFilter = false
                                                    sortByTitle()
                                                }
                                                label:{
                                                    Image(systemName: "abc")
                                                    Text("Title")
                                                }
                                            }
                                        } label:{
                                            Image(systemName: "ellipsis.circle")
                                        }
                )
                if cloudContainer.gameCollection.isEmpty && UserDefaults.standard.integer(forKey: "lastViewedGame") == 0{
                    Spacer()
                    Text("Welcome to Game Collect! Add some games to get started 🙂")
                        .padding()
                        .multilineTextAlignment(.center)
                    Image("Welcome Controller")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    Spacer()
                }
                else{
                    GameDetailsView(gameId: UserDefaults.standard.integer(forKey: "lastViewedGame"))
                }
            }
            else{
                VStack{
                    ActivityIndicator(shouldAnimate: $viewModel.shouldAnimate)
                    if !viewModel.shouldAnimate{
                        Text("Unable to display data. Either RAWG or your internet connection is offline. Try again later 😞.")
                    }
                }
            }
        }
        .onAppear{
            handleOnAppear()
        }
    }
    
    // MARK: Other Functions
    /**
     handleOnAppear()-check the status of the API and whether it's online or not. If offline, display something else instead
     */
    func handleOnAppear() {
        viewModel.checkDatabaseStatus()
        viewModel.bingTest()
    }
    /**
     deleteGame(at offsets: IndexSet)-delete games in the container game collection at the specified indexes
     */
    func deleteGame(at offsets: IndexSet) {
        cloudContainer.gameCollection.remove(atOffsets: offsets)
    }
    /**
     sortByTitle()-sort games in the game collection array from the container by title
     */
    func sortByTitle(){
        cloudContainer.gameCollection.sort(by: {$0.title < $1.title})
    }
    /**
     sortByDate()-sort games in the game collection array from the container by date
     */
    func sortByDate(){
        cloudContainer.gameCollection.sort(by: {$0.dateAdded > $1.dateAdded})
    }
}

// MARK: Content Preview
struct CollectionView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionView()
    }
}
