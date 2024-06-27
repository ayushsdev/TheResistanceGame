//
//  MoreMissionDetailView.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/22/24.
//

import SwiftUI

struct MoreMissionDetailView: View {
    @EnvironmentObject var gameService: GameService
    var mission: GameState.Mission
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("On This Mission")
                .font(Font.custom("Jockey One", size: 28))
                .underline()
                .foregroundStyle(Color.black)
            
            HStack {
                VStack {
                    ForEach(mission.missionAgents.keys.enumerated().filter { $0.offset % 2 == 0 && $0.offset / 2 < 3 }, id: \.element) { _, agentId in
                        if let player = gameService.gameState.players.first(where: { $0.id == agentId }) {
                            Text(player.name)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .font(Font.custom("Dangrek", size: 28))
                                .foregroundStyle(Color(red: 0.08, green: 0.16, blue: 0.22))
                        }
                    }
                }
                VStack {
                    ForEach(mission.missionAgents.keys.enumerated().filter { $0.offset % 2 != 0 && $0.offset / 2 < 3 }, id: \.element) { _, agentId in
                        if let player = gameService.gameState.players.first(where: { $0.id == agentId }) {
                            Text(player.name)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .font(Font.custom("Dangrek", size: 28))
                                .foregroundStyle(Color(red: 0.08, green: 0.16, blue: 0.22))
                        }
                    }
                }

           }
            
            HStack {
                VStack(alignment: .center, spacing: 20) {
                    Text("Approved")
                        .font(Font.custom("Jockey One", size: 28))
                        .foregroundColor(.green)
                        .padding(.bottom, 10)
                    
                    ForEach(mission.votes.filter { $0.value == .approve }.map { $0.key }, id: \.self) { playerId in
                        if let player = gameService.gameState.players.first(where: { $0.id == playerId }) {
                            Text(player.name)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .font(Font.custom("Menlo", size: 20))
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
                .padding()

                
                VStack(alignment: .center, spacing: 20) {
                    Text("Rejected")
                        .font(Font.custom("Jockey One", size: 28))
                        .foregroundColor(.red)
                        .padding(.bottom, 10)
                    
                    ForEach(mission.votes.filter { $0.value == .reject }.map { $0.key }, id: \.self) { playerId in
                        if let player = gameService.gameState.players.first(where: { $0.id == playerId }) {
                            Text(player.name)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .font(Font.custom("Menlo", size: 20))
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .frame(width: 368, height: 509)
            .background(Color(red: 0.08, green: 0.16, blue: 0.22))
            .cornerRadius(10)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.85, green: 0.85, blue: 0.85))

    }
}

struct MoreMissionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyPlayers = [
            Player(id: UUID(), name: "Player 1", role: .resistance, isLeader: true, isHost: true, votedOnLeader: true),
            Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false, votedOnLeader: true),
            Player(id: UUID(), name: "Player 3", role: .resistance, isLeader: false, isHost: false, votedOnLeader: true),
            Player(id: UUID(), name: "Player 4", role: .spy, isLeader: false, isHost: false, votedOnLeader: true),
            Player(id: UUID(), name: "Player 5", role: .resistance, isLeader: false, isHost: false, votedOnLeader: true),
            Player(id: UUID(), name: "Player 6", role: .spy, isLeader: false, isHost: false, votedOnLeader: true)
        ]
        
        let missionAgents: [UUID: GameState.MissionVote] = dummyPlayers.reduce(into: [UUID: GameState.MissionVote]()) { result, player in
            result[player.id] = .notVoted
        }

        let dummyMission = GameState.Mission(
            id: "mission1",
            leader: UUID(),
            status: .inProgress,
            missionAgents: missionAgents,
            votes: [
                dummyPlayers[0].id: .approve,
                dummyPlayers[1].id: .approve,
                dummyPlayers[2].id: .reject,
                dummyPlayers[3].id: .approve,
                dummyPlayers[4].id: .approve,
                dummyPlayers[5].id: .notVoted
            ],
            leaderApprove: .undecided
        )

        let gameService = GameService()
        gameService.gameState = GameState(
            id: "dummy_game_id",
            players: dummyPlayers,
            currentPhase: .setup,
            currentLeaderIndex: 0,
            missions: [dummyMission]
        )
        gameService.currentPlayer = dummyPlayers.first!

        return MoreMissionDetailView(mission: dummyMission)
            .environmentObject(gameService)
            .background(Color.black) // To visualize the white text better
//            .previewLayout(.sizeThatFits)
    }
}
