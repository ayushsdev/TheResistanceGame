//
//  MissionVotingView.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/23/24.
//

import SwiftUI


struct MissionVotingView: View {
    @EnvironmentObject var gameService: GameService
    @Environment(\.dismiss) var dismiss

    @State private var showMessage = false
    @State private var message = ""
    @State private var missionId: String = ""
    @State private var missionAgents: [Player] = []
    @Binding var missionResultSelected: Bool


    var body: some View {
        VStack {
            Text("Mission Voting")
                .font(Font.custom("Itim", size: 40))
                .foregroundStyle(Color.white)
                .padding(.top, 30)

            VStack {
                ForEach(missionAgents, id: \.id) { agent in
                    Text(agent.name)
                        .font(Font.custom("Itim", size: 25))
                        .foregroundStyle(Color.white)
                        .padding(3)
//                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                        .padding(.horizontal)
                }
            }
            Spacer()
            VStack (spacing: 20) {
                Button(action: {
                    missionResultSelected = true
                    dismiss()
                    gameService.voteOnMission(missionId: missionId, vote: .success) { result in
                       switch result {
                       case .success:
                           print("Vote recorded successfully.")
                           
                       case .failure(let error):
                           print("Failed to record vote: \(error.localizedDescription)")
                       }
                   }
                }) {
                    Text("Success")
                        .font(Font.custom("Itim", size: 40))
                        .foregroundStyle(Color.white)
                        .frame(width: 286, height: 110)
                        .background(Color(red: 0.06, green: 0.50, blue: 0.29))
                        .cornerRadius(7)
                        .shadow(color: Color.black.opacity(0.25), radius: 4, y: 4)
                        .padding(.bottom, 70)
                }

                Button(action: {
                    missionResultSelected = false
                    dismiss()

                    gameService.voteOnMission(missionId: missionId, vote: .fail) { result in
                        switch result {
                        case .success:
                            print("Vote recorded successfully.")
                        case .failure(let error):
                            print("Failed to record vote: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Fail")
                        .font(Font.custom("Itim", size: 40))
                        .foregroundStyle(Color.white)
                        .frame(width: 286, height: 110)
                        .background(Color(red: 0.50, green: 0.06, blue: 0.11))
                        .cornerRadius(7)
                        .shadow(color: Color.black.opacity(0.25), radius: 4, y: 4)
                }
            }
            .padding(.bottom, 50)

            if showMessage {
                Text(message)
                    .font(.body)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                    .padding(.horizontal)
            }
        }
        .onAppear {
            if let currentMission = gameService.gameState.missions.first(where: { $0.status == .inProgress }) {
                self.missionId = currentMission.id
                self.missionAgents = currentMission.missionAgents.compactMap { agentId, _ in
                    gameService.gameState.players.first(where: { $0.id == agentId })
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.01, green: 0.05, blue: 0.10))
        .interactiveDismissDisabled()

    }

    private func handleVoteResult(result: Result<Void, Error>) {
        switch result {
        case .success:
            message = "Vote recorded successfully."
        case .failure(let error):
            message = "Failed to record vote: \(error.localizedDescription)"
        }
        showMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showMessage = false
        }
    }
}


struct MissionVotingView_Previews: PreviewProvider {
    static var previews: some View {
        let gameService = GameService()
        
        let dummyPlayers = [
            Player(id: UUID(), name: "Player 1", role: .resistance, isLeader: true, isHost: true, votedOnLeader: true),
            Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false, votedOnLeader: true),
            Player(id: UUID(), name: "Player 3", role: .resistance, isLeader: false, isHost: false, votedOnLeader: true)
        ]
        
        let dummyMission = GameState.Mission(
            id: "mission1",
            leader: dummyPlayers[0].id,
            status: .inProgress,
            missionAgents: [dummyPlayers[0].id: .notVoted, dummyPlayers[1].id: .notVoted],
            votes: [:], 
            leaderApprove: .approved
        )
        
        gameService.gameState = GameState(
            id: "example_game_id",
            players: dummyPlayers,
            currentPhase: .teamVoting,
            currentLeaderIndex: 0,
            missions: [dummyMission]
        )
        
        return MissionVotingView(
            missionResultSelected: .constant(false)
        )
        .environmentObject(gameService)
        .previewLayout(.sizeThatFits)
    }
}

