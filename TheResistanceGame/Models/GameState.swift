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
    @Published var missionResults: [MissionResult]
    @Published var currentLeaderIndex: Int // Keeps track of the current leader
    
    init(id: String, players: [Player] = [], currentPhase: GamePhase = .setup, missionResults: [MissionResult] = [], currentLeaderIndex: Int = 0) {
        self.id = id
        self.players = players
        self.currentPhase = currentPhase
        self.missionResults = missionResults
        self.currentLeaderIndex = currentLeaderIndex
    }
    
    
    enum GamePhase: String {
        case setup      //includes playersetup and waiting lobby
        case rolereveal 
//        case teamSelection
//        case voting
//        case missionOutcome
    }
    
    struct MissionResult: Identifiable {
        var id = UUID()
        var success: Bool
        var votes: [Bool]
    }
}

struct Player: Identifiable {
    let id: UUID
    var name: String
    var role: Role
    var isLeader: Bool
    var isHost: Bool
}

enum Role: String {
    case spy
    case resistance
    case unknown
}
