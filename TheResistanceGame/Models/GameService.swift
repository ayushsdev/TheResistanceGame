//
//  GameService.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/21/24.
//
import Foundation
import FirebaseDatabase
import Combine
import SwiftUI

@MainActor
class GameService: ObservableObject {
    private var dbRef: DatabaseReference = Database.database().reference()
    @Published var gameState: GameState
    private var cancellables: Set<AnyCancellable> = []
    @Published var currentPlayer: Player?
    @EnvironmentObject var navigationViewModel: NavigationViewModel
    
    init () {
        self.gameState = GameState(id: "")
        observeGameStateChanges()
//        listAllGames { gameIds in
//            print("List of game IDs: \(gameIds)")
//        }
    }
    
    private func generateJoinCode(length: Int = 6) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    private func observeGameStateChanges() {
        // Observe changes in gameState and trigger objectWillChange in GameService
        gameState.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func createGame(completion: @escaping (Result<String, Error>) -> Void) {
        let joinCode = generateJoinCode()
        let gameData: [String: Any] = [
            "players": [:],
            "state": [
                "currentPhase": "setup",
                "missionResults": [],
                "currentLeaderIndex": 0
            ]
        ]
        
        dbRef.child("games").child(joinCode).setValue(gameData) { [weak self] error, _ in
            guard let self = self else { return }
            if let error = error {
                print("Error creating game: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                self.gameState.id = joinCode
                completion(.success(joinCode))
            }
        }
    }
    
    func hostGame(playerName: String, completion: @escaping (Result<Void, Error>) -> Void) {
       createGame { [weak self] result in
           switch result {
           case .success(let joinCode):
               self?.joinGame(gameId: joinCode, playerName: playerName, isHostValue: true) { joinResult in
                   switch joinResult {
                   case .success(let playerId):
                       print("Host \(playerName) with ID \(playerId) has successfully joined the game \(joinCode)")
                       completion(.success(()))
                   case .failure(let joinError):
                       print("Failed to join the newly created game: \(joinError.localizedDescription)")
                       completion(.failure(joinError))
                   }
               }
           case .failure(let createError):
               print("Failed to create the game: \(createError.localizedDescription)")
               completion(.failure(createError))
           }
       }
   }
    
    func joinGame(gameId: String, playerName: String, isHostValue: Bool = false, completion: @escaping (Result<String, Error>) -> Void) {
        let playerId = UUID().uuidString
        let playerData: [String: Any] = [
            "name": playerName,
            "role": "unknown",  // Consider having role assignment logic separate or initialized differently
            "isLeader": false,   // This might need to be dynamically determined based on existing players
            "isHost": isHostValue
        ]

        // Check if the game exists
        dbRef.child("games").child(gameId).observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                // If the game exists, add the player to the game
                self.dbRef.child("games").child(gameId).child("players").child(playerId).setValue(playerData) { error, _ in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.gameState.id = gameId
                        self.currentPlayer = Player(id: UUID(uuidString: playerId)!, name: playerName, role: .unknown, isLeader: false, isHost: isHostValue)

                        self.fetchGameState(gameId: gameId) { result in
                            switch result {
                            case .success(let gameState):
                                self.gameState = gameState
//                                print("Fetched game state after joining: \(self.gameState.players)")
                                self.observeGame(gameId: gameId) // Continue observing for future changes
                                completion(.success(playerId))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    }
                }
            } else {
                // If the game does not exist, return an error
                let error = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Game with ID \(gameId) does not exist"])
                completion(.failure(error))
            }
        }
    }

    
    func fetchGameState(gameId: String, completion: @escaping (Result<GameState, Error>) -> Void) {
        dbRef.child("games").child(gameId).observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                let error = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Game data not found"])
                completion(.failure(error))
                return
            }
            if let gameState = self.parseGameData(data, gameId: gameId) {
                completion(.success(gameState))
            } else {
                let error = NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse game data"])
                completion(.failure(error))
            }
        }
    }

    
    func observeGame(gameId: String) {
        dbRef.child("games").child(gameId).observe(.value) { [weak self] snapshot, _ in
            guard let self = self, let data = snapshot.value as? [String: Any] else {
                print("Failed to fetch game data or data is not in expected format")
                return
            }
            DispatchQueue.main.async {
                if let newState = self.parseGameData(data, gameId: gameId) {
                    self.gameState = newState
//                    self.updateNavigation()
                    print("Game state updated successfully")
                } else {
                    print("Failed to parse game data")
                }
            }
        }
    }
    
    private func parseGameData(_ data: [String: Any], gameId: String) -> GameState? {
        guard let playersData = data["players"] as? [String: [String: Any]],
              let stateData = data["state"] as? [String: Any],
              let currentPhaseRaw = stateData["currentPhase"] as? String,
              let currentPhase = GameState.GamePhase(rawValue: currentPhaseRaw),
              let currentLeaderIndex = stateData["currentLeaderIndex"] as? Int else {
            return nil
        }
         
        let players = playersData.compactMap { (key, value) -> Player? in

                guard let name = value["name"] as? String,
                      let roleRaw = value["role"] as? String,
                      let role = Role(rawValue: roleRaw),
                      let isLeader = value["isLeader"] as? Bool,
                      let isHost = value["isHost"] as? Bool,
                      let uuid = UUID(uuidString: key) else {
                    print("Else is run for player \(key)")
                    return nil
                }
                return Player(id: uuid, name: name, role: role, isLeader: isLeader, isHost: isHost)
            }

//            print("Parsed players: \(players)")

        
//        print(players)

        var missionResults: [GameState.MissionResult] = []
        if let resultsData = stateData["missionResults"] as? [[String: Any]] {
            missionResults = resultsData.compactMap { resultData in
                guard let success = resultData["success"] as? Bool,
                      let votes = resultData["votes"] as? [Bool] else {
                    return nil
                }
                return GameState.MissionResult(success: success, votes: votes)
            }
        }
        
        // Find and update the currentPlayer
            if let currentPlayerId = currentPlayer?.id {
                if let updatedPlayer = players.first(where: { $0.id == currentPlayerId }) {
                    currentPlayer = updatedPlayer
                } else {
                    print("Current player not found in the updated game state.")
                }
            } else {
                print("Current player ID is not set.")
            }
        
        let gameState = GameState(id: gameId, players: players, currentPhase: currentPhase, missionResults: missionResults, currentLeaderIndex: currentLeaderIndex)
        return gameState
    }

}

