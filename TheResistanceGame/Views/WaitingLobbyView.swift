//
//  WaitingLobbyView.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/21/24.
//

import SwiftUI

struct WaitingLobbyView: View {
    @EnvironmentObject var gameService: GameService
    
    private var isHost: Bool {
        return gameService.currentPlayer?.isHost ?? false
    }
    
    var body: some View {
        
        VStack (spacing: 0) {
            Text("Players In The Game")
              .font(Font.custom("Pacifico", size: 32))
              .foregroundColor(.white)
              .padding(.top, 60)
            
            Text("Join Code: \(gameService.gameState.id)")
                .font(Font.custom("ConcertOne", size: 24))
                .padding(.top, 20)
            
            Text("\(gameService.gameState.players.count)")
                .font(Font.custom("Pacifico", size: 48))
                .foregroundStyle(Color(.white))
                .frame(width: 100, height: 100)
                .background(Color(red: 0.05, green: 0.03, blue: 0.03))
                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                .padding(.top, 40)
            
            HStack {
                VStack(alignment: .center, spacing: 20) {
                    // Players with even indices
                    ForEach(gameService.gameState.players.indices.filter { $0 % 2 == 0 }, id: \.self) { index in
                        Text(gameService.gameState.players[index].name)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(Font.custom("Menlo", size: 20))
                            .foregroundStyle(Color(.white))
                    }
                }
                VStack(alignment: .center, spacing: 20) {
                    // Players with odd indices
                    ForEach(gameService.gameState.players.indices.filter { $0 % 2 != 0 }, id: \.self) { index in
                        Text(gameService.gameState.players[index].name)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(Font.custom("Menlo", size: 20))
                            .foregroundStyle(Color(.white))

                    }
                }
            }
            .frame(width: 361, height: 278)
            .background(Color(red: 0.85, green: 0.85, blue: 0.85).opacity(0.20))
            .cornerRadius(20)
            .padding(.top, 35)
            
            if isHost == true {
                Button(action: {
                    startGame()
                }, label: {
                    Text("Start The Game!")
                        .frame(width: 227, height: 48)
                        .font(Font.custom("Knewave", size: 20))
                        .foregroundStyle(Color(.white))
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 0.55, green: 0, blue: 0), Color(red: 0.62, green: 0.20, blue: 0.02)]), startPoint: .leading, endPoint: .trailing)
                          )
                          .cornerRadius(10)
                          .shadow(
                            color: Color(red: 0, green: 0, blue: 0, opacity: 0.50), radius: 4, y: 4
                          )
                })
                .padding(.top, 40)
            } else {
                Text("Waiting for Host To Start...")
                  .font(Font.custom("Pacifico", size: 20))
                  .foregroundStyle(Color(.white))
                  .padding(.top, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color(red: 0, green: 0.59, blue: 0.78), Color(red: 0, green: 0.15, blue: 0.43)]), startPoint: .top, endPoint: .bottom)
        )
    }
    
    private func startGame() {
        gameService.assignRoles()
    }
}

struct WaitingLobbyView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingLobbyView().environmentObject(GameService())
    }
}
