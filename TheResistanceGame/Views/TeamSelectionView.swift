//
//  TeamSelectionView.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/23/24.
//

import SwiftUI

struct TeamSelectionView: View {
    @EnvironmentObject var gameService: GameService
    @State private var selectedPlayers: Set<UUID> = []
    @Environment(\.presentationMode) var presentationMode // Add this line

    
    var missionId: String

    var body: some View {
        VStack {
            Text("Select Team for Mission")
                .font(Font.custom("Jockey One", size: 30))
                .foregroundStyle(Color.white)
                .padding()

            let mission = gameService.gameState.missions.first { $0.id == missionId }
            let numberOfAgents = mission != nil ? gameService.getMissionAgentCounts(for: gameService.gameState.players.count)[Int(mission!.id.replacingOccurrences(of: "mission", with: ""))! - 1] : 0


            ScrollView {
                HStack(alignment: .top) {
                    VStack(spacing: 20) {
                        ForEach(gameService.gameState.players.prefix(5)) { player in
                            PlayerSelectionRow(player: player, isSelected: selectedPlayers.contains(player.id)) {
                                toggleSelection(for: player.id, maxSelection: numberOfAgents)
                            }
                        }
                    }
                    VStack(spacing: 20) {
                        ForEach(gameService.gameState.players.suffix(from: 5)) { player in
                            PlayerSelectionRow(player: player, isSelected: selectedPlayers.contains(player.id)) {
                                toggleSelection(for: player.id, maxSelection: numberOfAgents)
                            }
                        }
                    }
                }
                .padding()
            }
            
            Button(action: {
                // Submit selected team to Firebase
                if selectedPlayers.count == numberOfAgents {
                    submitTeam()
                } else {
                    print("Select exactly \(numberOfAgents) players.")
                }
            }) {
                Text("Submit Team")
                    .font(Font.custom("Jockey One", size: 30))
                    .foregroundColor(.white)
                    .padding()
                    .background(selectedPlayers.count == numberOfAgents ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(selectedPlayers.count != numberOfAgents)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.08, green: 0.16, blue: 0.22))

    }

    private func submitTeam() {
        guard let missionIndex = gameService.gameState.missions.firstIndex(where: { $0.id == missionId }) else { return }
        
        // Create the missionAgents dictionary
        let missionAgents = selectedPlayers.reduce(into: [UUID: GameState.MissionVote]()) { result, playerId in
            result[playerId] = .notVoted
        }
        
        gameService.gameState.missions[missionIndex].missionAgents = missionAgents
        gameService.updateMissionAgents(missionId: missionId, agents: Array(selectedPlayers))
//        print("Submitted team: \(selectedPlayers)")
        
        gameService.updateGamePhase(to: .teamVoting)
        
        // Automatically go back to the previous view
        presentationMode.wrappedValue.dismiss()
    }
    
    private func toggleSelection(for playerId: UUID, maxSelection: Int) {
        if selectedPlayers.contains(playerId) {
            selectedPlayers.remove(playerId)
        } else {
            if selectedPlayers.count < maxSelection {
                selectedPlayers.insert(playerId)
            }
        }
    }
}


struct PlayerSelectionRow: View {
    var player: Player
    var isSelected: Bool
    var onSelect: () -> Void

    var body: some View {
        HStack {
            Text(player.name)
                .font(Font.custom("Menlo", size: 20))
                .foregroundColor(isSelected ? .green : .black)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .onTapGesture {
            onSelect()
        }
    }
}

struct TeamSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let gameService = GameService()
        let currentPlayerId = UUID()

        let dummyGameState = GameState(
            id: "dummy_game_id",
            players: [
                Player(id: currentPlayerId, name: "Player 1", role: .resistance, isLeader: true, isHost: true, votedOnLeader: true),
                Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false, votedOnLeader: true),
                Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false, votedOnLeader: true),
                Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false, votedOnLeader: true),
                Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false, votedOnLeader: true),
//                Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false),
//                Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false),
//                Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false),
//                Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false),
//                Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false)
            ],
            currentPhase: .missionInProgress,
            currentLeaderIndex: 0,
            missions: [
                GameState.Mission(id: "mission1", leader: currentPlayerId, status: .inProgress, missionAgents: [currentPlayerId: .notVoted,  UUID(): .notVoted], votes: [:], leaderApprove: .undecided),
                GameState.Mission(id: "mission2", leader: UUID(),status: .notStarted, missionAgents: [UUID(): .notVoted, UUID(): .notVoted], votes: [:], leaderApprove: .undecided),
                GameState.Mission(id:"mission3", leader: UUID(),status: .notStarted, missionAgents: [UUID(): .notVoted, UUID(): .notVoted, UUID(): .notVoted], votes: [:], leaderApprove: .undecided),
                GameState.Mission(id: "mission4", leader: UUID(),status: .notStarted, missionAgents: [UUID(): .notVoted, UUID(): .notVoted], votes: [:], leaderApprove: .undecided),
                GameState.Mission(id: "mission5", leader: UUID(),status: .notStarted, missionAgents: [UUID(): .notVoted, UUID(): .notVoted], votes: [:], leaderApprove: .undecided)
            ]

        )
        
        gameService.gameState = dummyGameState
        gameService.currentPlayer.isLeader = false

        return TeamSelectionView(missionId: "mission4")
            .environmentObject(gameService)
    }
}
