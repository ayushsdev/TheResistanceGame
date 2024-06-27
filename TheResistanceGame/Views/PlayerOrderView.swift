//
//  PlayerOrderView.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/27/24.
//

import SwiftUI

struct PlayerOrderView: View {
    @EnvironmentObject var gameService: GameService
    var body: some View {
        VStack {
            Text("Player Order")
              .font(Font.custom("Jockey One", size: 48))
              .foregroundStyle(Color.white)
                        
            ForEach(gameService.gameState.playerOrder.keys.sorted(), id: \.self) { index in
                if let playerId = gameService.gameState.playerOrder[index],
                   let player = gameService.gameState.players.first(where: { $0.id == playerId }) {
                    Text(player.name)
                        .font(Font.custom("Jockey One", size: 32))
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 5)
                }
            }

        }
        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
        .background(Color(red: 0.08, green: 0.16, blue: 0.22))

    }
}

struct PlayerOrderView_Previews: PreviewProvider {
    static var previews: some View {
        let gameService = GameService()
        
        // Mock players
        let dummyPlayers = [
            Player(id: UUID(), name: "Player 1", role: .resistance, isLeader: false, isHost: true, votedOnLeader: false),
            Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false, votedOnLeader: false),
            Player(id: UUID(), name: "Player 3", role: .resistance, isLeader: false, isHost: false, votedOnLeader: false),
            Player(id: UUID(), name: "Player 4", role: .spy, isLeader: false, isHost: false, votedOnLeader: false),
            Player(id: UUID(), name: "Player 5", role: .resistance, isLeader: true, isHost: false, votedOnLeader: false),
            Player(id: UUID(), name: "Player 1", role: .resistance, isLeader: false, isHost: true, votedOnLeader: false),
            Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false, votedOnLeader: false),
            Player(id: UUID(), name: "Player 3", role: .resistance, isLeader: false, isHost: false, votedOnLeader: false),
            Player(id: UUID(), name: "Player 4", role: .spy, isLeader: false, isHost: false, votedOnLeader: false),
            Player(id: UUID(), name: "Player 5", role: .resistance, isLeader: true, isHost: false, votedOnLeader: false)
        ]
        
        // Mock player order
        gameService.gameState = GameState(
            id: "example_game_id",
            players: dummyPlayers,
            currentPhase: .setup,
            currentLeaderIndex: 0,
            missions: [],
            playerOrder: [
                0: dummyPlayers[0].id,
                1: dummyPlayers[1].id,
                2: dummyPlayers[2].id,
                3: dummyPlayers[3].id,
                4: dummyPlayers[4].id,
                5: dummyPlayers[5].id,
                6: dummyPlayers[6].id,
                7: dummyPlayers[7].id,
                8: dummyPlayers[8].id,
                9: dummyPlayers[9].id
            ]
        )
        
        return PlayerOrderView()
            .environmentObject(gameService)
            .previewLayout(.sizeThatFits)
    }
}
