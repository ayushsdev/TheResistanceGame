//
//  SpyRevealView.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/21/24.
//

import SwiftUI

struct SpyRevealView: View {
//    @EnvironmentObject var gameService: GameService
    @EnvironmentObject var navigationView: NavigationViewModel
    @EnvironmentObject var gameService: GameService
    @Environment(\.dismiss) var dismiss

    
    private var spyNames: String {
        let spies = gameService.gameState.players.filter { $0.role == .spy }
        return spies.map { $0.name }.joined(separator: ", ")
    }
    
    var body: some View {
        VStack (spacing: 0) {
            Text("You're a ")
                .font(Font.custom("Dangrek", size: 40))
                .foregroundStyle(Color(.white))
                .padding(.top, 150)
            
            Text("Spy")
              .font(Font.custom("Dangrek", size: 64))
              .foregroundStyle(Color(.white))
            
            Text("Spies:")
              .font(Font.custom("Dangrek", size: 40))
              .foregroundStyle(Color(.white))
              .padding(.top, 60)
            
            Text(spyNames)
              .font(Font.custom("Dangrek", size: 48))
              .foregroundStyle(Color(.white))
            
            Button {
//                navigationView.currentView = .mainGame
                gameService.wasRoleRevealed = true
                dismiss()

            } label: {
                Text("Continue ->")
                    .font(Font.custom("Concert One", size: 36))
                    .frame(width: 244, height: 61)
                    .background(Color(red: 0.46, green: 0.03, blue: 0.03))
                    .foregroundStyle(Color(.white))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                          .inset(by: 1.50)
                          .stroke(Color(red: 0.86, green: 0.36, blue: 0.36), lineWidth: 3.50)
                      )
            }
            .padding(.top, 70)
            
            Spacer()
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Image("spy-bg").resizable().ignoresSafeArea())
        .interactiveDismissDisabled()
    }
}

#Preview {
    SpyRevealView()
        .environmentObject(GameService())
        .environmentObject(NavigationViewModel())
}
