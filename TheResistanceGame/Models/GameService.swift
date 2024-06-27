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


// Extension to transform dictionary keys
extension Dictionary where Key == String, Value == Bool {
    func compactMapKeys<Transformed>(_ transform: (Key) -> Transformed?) -> [Transformed: Value] {
        var result = [Transformed: Value]()
        for (key, value) in self {
            if let transformedKey = transform(key) {
                result[transformedKey] = value
            }
        }
        return result
    }
}

@MainActor
class GameService: ObservableObject {
    private var dbRef: DatabaseReference = Database.database().reference()
    @Published var gameState: GameState
    private var cancellables: Set<AnyCancellable> = []
    @Published var currentPlayer: Player
    @EnvironmentObject var navigationView: NavigationViewModel
    @Published var wasRoleRevealed: Bool = false
//    @Published var votedOnLeader: Bool = false
    
    init () {
        self.gameState = GameState(id: "")
        let playerId = UUID().uuidString
        self.currentPlayer = Player(id: UUID(uuidString: playerId)!, name: "", role: .unknown, isLeader: false, isHost: false, votedOnLeader: false)

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
                "currentLeaderIndex": 0,
                "playerOrder": [:] // Initialize playerOrder as an empty dictionary

            ],
            "missions": [:] // Initialize missions as an empty dictionary
        ]
        
        dbRef.child("games").child(joinCode).setValue(gameData) { [weak self] error, _ in
            guard let self = self else { return }
            if let error = error {
                print("Error creating game: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                self.gameState.id = joinCode
                
                //initializing missions
                for index in 1..<6 {
                    let status = (index == 1) ? "inProgress" : "notStarted"
                    self.setupMissionNode(gameId: joinCode, missionId:  "mission\(index)", status: status, hostPlayerId: self.currentPlayer.id)
                }
                
                completion(.success(joinCode))
            }
        }
    }
    
    func joinGame(gameId: String, playerName: String, isHostValue: Bool = false, completion: @escaping (Result<String, Error>) -> Void) {
        let playerId = self.currentPlayer.id.uuidString
        let playerData: [String: Any] = [
            "name": playerName,
            "role": "unknown",  // Consider having role assignment logic separate or initialized differently
            "isLeader": false,   // This might need to be dynamically determined based on existing players
            "isHost": isHostValue,
            "votedOnLeader": false
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
                        self.currentPlayer.name = playerName
                        self.currentPlayer.isHost = isHostValue
    
                        
                        self.fetchGameState(gameId: gameId) { result in
                            switch result {
                            case .success(let gameState):
                                self.gameState = gameState
                                
                                // Number of players - Placeholder value, update this to get actual player count
                                let playerCount = self.gameState.players.count
                                let playerIds = self.gameState.players.map { $0.id }
                                
                                //setting the valye of host in hostGame function
                                if !isHostValue {
                                    self.dbRef.child("games").child(gameId).child("playerOrder").child("\(playerCount)").setValue(playerId)
                                } else {
//                                    print("Is a host")
                                }
                                
//                                print("These are outer playerIds being")
//                                print(playerIds)
                                
                                self.gameState.playerOrder[playerCount] = self.currentPlayer.id     //setting the values of players (0: playerId)   //dont need this if im updating firebase
                                
//                                let missionCounts = self.getMissionAgentCounts(for: playerCount)
                //                print(missionCounts)
                                // Initialize five missions with the first mission inProgress
//                                for (index, count) in missionCounts.enumerated() {
////                                    print(index, count)
//                                    let status = (index == 0) ? "inProgress" : "notStarted"
//                                    self.setupMissionNode(gameId: gameId, missionId: "mission\(index + 1)", status: status, numberOfAgents: count, playerIds: playerIds)
//                                }
//                                self.updateMissionAgentCount(gameId: gameId, numberOfAgents: missionCounts)
//                                print("Fetched game state after joining: \(self.gameState.players)")
                                
                                for mission in self.gameState.missions {
                                    self.addVoteToMission(gameId: gameId, missionId: mission.id, playerId: self.currentPlayer.id, status: .notVoted)
                                }
                                
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
    
    func hostGame(playerName: String, completion: @escaping (Result<Void, Error>) -> Void) {
       createGame { [weak self] result in
           switch result {
           case .success(let joinCode):
//               let testId = UUID().uuidString
               self?.dbRef.child("games").child(joinCode).child("playerOrder").child("0").setValue(self?.currentPlayer.id.uuidString)
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
    

    
    func fetchGameState(gameId: String, completion: @escaping (Result<GameState, Error>) -> Void) {
        print("fetchingg game state")
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
                    print("Failed to parse game data and observe")
                }
            }
        }
    }
    
    private func parseGameData(_ data: [String: Any], gameId: String) -> GameState? {
//        print("Starting to parse game data")
//        print("Parsing game data is run")
        guard let playersData = data["players"] as? [String: [String: Any]],
               let stateData = data["state"] as? [String: Any],
               let currentPhaseRaw = stateData["currentPhase"] as? String,
               let currentPhase = GameState.GamePhase(rawValue: currentPhaseRaw),
               let currentLeaderIndex = stateData["currentLeaderIndex"] as? Int,
               let playerOrderArray = data["playerOrder"] as? [String] else {
             return nil
         }
//        print("This is playersData: \(playersData)")
//        print("This is playersOrderArray: \(playerOrderArray)")
//        print("This is type of playersOrderArray: \(type(of:playerOrderArray))")
        
        
//        print("Parsed 'playerOrder' data")
        
       // Parse player order as an array
//        let playerOrder = playerOrderArray.compactMap { UUID(uuidString: $0) }
//        let orderedPlayerIds = playerOrder


//        print("Parsed player order: \(playerOrder)")
//        print("Ordered player IDs: \(orderedPlayerIds)")
//        print(playerOrderArray[0])
//        print(playersData[playerOrderArray[0]] ?? "The error is here buddy")
        

        // Parse players
        var players: [Player] = []
        var index = 0
        var playerOrder: [Int: UUID] = [:]
        for playerId in playerOrderArray {
            if let playerData = playersData[playerId] {
                
                if let name = playerData["name"] as? String,
                   let playerIdUUID = UUID(uuidString: playerId),
                   let roleRaw = playerData["role"] as? String,
                   let role = Role(rawValue: roleRaw),
                   let isLeader = playerData["isLeader"] as? Bool,
                   let isHost = playerData["isHost"] as? Bool,
                   let votedOnLeader = playerData["votedOnLeader"] as? Bool {
                    let player = Player(id: playerIdUUID, name: name, role: role, isLeader: isLeader, isHost: isHost, votedOnLeader: votedOnLeader )
//                        print("Appending player: \(player)")
                    players.append(player)
                } else {
                    print("Failed to parse all properties for player ID \(playerId)")
                }
            } else {
                print("No player data found for ID \(playerId)")
            }
            playerOrder[index] = UUID(uuidString: playerId)
            index = index + 1
        }
        
//        print("Parsed players: \(players)")
        
        // Parse missions
        var missions: [GameState.Mission] = []
//        print("details abour mission: \(data["missions"] ?? "Mission Data not available")")
        if let missionsData = data["missions"] as? [String: Any] {
            for (key, value) in missionsData {
                guard let missionData = value as? [String: Any],
                      let statusRaw = missionData["status"] as? String,
                      let status = GameState.MissionStatus(rawValue: statusRaw),
                      let missionAgentsRaw = missionData["missionAgents"] as? [String: String],
                      let leaderIdString = missionData["leader"] as? String,
                      let leaderId = UUID(uuidString: leaderIdString),
                      let leaderApproveRaw = missionData["leaderApprove"] as? String,
                      let leaderApprove = GameState.LeaderApproveStatus(rawValue: leaderApproveRaw),
                      let votesRaw = missionData["votes"] as? [String: String] else {
                    continue
                }
                
                print("Mission status for mission: \(key) is \(status)")
                
                let missionAgents: [UUID: GameState.MissionVote] = missionAgentsRaw.reduce(into: [UUID: GameState.MissionVote]()) { result, pair in
                    if let key = UUID(uuidString: pair.key), let value = GameState.MissionVote(rawValue: pair.value) {
                        result[key] = value
                    }
                }     
                var votes = [UUID: GameState.TeamVoteStatus]()

                for (key, value) in votesRaw {
                    if let uuid = UUID(uuidString: key), let status = GameState.TeamVoteStatus(rawValue: value) {
                        votes[uuid] = status
                    }
                }
//                print(statusRaw)
                print("These are mission votes: \(votes)")
                let mission = GameState.Mission(id: key, leader: leaderId, status: status, missionAgents: missionAgents, votes: votes, leaderApprove: leaderApprove)
                missions.append(mission)
//                print("Mission update is tried")
            }
        }
//        print("These are updated mission details")
//        print(missions)
        
        // Update currentPlayer if it exists in the parsed players
        let currentPlayerId = currentPlayer.id
        if let updatedPlayer = players.first(where: { $0.id == currentPlayerId }) {
            currentPlayer = updatedPlayer
        }
            
      

        // Create and return the new GameState object
        return GameState(
            id: gameId,
            players: players,
            currentPhase: currentPhase,
//            missionResults: missionResults,
            currentLeaderIndex: currentLeaderIndex,
            missions: missions,
            playerOrder: playerOrder
        )
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
//            print("yuh")
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
        updateGamePhase(to: .teamProposal)
//        dbRef.child("games").child(gameState.id).child("state").updateChildValues(["currentPhase": "rolereveal"])
        
    }
    
    func updateNavigation(navigationViewModel: NavigationViewModel) {
        let gameState = gameState
        
        switch gameState.currentPhase {
        case .setup:
            print("Setup mode")
        case .rolereveal:
            print("Role Reveal Mode")
//            print(currentPlayer.role)
//            let playerRole = currentPlayer.role
//            if playerRole == .spy {
//                navigationViewModel.currentView = .spyReveal
//                print("Spy Mode")
//            } else if playerRole == .resistance {
//                navigationViewModel.currentView = .resistanceReveal
//                print("Resistance Mode")
//            }
            
            //        case .teamProposal:
            //            print("team proposal")
           
        case .teamProposal:
            print("team proposal")
            navigationViewModel.currentView = .mainGame
        case .teamVoting:
            print("team voting")
        case .missionInProgress:
            print("missionInProgress")
   
        case .gameEnd:
            navigationViewModel.currentView = .gameEnd
        }
    }
    
    func setupMissionNode(gameId: String, missionId: String, status: String = "notStarted", hostPlayerId: UUID) {
        
        let dbRef = Database.database().reference()
        let unknownLeaderUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")! // Placeholder UUID for unknown leader
        
//        print("These are player ids argument in mission: \(playerIds) \n")
        
        // Initialize votes with default value for each player
        var votes: [String: String] = [:]
//        for playerId in playerIds {
//            votes[playerId.uuidString] = false // Assuming false as the default value for not voted
//            print("This is value of votes")
//            print(votes[playerId.uuidString] ?? "no votes given")
//        }
        
        votes[hostPlayerId.uuidString] = "notVoted"
        // Create a dictionary for mission agents with placeholder values
        var missionAgents: [String: String] = [:]
//        for _ in 0..<numberOfAgents {
//            missionAgents[unknownLeaderUUID.uuidString] = "notVoted"
//        }
        missionAgents[unknownLeaderUUID.uuidString] = "notVoted"
        
        let missionData: [String: Any] = [
            "status": status,
            "leader": unknownLeaderUUID.uuidString, // Set the leader to the placeholder UUID
            "missionAgents": missionAgents,
            "votes": votes,
            "leaderApprove": "undecided"
        ]
        
        dbRef.child("games").child(gameId).child("missions").child(missionId).setValue(missionData)
        //        print("This is run")
    }
    func updateMissionStatus(gameId: String, missionId: String, status: String) {
        let dbRef = Database.database().reference()
        dbRef.child("games").child(gameId).child("missions").child(missionId).child("status").setValue(status)
    }
    
    func addVoteToMission(gameId: String, missionId: String, playerId: UUID, status: GameState.TeamVoteStatus) {
        let dbRef = Database.database().reference()
        dbRef.child("games").child(gameId).child("missions").child(missionId).child("votes").child(playerId.uuidString).setValue(status.rawValue)
    }
    
    func updateMissionAgentCount(gameId: String, numberOfAgents: [Int] ) {
        let dbRef = Database.database().reference()
        var missionAgents: [String: String] = [:]
        var index = 0
        for mission in gameState.missions {
            for _ in 0..<numberOfAgents[index] {
                missionAgents["00000000-0000-0000-0000-000000000000"] = "notVoted"
                index = index + 1
            }
            dbRef.child("games").child(gameId).child("missions").child(mission.id).child("missionAgents").childByAutoId().setValue(missionAgents)
        }
    }
    
    func getMissionAgentCounts(for playerCount: Int) -> [Int] {
        switch playerCount {
        case 5:
            return [2, 3, 2, 3, 3]
        case 6:
            return [2, 3, 4, 3, 4]
        case 7:
            return [2, 3, 3, 4, 4]
        case 8:
            return [3, 4, 4, 5, 5]
        case 9:
            return [3, 4, 4, 5, 5]
        case 10:
            return [3, 4, 4, 5, 5]
        default:
            return [1, 2, 3, 4, 5]  //change this to [] post test
        }
    }
    
    func updateMissionAgents(missionId: String, agents: [UUID]) {
        let missionAgents = agents.reduce(into: [String: String]()) { result, agentId in
            result[agentId.uuidString] = GameState.MissionVote.notVoted.rawValue
        }
        
        dbRef.child("games").child(gameState.id).child("missions").child(missionId).updateChildValues(["missionAgents": missionAgents])
    }
}

extension GameService {
    func selectRandomLeader() {
         guard !gameState.players.isEmpty else {
             print("No players available to select a leader.")
             return
         }
        
         let randomIndex = Int.random(in: 0..<gameState.players.count)
         gameState.currentLeaderIndex = randomIndex
        
//        let selectedLeaderId = gameState.players[randomIndex].id
        print("This is player order: \(gameState.playerOrder)")
        // Update the isLeader property for each player using the playerOrder array
        for (index, playerId) in gameState.playerOrder {
            print("updating player: \(playerId) from playerOrder")
            if let playerIndex = gameState.players.firstIndex(where: { $0.id == playerId }) {
                print("updating player: \(playerIndex)")
                gameState.players[playerIndex].isLeader = (index == gameState.currentLeaderIndex)
                let playerUUID = playerId.uuidString
                dbRef.child("games").child(gameState.id).child("players").child(playerUUID).updateChildValues(["isLeader": (index == gameState.currentLeaderIndex)])
                print("\(playerUUID) is the leader: \(index == gameState.currentLeaderIndex)")
            }
        }
//        print("The current Leader Index is \(randomIndex)")

         dbRef.child("games").child(gameState.id).child("state").updateChildValues(["currentLeaderIndex": randomIndex])
        
//        // Update the players array and Firebase
//        for (index, player) in gameState.players.enumerated() {
//            gameState.players[index].isLeader = (index == randomIndex)
//            let playerId = player.id.uuidString
//            dbRef.child("games").child(gameState.id).child("players").child(playerId).updateChildValues(["isLeader": (index == randomIndex)])
//        }
        
        // Get the list of player IDs from playerOrder in the correct order
//        let orderedPlayerIds = gameState.playerOrder.sorted { $0.key < $1.key }.map { $0.value }
        guard let randomPlayerId = gameState.playerOrder[randomIndex] else {
            return
        }

        
        // Update the leader in the current mission
        if var currentMission = gameState.missions.first(where: { $0.status == .inProgress }) {
            currentMission.leader = randomPlayerId
            let missionId = currentMission.id
            dbRef.child("games").child(gameState.id).child("missions").child(missionId).updateChildValues(["leader": randomPlayerId.uuidString])
            print("Updated mission \(missionId) with new leader \(randomPlayerId)")
        } else {
            print("No mission is currently in progress.")
        }
        
     }
    
    func advanceLeader() {
        guard !gameState.players.isEmpty else {
            print("No players available to advance the leader.")
            return
        }

        gameState.currentLeaderIndex = (gameState.currentLeaderIndex + 1) % gameState.players.count

        // Update the isLeader property for each player using the playerOrder array
        for (index, playerId) in gameState.playerOrder {
            if let playerIndex = gameState.players.firstIndex(where: { $0.id == playerId }) {
                gameState.players[playerIndex].isLeader = (index == gameState.currentLeaderIndex)
                let playerUUID = playerId.uuidString
                dbRef.child("games").child(gameState.id).child("players").child(playerUUID).updateChildValues(["isLeader": (index == gameState.currentLeaderIndex)])
            }
        }
        

        // Update the current mission with the new leader using playerOrder array
       let newLeaderId = gameState.playerOrder[gameState.currentLeaderIndex]!
       if var currentMission = gameState.missions.first(where: { $0.status == .inProgress }) {
//           print("This is the current mission whose leader is being updated: \(currentMission)")
           currentMission.leader = newLeaderId
           let missionId = currentMission.id
           let missionRef = dbRef.child("games").child(gameState.id).child("missions").child(missionId)

           missionRef.updateChildValues(["leader": newLeaderId.uuidString])
//           print("Updated mission \(missionId) with new leader \(newLeaderId)")
           
           // Reset all player votes to notVoted
           var votesReset = [String: String]()
           for (_, playerId) in gameState.playerOrder {
               votesReset[playerId.uuidString] = "notVoted"
           }
           missionRef.child("votes").setValue(votesReset)
       } else {
           print("No mission is currently in progress.")
       }

        
        // Update the game state in Firebase
        dbRef.child("games").child(gameState.id).child("state").updateChildValues(["currentLeaderIndex": gameState.currentLeaderIndex])
        
        let missionId = gameState.missions.first { $0.status == .inProgress }?.id ?? "random id"
        
        updateLeaderApproveStatus(for: missionId, leaderApproveStatus: .undecided) { result in
            switch result {
            case .success:
                print("Leader approve status updated successfully.")
            case .failure(let error):
                print("Failed to update leader approve status: \(error.localizedDescription)")
            }
            
        }
        updateVotedOnLeaderForAllPlayers(voted: false)
//        print("New leader: \(gameState.players[gameState.currentLeaderIndex].name)")
    }
    
    func updateVotedOnLeader(for playerId: UUID, voted: Bool) {
        // Get a reference to the player's node in Firebase
        let playerRef = dbRef.child("games").child(gameState.id).child("players").child(playerId.uuidString)
        
        // Update the votedOnLeader property
        playerRef.updateChildValues(["votedOnLeader": voted]) { error, _ in
            if let error = error {
                print("Error updating votedOnLeader for player \(playerId): \(error.localizedDescription)")
            } else {
                print("Successfully updated votedOnLeader for player \(playerId)")
            }
        }
    }

    func updateVotedOnLeaderForAllPlayers(voted: Bool) {
        // Iterate over all players in the game
        for player in gameState.players {
            // Get a reference to the player's node in Firebase
            let playerRef = dbRef.child("games").child(gameState.id).child("players").child(player.id.uuidString)
            
            // Update the votedOnLeader property
            playerRef.updateChildValues(["votedOnLeader": voted]) { error, _ in
                if let error = error {
                    print("Error updating votedOnLeader for player \(player.id): \(error.localizedDescription)")
                } else {
                    print("Successfully updated votedOnLeader for player \(player.id)")
                }
            }
        }
    }

}

extension GameService {
    func updateGamePhase(to newPhase: GameState.GamePhase) {
        gameState.currentPhase = newPhase
        dbRef.child("games").child(gameState.id).child("state").updateChildValues(["currentPhase": newPhase.rawValue]) { error, _ in
            if let error = error {
                print("Failed to update game phase: \(error.localizedDescription)")
            } else {
                print("Successfully updated game phase to \(newPhase.rawValue) in Firebase")
            }
        }
    }
    
    func updateLeaderApproveStatus(for missionId: String, leaderApproveStatus: GameState.LeaderApproveStatus, completion: @escaping (Result<Void, Error>) -> Void) {
            let missionRef = dbRef.child("games").child(gameState.id).child("missions").child(missionId)
        let updateData = ["leaderApprove": leaderApproveStatus.rawValue]

            missionRef.updateChildValues(updateData) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                    print("Leader approve status updated successfully for mission \(missionId)")
                }
            }
        }
}

extension GameService {
    func voteOnTeam(status: GameState.TeamVoteStatus) {
        guard let currentMissionIndex = gameState.missions.firstIndex(where: { $0.status == .inProgress }) else {
            print("No mission is currently in progress.")
            return
        }
        
        let playerId = currentPlayer.id
        let missionId = gameState.missions[currentMissionIndex].id
        let votesRef = dbRef.child("games").child(gameState.id).child("missions").child(missionId).child("votes")
        
        votesRef.runTransactionBlock { currentData -> TransactionResult in
            var votes = currentData.value as? [String:String] ?? [:]
            votes[playerId.uuidString] = status.rawValue
            currentData.value = votes
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { error, _, snapshot in
            if let error = error {
                print("Failed to update votes: \(error.localizedDescription)")
            } else {
                print("Successfully updated votes in Firebase")
                
                // Check if all players have voted
                if let votesRaw = snapshot?.value as? [String: String] {
                    var votes = [UUID: GameState.TeamVoteStatus]()
                    for (key, value) in votesRaw {
                        if let uuid = UUID(uuidString: key), let status = GameState.TeamVoteStatus(rawValue: value) {
                            votes[uuid] = status
                        }
                    }
                    self.gameState.missions[currentMissionIndex].votes = votes
                    if self.gameState.missions[currentMissionIndex].votes.count == self.gameState.players.count &&
                        !self.gameState.missions[currentMissionIndex].votes.values.contains(.notVoted) {
                        self.evaluateVotes()
                    }
                }
            }
        }
    }
    
    private func evaluateVotes() {
        guard let currentMissionIndex = gameState.missions.firstIndex(where: { $0.status == .inProgress }) else {
                print("No mission is currently in progress.")
                return
            }
            
        let missionId = gameState.missions[currentMissionIndex].id
        let currentMission = gameState.missions[currentMissionIndex]
        let approvedVotes = currentMission.votes.values.filter { $0 == .approve }.count
        let rejectedVotes = currentMission.votes.values.filter { $0 == .reject }.count
        
        if approvedVotes > rejectedVotes {
            // Majority approves, move to missionInProgress
            updateLeaderApproveStatus(for: missionId, leaderApproveStatus: .approved) { result in
                switch result {
                case .success:
                    print("Leader approve status updated successfully.")
                case .failure(let error):
                    print("Failed to update leader approve status: \(error.localizedDescription)")
                }
                
            }
            updateGamePhase(to: .missionInProgress)
//            print("Team approved. Moving to missionInProgress.")
        } else {
            // Majority rejects, advance the leader
            updateLeaderApproveStatus(for: missionId, leaderApproveStatus: .rejected) { result in
                switch result {
                case .success:
                    print("Leader approve status updated successfully.")
                case .failure(let error):
                    print("Failed to update leader approve status: \(error.localizedDescription)")
                }
                
            }
            //            advanceLeader()
            updateGamePhase(to: .teamProposal)
//            print("Team rejected. Advancing leader and returning to teamProposal.")
        }
    }
    
    func voteOnMission(missionId: String, vote: GameState.MissionVote, completion: @escaping (Result<Void, Error>) -> Void) {
        let missionRef = dbRef.child("games").child(gameState.id).child("missions").child(missionId).child("missionAgents").child(currentPlayer.id.uuidString)
        
        missionRef.runTransactionBlock({ (currentData) -> TransactionResult in
            if let currentVote = currentData.value as? String, let _ = GameState.MissionVote(rawValue: currentVote) {
                currentData.value = vote.rawValue
                return TransactionResult.success(withValue: currentData)
            } else {
                currentData.value = vote.rawValue
                return TransactionResult.success(withValue: currentData)
            }
        }) { error, committed, snapshot in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if committed {
                self.checkMissionOutcome(missionId: missionId) { result in
                    completion(result)
                }
            }
        }
    }
        
    private func checkMissionOutcome(missionId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let missionRef = dbRef.child("games").child(gameState.id).child("missions").child(missionId).child("missionAgents")
        
        missionRef.observeSingleEvent(of: .value) { snapshot in
            guard let missionAgentsDict = snapshot.value as? [String: String] else {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve mission agents"])))
                return
            }
            
            let votes = missionAgentsDict.values.compactMap { GameState.MissionVote(rawValue: $0) }
//            print("These are votes of \(missionId) \(votes)")
            
            // Check if any agent has not voted
            if votes.contains(.notVoted) {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Not all agents have voted"])))
                return
            }
            
            let failVotes = votes.contains { $0 == .fail }

            let missionOutcome: Bool = !failVotes

            self.updateMissionOutcome(missionId: missionId, outcome: missionOutcome)
            completion(.success(()))
        }
    }
    
    private func updateMissionOutcome(missionId: String, outcome: Bool) {
        let missionRef = dbRef.child("games").child(gameState.id).child("missions").child(missionId)
        missionRef.child("status").setValue(outcome ? "success" : "fail") { error, success in
            if let error = error {
//                print("Error updating mission status: \(error.localizedDescription)")
                return
            }
            if self.checkGameEnd() {
                self.updateGamePhase(to: .gameEnd)
//                print("Game has ended")
            } else {
                //updating the next mission's status
                if let currentMissionIndex = self.gameState.missions.firstIndex(where: { $0.id == missionId }) {
                    let currentMissionIdNumber = Int(missionId.replacingOccurrences(of: "mission", with: "")) ?? 0
//                    print("Current mission index: \(currentMissionIndex), Current mission number: \(currentMissionIdNumber)")
                    
                    let nextMissionIdNumber = currentMissionIdNumber + 1
                    let nextMissionId = "mission\(nextMissionIdNumber)"
//                    print("Next mission ID to check: \(nextMissionId)")
                    
                    if let nextMission = self.gameState.missions.first(where: { $0.id == nextMissionId }) {
//                        print("Next mission found: \(nextMission.id), updating status to inProgress")
                        let nextMissionRef = self.dbRef.child("games").child(self.gameState.id).child("missions").child(nextMission.id)
                        nextMissionRef.child("status").setValue("inProgress") { error, _ in
                            if let error = error {
                               // Handle the error appropriately
//                               print("Error updating status: \(error.localizedDescription)")
                               return
                           }
//                            print("Status updated for mission \(nextMission.id)")
                            self.updateGamePhase(to: .teamProposal)
                            self.advanceLeader()
                            
                        }
                    } else {
                        print("No more missions available or all missions are completed. Next mission ID: \(nextMissionId) not found.")
                    }
                } else {
                    print("Current mission not found for missionId: \(missionId)")
                }
            }
        }
    }
    
    private func checkGameEnd() -> Bool {
        let missionSuccessCount = gameState.missions.filter { $0.status == .success }.count
        let missionFailCount = gameState.missions.filter { $0.status == .fail }.count
        
        if missionSuccessCount >= 3 {
            updateGamePhase(to: .gameEnd)
            return true
        } else if missionFailCount >= 3 {
            updateGamePhase(to: .gameEnd)
            return true
        }
        return false
    }
    
}