extension GameService {
    func assignRoles() {
        var players = gameState.players
                
        let numberOfPlayers = players.count
        let numberOfSpies: Int
        let numberOfResistance: Int
        
        switch numberOfPlayers {
            case 1:
                numberOfSpies = 1
                numberOfResistance = 0
            case 5:
                numberOfSpies = 2
                numberOfResistance = 3
            case 6:
                numberOfSpies = 2
                numberOfResistance = 4
            case 7:
                numberOfSpies = 3
                numberOfResistance = 4
            case 8:
                numberOfSpies = 3
                numberOfResistance = 5
            case 9:
                numberOfSpies = 3
                numberOfResistance = 6
            case 10:
                numberOfSpies = 4
                numberOfResistance = 6
            default:
            print("yuh")
                return
            }
        
        // Create an array of roles
        var roles = [Role](repeating: .resistance, count: numberOfResistance) +
                    [Role](repeating: .spy, count: numberOfSpies)
        
        // Shuffle the roles
        roles.shuffle()

        // Assign roles to players
        for i in 0..<players.count {
            players[i].role = roles[i]
        }

        // Update the game state
        gameState.players = players
        

        for player in players {
            dbRef.child("games").child(gameState.id).child("players").child(player.id.uuidString).updateChildValues(["role": player.role.rawValue])
        }
        dbRef.child("games").child(gameState.id).child("state").updateChildValues(["currentPhase": "rolereveal"])
        
    }
    
    func updateNavigation(navigationViewModel: NavigationViewModel) {
        let gameState = gameState
        
        switch gameState.currentPhase {
        case .setup:
            print("Setup mode")
        case .rolereveal:
            print("Role Reveal Mode")
            print(currentPlayer?.role ?? "no player role")
            if let playerRole = currentPlayer?.role {
                if playerRole == .spy {
                    navigationViewModel.currentView = .spyReveal
                    print("Spy Mode")
                } else if playerRole == .resistance {
                    navigationViewModel.currentView = .resistanceReveal
                    print("Resistance Mode")
                }
            }
        }
    }
}

