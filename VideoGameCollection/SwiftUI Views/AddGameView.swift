//
//  AddGameView.swift
//  VideoGameCollection
//
//  Created by Jonathon Lannon on 7/9/21.
//

//import the following frameworks...
import SwiftUI

/**
 View that contains the screen users will use to add new games to their collection
 */
struct AddGameView: View {
    @EnvironmentObject var gameObject: VideoGameCollection      //the object in the SwiftUI environment that contains the user's current game collection
    @State var searchText = String()    //string sent into API calls with the search bar
    @State var displayText = String()   //string to be displayed to the user when typing in the search bar
    @State var gameResults: GameResults = GameResults()     //empty GameResults object that will later on store search results when used with the API
    @State var showExact: Bool = false      //boolean value to toggle "exact search" filter on or off
    @State var platformSelection = "No selection"     //string holding the user's selection of console/platform filter
    @State var platformAPISelect = String()     //string holding the final string of the user's platform selection. This string must first be modified to have spaces removed from it with "-" character in it's place instead
    @State var showAnimation = false    //boolean for determining when the activity indicator should be animating or not
    @State var platformDict = [:]       //empty dictionary that will hold the names and ids of the platforms supported in the API at that time
    @State var platformNames: [String] = []     //empty string array that will hold all of the names of the platforms supported by the API. Data is loaded into the array upon appearance of this view
    @State var showCamera = false
    @State var scanner: ScannerViewController? = ScannerViewController()
    @State var postCameraSuccessAlert = false
    @State var barcodeResult = String()
    @State var barcodeID = 0
    @State var barcodePlatforms: [PlatformSearchResult] = []
    @State var metacriticSortGreater = false
    
    //initial body
    var body: some View {
        //custom binding for filtering out " " characters and replacing them with "-"
        let bindSearch = Binding<String>(
            //display displayText for the user to see
            get: { self.displayText},
            //when setting bindSearch string, use this...
            set: {
                //set the displayText property to the inputted value
                self.displayText = $0
                //convert what the user entered into a char array
                var charArray = Array(self.displayText)
                var index = 0   //variable for holding the current iteration of the below for loop
                //iterate through all the chars in the array, replacing every " " with "-" for valid API calls
                for char in charArray{
                    if char == " "{
                        charArray[index] = "-"
                    }
                    index += 1
                }
                //set the searchText property (as the thing to be sent to the API) equal to the new modified string
                searchText = String(charArray)
                //call the gameSearch (API call) function with the selected current states
                gameSearch(searchText, showExact, platformAPISelect)
            }
        )
        
        let bindMetacritic = Binding<Bool>(
            get: {self.metacriticSortGreater},
            set: {
                self.metacriticSortGreater = $0
                gameSearch(searchText, showExact, platformAPISelect)
                sortByMetacritic()
            }
        )
        
        //custom binding for filtering out " " characters and replacing them with "-"
        let bindPlatform = Binding<String>(
            //display platformSelection (non-modded string) for the user to see
            get: { self.platformSelection},
            //when setting bindPlatform, use this...
            set: {
                //set the platformSelection property to the user input
                self.platformSelection = $0
                if platformSelection != "No selection"{
                    //convert what the user entered into a char array
                    var charArray = Array(self.platformSelection)
                    var index = 0   //variable for holding the current iteration of the below for loop
                    //iterate through all the chars in the array, replacing every " " with "-" for valid API calls
                    for char in charArray{
                        if char == " "{
                            charArray[index] = "-"
                        }
                        index += 1
                    }
                    //set the platformAPISelect property to equal the new modified string
                    platformAPISelect = String(charArray)
                    //call the gameSearch (API call) function with the selected current states
                }
                else{
                    platformAPISelect = String()
                }
                gameSearch(searchText, showExact, platformAPISelect)
            }
        )
        
        //custom binding for toggling the "Exact Search" filter
        let bindExact = Binding<Bool>(
            //set the bindExact value to equal showExact
            get: {self.showExact},
            //set showExact to equal the current boolean, and call the gameSearch (API call) function with the selected current states
            set: {self.showExact = $0; gameSearch(searchText, showExact, platformAPISelect)}
        )
        
        //SwiftUI body
        Form{
            Section(header: Text("Filters")){
                Toggle("Exact Search", isOn: bindExact)
                Picker("Platform", selection: bindPlatform, content: {
                    ForEach(platformNames, id: \.self){ platform in
                        Text(platform).tag(platform)
                    }
                })
                Picker("Metacritic Sorting", selection: bindMetacritic, content: {
                    Text("Higher").tag(true)
                    Text("Lower").tag(false)
                }
                )
            }
            HStack{
                Image(systemName: "magnifyingglass")
                    .padding(4)
                TextField("Search", text: bindSearch)
            }
            Section(header: Text("Results"), footer: ActivityIndicator(shouldAnimate: self.$showAnimation)){
                List(gameResults.results, id: \.id){ game in
                    GameResultRow(title: game.name, id: game.id, platformArray: game.platforms)
                }
            }
        }
        .navigationBarTitle("Add Game")
        .navigationBarItems(trailing: Button{
            showCamera.toggle()
        }
        label:{
            Image(systemName: "barcode.viewfinder")
        })
        .onAppear(perform: {
            print("Called")
            if platformNames.isEmpty{
                loadPlatformSelection()
            }
        })
        .sheet(isPresented: $showCamera, onDismiss: {
            do{
                if scanner?.upcString == nil{
                    throw BarcodeError.noBarcodeScanned
                }
                barcodeLookup(upcCode: (scanner?.upcString)!)
            }
            catch{
                print(error)
            }
        }){
            if !postCameraSuccessAlert{
                ViewControllerWrapper(scanner: $scanner)
                    .onAppear{
                        postCameraSuccessAlert = false
                    }
            }
        }
        .alert(isPresented: $postCameraSuccessAlert){
            Alert(title: Text("Game Found"), message: Text("Would you like to add \(barcodeResult) to your collection?"), primaryButton: Alert.Button.default(Text("Yes"), action: {
                loadBarcodeGameInfo()
                while barcodePlatforms.count == 0{
                    //do nothing. Stall the code until it's finished loading
                }
                gameObject.gameCollection.append(Game(title: barcodeResult, id: barcodeID, dateAdded: Date(), platforms: barcodePlatforms))
                VideoGameCollection.saveToFile(basicObject: gameObject)
                print("In barcode with count \(barcodePlatforms.count)")
                for platform in barcodePlatforms{
                    print(platform.platform.name)
                }
            }), secondaryButton: Alert.Button.cancel())
        }
    }
    
