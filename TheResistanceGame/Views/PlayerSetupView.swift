//
//  PlayerSetupView.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/21/24.
//

import SwiftUI
struct PlayerSetupView: View {
//    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var gameService: GameService
    @EnvironmentObject var navigationView: NavigationViewModel
    @State var StartState: StartModeState = .host
    @State private var playerName: String = ""
    @State var joinCode: String = ""
    
    var body: some View {
        VStack (spacing: 0) {
            Spacer()
            
            //Join or Host area
            HStack (spacing: 1.5){
                Button {
                    StartState = .host
                } label: {
                    HostOrJoinLabel(text: "Host", StartState: $StartState)
                }
                
                Button {
                    StartState = .join
                } label: {
                    HostOrJoinLabel(text: "Join", StartState: $StartState)
                }

            }
            .frame(width: 250, height: 61)
            
            //NameAndCodeBox
            VStack (spacing: 0) {
                CustomTextBox(textInput: $playerName, placeholder: "Name" )
                    .padding(.top, 45)
                if StartState == .join {
                    CustomTextBox(textInput: $joinCode, placeholder: "Join Code")
                        .padding(.top, 20)
                }
                
                Button {
                    if StartState == .host {
//                        hostGame()
                        hostNewGame()
                    } else {
//                        joinGame()
                        joinExistingGame()
                    }
                } label: {
                    Text("Join the Game!")
                        .font(Font.custom("Menlo", size: 16).weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 207, height: 47)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                        .cornerRadius(8)
                        .padding(.top, 50)
                }
                .disabled(!isFormValid)
                
                Spacer()

            }
            .frame(width: 246.5, height: 255)
            .background(
                Color(.white)
                    .opacity(0.04)
            )
            .clipShape(
                UnevenRoundedRectangle(cornerRadii:.init(
                    topLeading: 0.0,
                    bottomLeading: 10.0,
                    bottomTrailing: 10.0,
                    topTrailing: 0.0))
            )

            .overlay(
                UnevenRoundedRectangle(cornerRadii:.init(
                    topLeading: 0.0,
                    bottomLeading: 10.0,
                    bottomTrailing: 10.0,
                    topTrailing: 0.0))
                .stroke(
                    Color(.white).opacity(0.29)
                )
            )
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // Ensure the VStack fills the entire screen
        .background(
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.19, green: 0, blue: 0.57), Color(red: 0.57, green: 0.00, blue: 0.19)]), startPoint: .leading, endPoint: .trailing)
        )
    }
    
    private var isFormValid: Bool {
        if StartState == .host {
            return !playerName.isEmpty
        } else {
            return !playerName.isEmpty && !joinCode.isEmpty
        }
    }
    
    private func hostNewGame() {
        gameService.hostGame(playerName: playerName) { result in
            switch result {
            case .success():
//                print("Game Hosted Successfully")
//                print(gameService.gameState.players)
                navigationView.currentView = .waitingLobby
            case .failure(let error):
                print("Failed to host game: \(error.localizedDescription)")
            }
        }
    }
    
    private func joinExistingGame() {
        gameService.joinGame(gameId: joinCode, playerName: playerName) { result in
            switch result {
            case .success(let playerId):
                navigationView.currentView = .waitingLobby
                
            case .failure(let error):
                print("Failed to join game: \(error.localizedDescription)")
            }
        }
    }
}

enum StartModeState {
    case join
    case host
}

#Preview {
    PlayerSetupView()
}
