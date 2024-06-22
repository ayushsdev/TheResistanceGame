//
//  TheResistanceGameApp.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/21/24.
//

import SwiftUI
import SwiftData
import Firebase

@main
struct TheResistanceGameApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
//    @StateObject var gameState = GameState(id: "123")
    @StateObject var gameService = GameService()
    @StateObject var navigationView = NavigationViewModel()
    init () {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
//                .environmentObject(gameState)
                .environmentObject(gameService)
                .environmentObject(navigationView)
        }
        .modelContainer(sharedModelContainer)
    }
}