    //API note: use - character to subsitutue for space characters, as the API does not allow spaces in URLs (bad URL warnings will appear in the console if this is done)
    /**
     gameSearch: performs an API call to retrieve JSON data for games based on current search parameters
     parameters: searchTerm: string search term entered by the user, searchExact: boolean determining whether or not the search is exact, platformFilter: string used for filtering which platforms are being searched through
     */
    func gameSearch(_ searchTerm: String, _ searchExact: Bool, _ platformFilter: String){
        //create the basic URL
        var urlString = "https://api.rawg.io/api/games?key=\(rawgAPIKey)&search=\(searchTerm)&search_exact=\(searchExact)"
        if platformDict[platformSelection] != nil{
            urlString.append("&platforms=\(platformDict[platformSelection]!)")
        }
        //detect if the URL is valid
        guard let url = URL(string: urlString) else {
            print("Bad URL: \(urlString)")
            return
        }
        let session = URLSession.shared
        session.configuration.timeoutIntervalForRequest = 30.0
        session.configuration.timeoutIntervalForResource = 60.0
        //start our URLSession to get data
        session.dataTask(with: url) { data, response, error in
            showAnimation = true
            //data received
            if let data = data {
//                let str = String(decoding: data, as: UTF8.self)
//                print(str)
                //decode the data as a GameResults object
                let decoder = JSONDecoder()
                if let items = try? decoder.decode(GameResults.self, from: data){
                    //set our gameResults object (object that contains visible results to the user)
                    gameResults = items
                    showAnimation = false   //disable the animation
                    if !barcodeResult.isEmpty && items.count != 0{
                        barcodeResult = items.results[0].name
                        barcodeID = items.results[0].id
                        postCameraSuccessAlert.toggle()
                    }
                    //data parsing was successful, so return
                    return
                }
                
            }
        }.resume()  //call our URLSession
    }
    
