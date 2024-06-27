//
//  ContentView.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/21/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
//    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var gameService: GameService
    @EnvironmentObject var navigationView: NavigationViewModel
    
    
    var body: some View {
        NavigationStack {
            VStack {
                switch self.navigationView.currentView {
                case .hostOrJoin:
                    PlayerSetupView()
                case .waitingLobby:
                    WaitingLobbyView()
//                case .spyReveal:
//                    SpyRevealView()
//                case .resistanceReveal:
//                    ResistanceRevealView()
                case .mainGame:
                    MainGameView()
                case .gameEnd:
                    gameEnd()
                }
            }
            .onChange(of: gameService.gameState.currentPhase) { oldPhase, newPhase in
                gameService.updateNavigation(navigationViewModel: navigationView)
            }
        }
    }
}

//#Preview {
//    ContentView()
//}
