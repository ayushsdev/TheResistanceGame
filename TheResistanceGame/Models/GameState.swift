//
//  GameState.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/21/24.
//

import Foundation

@MainActor
class GameState: ObservableObject {
    @Published var id: String
    @Published var players: [Player]
    @Published var currentPhase: GamePhase
//    @Published var missionResults: [MissionResult]
//    @Published var currentLeaderIndex: Int
    @Published var missions: [Mission] // New property to store missions
    @Published var currentLeaderIndex: Int // Revert to index
    @Published var playerOrder: [Int: UUID] // New dictionary to maintain player order



    init(id: String, players: [Player] = [], currentPhase: GamePhase = .setup, currentLeaderIndex: Int = 0, missions: [Mission] = [], playerOrder: [Int: UUID] = [:]) {
        self.id = id
        self.players = players
        self.currentPhase = currentPhase
//        self.missionResults = missionResults
        self.currentLeaderIndex = currentLeaderIndex
        self.playerOrder = playerOrder
        self.missions = missions // Initialize missions
    }
    
    enum GamePhase: String {
        case setup      // Includes player setup and waiting lobby
        case rolereveal //this also encompasses teamProposal
        case teamProposal
        case teamVoting
        case missionInProgress
        case gameEnd
    }

    struct Mission: Identifiable {
        var id: String
        var leader: UUID    //thjs is to keep track 
        var status: MissionStatus
        var missionAgents: [UUID: MissionVote]
        var votes: [UUID: TeamVoteStatus]
        let leaderApprove: LeaderApproveStatus
    }

    enum MissionStatus: String {
        case notStarted
        case inProgress
        case success
        case fail
    }
    
    enum TeamVoteStatus: String {
        case notVoted
        case approve
        case reject
    }
    
    enum MissionVote: String {
        case notVoted
        case success
        case fail
    }
    enum LeaderApproveStatus: String {
        case undecided
        case approved
        case rejected
    }
}

struct Player: Identifiable {
    let id: UUID
    var name: String
    var role: Role
    var isLeader: Bool
    var isHost: Bool
    var votedOnLeader: Bool
}

enum Role: String {
    case spy
    case resistance
    case unknown
}
