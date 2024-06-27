//
//  gameEnd.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/26/24.
//

import SwiftUI

struct gameEnd: View {
    @EnvironmentObject var gameService: GameService
    @EnvironmentObject var navigationView: NavigationViewModel

    @State private var showConfetti = true

    var body: some View {
        VStack {
            if gameService.gameState.missions.filter({ $0.status == .success }).count >= 3 {
                Text("Resistance Wins!")
                    .font(Font.custom("Lobster Two", size: 55))
                    .foregroundStyle(Color.white)
                    .padding(.top, 200)
            } else if gameService.gameState.missions.filter({ $0.status == .fail }).count >= 3 {
                Text("Spies Win!")
                    .font(Font.custom("Lobster Two", size: 70))
                    .foregroundStyle(Color.white)
                    .padding(.top, 200)
            }
            Button() {
                restartGame()
            } label: {
                Text("New Game")
                .font(Font.custom("Mouse Memoirs", size: 40))
                .foregroundStyle(Color.black)
                .frame(width: 252, height: 71)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color(red: 1, green: 0.84, blue: 0), Color(red: 1, green: 0, blue: 0)]), startPoint: .leading, endPoint: .trailing)
                  )
                .cornerRadius(8)
                .shadow(
                    color: Color(red: 0, green: 0, blue: 0, opacity: 0.80), radius: 4, y: 8
                  )
                .padding(.top, 80)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.33, green: 0.09, blue: 0.44))
        .displayConfetti(isActive: $showConfetti)
    }
    
    func restartGame() {
        // Logic to reset the game state
        gameService.gameState = GameState(id: gameService.gameState.id)
        navigationView.currentView = .hostOrJoin
    }
}

struct gameEnd_Previews: PreviewProvider {
    static var previews: some View {
        let gameService = GameService()
        
        // Mock players
        let dummyPlayers = [
            Player(id: UUID(), name: "Player 1", role: .resistance, isLeader: false, isHost: true, votedOnLeader: false),
            Player(id: UUID(), name: "Player 2", role: .spy, isLeader: false, isHost: false, votedOnLeader: false),
            Player(id: UUID(), name: "Player 3", role: .resistance, isLeader: false, isHost: false, votedOnLeader: false),
            Player(id: UUID(), name: "Player 4", role: .spy, isLeader: false, isHost: false, votedOnLeader: false),
            Player(id: UUID(), name: "Player 5", role: .resistance, isLeader: true, isHost: false, votedOnLeader: false)
        ]
        
        // Mock missions
        let dummyMissions = [
            GameState.Mission(id: "mission1", leader: dummyPlayers[0].id, status: .success, missionAgents: [dummyPlayers[0].id: .fail, dummyPlayers[1].id: .success], votes: [dummyPlayers[0].id: .approve, dummyPlayers[1].id: .reject], leaderApprove: .approved),
            GameState.Mission(id: "mission2", leader: dummyPlayers[1].id, status: .fail, missionAgents: [dummyPlayers[2].id: .success, dummyPlayers[3].id: .success], votes: [dummyPlayers[2].id: .approve, dummyPlayers[3].id: .reject], leaderApprove: .rejected),
            GameState.Mission(id: "mission3", leader: dummyPlayers[2].id, status: .fail, missionAgents: [dummyPlayers[3].id: .success, dummyPlayers[4].id: .fail], votes: [dummyPlayers[3].id: .approve, dummyPlayers[4].id: .reject], leaderApprove: .approved),
            GameState.Mission(id: "mission4", leader: dummyPlayers[3].id, status: .fail, missionAgents: [dummyPlayers[0].id: .success, dummyPlayers[1].id: .success], votes: [dummyPlayers[0].id: .approve, dummyPlayers[1].id: .reject], leaderApprove: .rejected),
            GameState.Mission(id: "mission5", leader: dummyPlayers[4].id, status: .success, missionAgents: [dummyPlayers[2].id: .success, dummyPlayers[3].id: .fail], votes: [dummyPlayers[2].id: .approve, dummyPlayers[3].id: .reject], leaderApprove: .approved)
        ]
        
        gameService.gameState = GameState(
            id: "example_game_id",
            players: dummyPlayers,
            currentPhase: .gameEnd,
            currentLeaderIndex: 0,
            missions: dummyMissions
        )
        
        return gameEnd()
            .environmentObject(gameService)
            .environmentObject(NavigationViewModel())
            .previewLayout(.sizeThatFits)
    }
}


struct DisplayConfettiModifier: ViewModifier {
    @Binding var isActive: Bool {
        didSet {
            if !isActive {
                opacity = 1
            }
        }
    }
    @State private var opacity = 1.0 {
        didSet {
            if opacity == 0 {
                isActive = false
            }
        }
    }
    
    private let animationTime = 10.0
    private let fadeTime = 4.0

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .overlay(isActive ? ConfettiContainerView().opacity(opacity) : nil)
                .sensoryFeedback(.success, trigger: isActive)
                .task {
                    await handleAnimationSequence()
                }
        } else {
            content
                .overlay(isActive ? ConfettiContainerView().opacity(opacity) : nil)
                .task {
                    await handleAnimationSequence()
                }
        }
    }

    private func handleAnimationSequence() async {
        do {
            try await Task.sleep(nanoseconds: UInt64(animationTime * 1_000_000_000))
            withAnimation(.easeOut(duration: fadeTime)) {
                opacity = 0
            }
        } catch {}
    }
}

extension View {
    func displayConfetti(isActive: Binding<Bool>) -> some View {
        self.modifier(DisplayConfettiModifier(isActive: isActive))
    }
}

struct ConfettiContainerView: View {
    var count: Int = 200
    @State var yPosition: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { _ in
                ConfettiView()
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: yPosition != 0 ? CGFloat.random(in: 0...UIScreen.main.bounds.height) : yPosition
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            yPosition = CGFloat.random(in: 0...UIScreen.main.bounds.height)
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}

struct ConfettiView: View {
    @State var animate = false
    @State var xSpeed = Double.random(in: 0.7...2)
    @State var zSpeed = Double.random(in: 1...2)
    @State var anchor = CGFloat.random(in: 0...1).rounded()
    
    var body: some View {
        Rectangle()
            .fill([Color.orange, Color.green, Color.blue, Color.red, Color.yellow].randomElement() ?? Color.green)
            .frame(width: 20, height: 20)
            .onAppear(perform: { animate = true })
            .rotation3DEffect(.degrees(animate ? 360 : 0), axis: (x: 1, y: 0, z: 0))
            .animation(Animation.linear(duration: xSpeed).repeatForever(autoreverses: false), value: animate)
            .rotation3DEffect(.degrees(animate ? 360 : 0), axis: (x: 0, y: 0, z: 1), anchor: UnitPoint(x: anchor, y: anchor))
            .animation(Animation.linear(duration: zSpeed).repeatForever(autoreverses: false), value: animate)
    }
}
