//
//  MainGameView.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/22/24.
//

import SwiftUI

struct MainGameView: View {
    @EnvironmentObject var gameService: GameService
    @State private var borderColor = Color.clear
    @State private var leaderMessage = "Leader:"
    @State private var showRoleRevealSheet = false
    @State private var sortedMissions: [GameState.Mission] = []
    
    
    var body: some View {
        
        let currentMissionIndex = gameService.gameState.missions.firstIndex(where: { $0.status == .inProgress }) ?? 0
   
        NavigationStack {
            VStack(spacing: 10) {
                MissionDashboard()
                    .padding(.bottom, 10)
                
                CurrentLeaderBox(
                    currentLeader: gameService.gameState.players[gameService.gameState.currentLeaderIndex].name,
                    message: leaderMessage,
                    borderColor: borderColor
                )
                .padding(.bottom)
                
                
                VStack {
                    ForEach(sortedMissions) { mission in
                        let missionLeaderName = gameService.gameState.players.first { $0.id == mission.leader }?.name ?? "Unknown"
//                        NavigationLink(=
//                            destination: SpyRevealView()
//                        ) {
//                            MissionDetailView(
//                                missionLeader: missionLeaderName,
//                                missionStatus: mission.status,
//                                missionID: mission.id,
//                                onNavigate: {}
//                            )
//                        }
                        NavigationLink(
//                            destination: MockMissionDetailView(missionID: mission.id)
                            destination: MoreMissionDetailView(mission: mission)
                        ) {
//                            Text("Go to \(mission.id)")
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
                            MissionDetailView(
                                missionLeader: missionLeaderName,
                                missionStatus: mission.status,
                                missionID: mission.id
                            )
                        }
                        .disabled(mission.status == .notStarted) // Disable if mission is not started
  
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.08, green: 0.16, blue: 0.22))
            .onChange(of: gameService.gameState.missions[currentMissionIndex].leaderApprove) { oldValue, newValue in
                handleVoteResult(status: newValue)
            }
            .onAppear {
                if gameService.wasRoleRevealed == false {
                    showRoleRevealSheet = true
                }
                // Update sortedMissions whenever the view appears
                sortedMissions = gameService.gameState.missions.sorted { mission1, mission2 in
                    let index1 = Int(mission1.id.replacingOccurrences(of: "mission", with: ""))!
                    let index2 = Int(mission2.id.replacingOccurrences(of: "mission", with: ""))!
                    return index1 < index2
                }
            }
            .sheet(isPresented: $showRoleRevealSheet) {
               if gameService.currentPlayer.role == .spy {
                   SpyRevealView()
               } else if gameService.currentPlayer.role == .resistance {
                   ResistanceRevealView()
               }
           }
   
        }
    }
//    private var sortedMissions: [GameState.Mission] {
//        gameService.gameState.missions.sorted { mission1, mission2 in
//            let index1 = Int(mission1.id.replacingOccurrences(of: "mission", with: ""))!
//            let index2 = Int(mission2.id.replacingOccurrences(of: "mission", with: ""))!
//            return index1 < index2
//        }
//    }
//  
    
    private func handleVoteResult(status: GameState.LeaderApproveStatus) {
        switch status {
            
        case .undecided:
            leaderMessage = "Leader:"
            borderColor = .clear
        case .approved:
            leaderMessage = "Leader:"
            borderColor = .clear
        case .rejected:
            leaderMessage = "Mission was not approved."
            borderColor = .red

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                borderColor = .clear
                gameService.advanceLeader()
            }
        }
    }
}


//#Preview {
//    MainGameView()
//        .environmentObject(GameService())
//}

struct MainGameView_Previews: PreviewProvider {
    static var previews: some View {
        let gameService = GameService()
        let currentPlayerId = UUID()

        let dummyGameState = GameState(
            id: "dummy_game_id",
            players: [
                Player(id: currentPlayerId, name: " Melanie", role: .resistance, isLeader: true, isHost: true, votedOnLeader: true),
                Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false, votedOnLeader: false),
                Player(id: UUID(), name: "Player 3", role: .spy, isLeader: false, isHost: false, votedOnLeader: false),
                Player(id: UUID(), name: "Player 4", role: .spy, isLeader: false, isHost: false, votedOnLeader: false),
                Player(id: UUID(), name: "Player 5", role: .spy, isLeader: false, isHost: false, votedOnLeader: false),
                Player(id: UUID(), name: "Player 6", role: .spy, isLeader: false, isHost: false, votedOnLeader: false)
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
//        gameService.currentPlayer.id = currentPlayerId

        return MainGameView()
            .environmentObject(gameService)
    }
}