    /**
     Load the details of a game based on it's ID from the API, decode the data, and update this views properites accordingly with that data
     parameters: none
     */
    func loadBarcodeGameInfo(){
        //create the basic URL
        let urlString = "https://api.rawg.io/api/games/\(String(barcodeID))?key=\(rawgAPIKey)"
        guard let url = URL(string: urlString) else {
            print("Bad URL: \(urlString)")
            return
        }
        print("Starting decoding...")
        //start our URLSession to get data
        let session = URLSession.shared
        session.configuration.timeoutIntervalForRequest = 30.0
        session.configuration.timeoutIntervalForResource = 60.0
        session.dataTask(with: url) { data, response, error in
            if let data = data {
//                let str = String(decoding: data, as: UTF8.self)
//                print(str)
                //decode the data as a PlatformSelection objecct
                let decoder = JSONDecoder()
                if let details = try? decoder.decode(GameDetails.self, from: data){
                    print("Successfully decoded")
                    //data parsing was successful, so return
                    barcodePlatforms = details.platforms
                    return
                }
            }
        }.resume()  //call our URLSession
    }
    
    /**
     loadPlatformSelection: function responsible for loading the current list of platforms the API supports, and displaying them to the user
     parameters: none
     */
    func loadPlatformSelection() {
        //create the basic URL
        let urlString = "https://api.rawg.io/api/platforms?key=\(rawgAPIKey)"
        guard let url = URL(string: urlString) else {
            print("Bad URL: \(urlString)")
            return
        }
        let session = URLSession.shared
        session.configuration.timeoutIntervalForRequest = 30.0
        session.configuration.timeoutIntervalForResource = 60.0
        //start our URLSession to get data
        session.dataTask(with: url) { data, response, error in
            if let data = data {
                //let str = String(decoding: data, as: UTF8.self)
                //print(str)
                //decode the data as a PlatformSelection objecct
                let decoder = JSONDecoder()
                if let items = try? decoder.decode(PlatformSelection.self, from: data){
                    //for every platform found, store it's name as a key and id as a value in platformDict
                    //for every platform found, store it's name as an item in the platformNames array (array responsible for displaying the actual list of platforms to the user
                    for platform in items.results {
                        print(platform)
                        platformDict[platform.name] = platform.id
                        platformNames.append(platform.name)
                    }
                    //sort the platform names to they come across to the user the same every time...regardless of what order the API delivers them in
                    platformNames.sort()
                    platformNames.insert("No selection", at: 0)
                    print("\n")
                    //data parsing was successful, so return
                    return
                }
                
            }
        }.resume()  //call our URLSession
    }
    
    func barcodeLookup(upcCode: String){
        //create the basic URL
        let urlString = "https://api.barcodelookup.com/v3/products?barcode=\(upcCode)&formatted=y&key=\(barcodeLookupAPIKey)"
        guard let url = URL(string: urlString) else {
            print("Bad URL: \(urlString)")
            return
        }
        let session = URLSession.shared
        session.configuration.timeoutIntervalForRequest = 30.0
        session.configuration.timeoutIntervalForResource = 60.0
        //start our URLSession to get data
        session.dataTask(with: url) { data, response, error in
            if let data = data {
                let str = String(decoding: data, as: UTF8.self)
                print(str)
                let decoder = JSONDecoder()
                if let results = try? decoder.decode(BarcodeResults.self, from: data){
                    print(results.products[0].title)
                    var charArray = Array(results.products[0].title)
                    var index = 0   //variable for holding the current iteration of the below for loop
                    //iterate through all the chars in the array, replacing every " " with "-" for valid API calls
                    for char in charArray{
                        if char == " "{
                            charArray[index] = "-"
                        }
                        index += 1
                    }
                    barcodeResult = results.products[0].title
                    gameSearch(String(charArray), showExact, platformAPISelect)
                }
            }
        }.resume()  //call our URLSession
    }
    func sortByMetacritic(){
        if metacriticSortGreater{
            gameResults.results.sort(by: {$0.metacritic > $1.metacritic})
        }
        else{
            gameResults.results.sort(by: {$0.metacritic < $1.metacritic})
        }
    }
}

//Preview struct
struct AddGameView_Previews: PreviewProvider {
    static var previews: some View {
        AddGameView()
    }
}
