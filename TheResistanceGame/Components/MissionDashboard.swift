//
//  MissionDashboard.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/22/24.
//

import SwiftUI

struct MissionDashboard: View {
    
    @State private var hasVoted = false
    @State private var showMissionVotingSheet = false
    @State private var missionResultSelected = false
    @State private var missionId: String = ""
    @State private var missionAgents: [Player] = []
    
    
    @EnvironmentObject var gameService: GameService
    
    var body: some View {
        
        let playerCount = gameService.gameState.players.count
        let missionCounts = gameService.getMissionAgentCounts(for: playerCount)

        
        VStack (spacing: 0) {
            if gameService.gameState.currentPhase == .teamVoting {
                Text("Agents Going on the Mission")
                    .font(Font.custom("ConcertOne", size: 20))
                    .foregroundStyle(Color.black)
                    .padding()

                
                if let currentMission = gameService.gameState.missions.first(where: { $0.status == .inProgress }) {
                    let agents = currentMission.missionAgents.keys.compactMap { agentId in
                        gameService.gameState.players.first(where: { $0.id == agentId })
                    }
                    
                    HStack (spacing: 60){
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(agents.prefix(3), id: \.id) { agent in
                                Text(agent.name)
                                    .font(Font.custom("Itim", size: 18))
                                    .foregroundStyle(Color.black)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(5)
//                                    .padding(./*horizontal*/)
                            }
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(agents.dropFirst(3), id: \.id) { agent in
                                Text(agent.name)
                                    .font(Font.custom("Itim", size: 18))
                                    .foregroundStyle(Color.black)
//                                    .padding(3)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(5)
//                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            else {
                HStack(spacing: 0) {
                    ForEach(gameService.gameState.missions.sorted(by: { mission1, mission2 in
                        let index1 = Int(mission1.id.replacingOccurrences(of: "mission", with: ""))!
                        let index2 = Int(mission2.id.replacingOccurrences(of: "mission", with: ""))!
//                        print("Mission circle")
                        return index1 < index2
                    }), id: \.id) { mission in
                        if let missionIndex = Int(mission.id.replacingOccurrences(of: "mission", with: "")),
                           missionIndex > 0 && missionIndex <= missionCounts.count {
                            let numberOfAgents = missionCounts[missionIndex - 1]
                            MissionCircle(numberOfPeople: numberOfAgents, status: mission.status)
                                .padding(3)
                        }
                    }
                }
                .padding(.top, 20)
            }
            
            
            if gameService.gameState.currentPhase == .missionInProgress {
                if let currentMission = gameService.gameState.missions.first(where: { $0.status == .inProgress }),
                   (currentMission.missionAgents.keys.contains(gameService.currentPlayer.id) &&  !missionResultSelected){
                    Button {
                        showMissionVotingSheet = true
                    } label: {
                        Text("Go on the Mission")
                            .foregroundStyle(Color.white)
                            .frame(width: 227, height: 41)
                            .background(Color(red: 0.09, green: 0.06, blue: 0.06))
                            .cornerRadius(7)
                            .shadow(
                                color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4, y: 4
                            )
                    }
          
                    .padding(.top, 30)
                    
                } else {
                    Text("Mission in Progress")
                        .font(Font.custom("Itim", size: 28))
                        .foregroundStyle(Color.black)
                        .padding(.top, 30)
                }
            }
            
            if (gameService.gameState.currentPhase == .teamProposal) &&
                (gameService.currentPlayer.isLeader == true)
            {
                NavigationLink {
                    TeamSelectionView(missionId: gameService.gameState.missions.first { $0.status == .inProgress }?.id ?? "")
                } label: {
                    Text("Propose Team")
                        .foregroundStyle(Color.white)
                        .frame(width: 227, height: 41)
                        .background(Color(red: 0.09, green: 0.06, blue: 0.06))
                        .cornerRadius(7)
                        .shadow(
                            color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4, y: 4
                        )
                }
                .padding(.top, 30)
                
            } else if (gameService.gameState.currentPhase == .teamProposal &&
                       gameService.currentPlayer.isLeader == false) {
                Text("Leader is proposing the team")
                    .font(Font.custom("Itim", size: 25))
                    .foregroundStyle(Color.black)
                    .padding(.top, 20)
            } else if (gameService.gameState.currentPhase == .teamVoting) {
                
                if gameService.currentPlayer.votedOnLeader {
                    Text("Waiting for other players to Vote")
                        .font(Font.custom("Itim", size: 20))
                        .foregroundColor(Color.black)
                        .padding()
                } else {
                    HStack {
                        Button {
                            gameService.voteOnTeam(status: .approve)
                            gameService.updateVotedOnLeader(for: gameService.currentPlayer.id, voted: true)

                        } label: {
                            Text("Approve")
                                .font(Font.custom("Itim", size: 20))
                                .foregroundStyle(Color(red: 0.85, green: 0.85, blue: 0.85))
                                .frame(width: 163, height: 41)
                                .background(Color(red: 0.06, green: 0.29, blue: 0.06))
                                .cornerRadius(7)
                                .shadow(
                                    color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4, y: 4
                                )
                        }
                        
                        Button {
                            gameService.voteOnTeam(status: .reject)
                            gameService.updateVotedOnLeader(for: gameService.currentPlayer.id, voted: true)
                        } label: {
                            Text("Reject")
                                .font(Font.custom("Itim", size: 20))
                                .foregroundStyle(Color(red: 0.85, green: 0.85, blue: 0.85))
                                .frame(width: 163, height: 41)
                                .background(Color(red: 0.58, green: 0.05, blue: 0.05))
                                .cornerRadius(7)
                                .shadow(
                                    color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4, y: 4
                                )
                        }
                    }
                    .padding(.top, 20)
                }
            }
            
            Spacer()
        }
//        .onAppear {
//            if let currentMission = gameService.gameState.missions.first(where: { $0.status == .inProgress }) {
//                self.missionId = currentMission.id
//                self.missionAgents = currentMission.missionAgents.compactMap { agentId, _ in
//                    gameService.gameState.players.first(where: { $0.id == agentId })
//                }
//            }
//        }
        
        .frame(width: 368, height: 220)
        .background(Color(red: 0.85, green: 0.85, blue: 0.85))
        .cornerRadius(10)
        .sheet(isPresented: $showMissionVotingSheet) {
            MissionVotingView(missionResultSelected: $missionResultSelected)
        }
        .onChange(of: gameService.gameState.currentPhase) { oldValue, newValue in
            if oldValue == .missionInProgress {
                missionResultSelected = false
            }
        }
    }
}

struct MissionDashboard_Previews: PreviewProvider {
    static var previews: some View {
        let gameService = GameService()
        let currentPlayerId = gameService.currentPlayer.id
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
                GameState.Mission(id: "mission1", leader: currentPlayerId, status: .inProgress, missionAgents: [currentPlayerId: .notVoted,  UUID(): .notVoted], votes: [:], leaderApprove: .approved),
                GameState.Mission(id: "mission2", leader: UUID(),status: .notStarted, missionAgents: [UUID(): .notVoted, UUID(): .notVoted], votes: [:], leaderApprove: .undecided),
                GameState.Mission(id:"mission3", leader: UUID(),status: .notStarted, missionAgents: [UUID(): .notVoted, UUID(): .notVoted, UUID(): .notVoted], votes: [:], leaderApprove: .undecided),
                GameState.Mission(id: "mission4", leader: UUID(),status: .notStarted, missionAgents: [UUID(): .notVoted, UUID(): .notVoted], votes: [:], leaderApprove: .undecided),
                GameState.Mission(id: "mission5", leader: UUID(),status: .notStarted, missionAgents: [UUID(): .notVoted, UUID(): .notVoted], votes: [:], leaderApprove: .undecided)
            ]
        )
        
        gameService.gameState = dummyGameState

        gameService.currentPlayer.isLeader = true
//        gameService.currentPlayer.id = currentPlayerId

        return MissionDashboard()
            .environmentObject(gameService)
    }
}
