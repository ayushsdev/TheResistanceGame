//
//  ResistanceRevealView.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/22/24.
//

import SwiftUI

struct ResistanceRevealView: View {
    @EnvironmentObject var navigationView: NavigationViewModel
    @EnvironmentObject var gameService: GameService
    @Environment(\.dismiss) var dismiss


    var body: some View {
        VStack (spacing: 0) {
            Text("You're part of ")
                .font(Font.custom("Dangrek", size: 40))
                .foregroundStyle(Color(.white))
                .padding(.top, 150)
            
            Text("The Resistance")
              .font(Font.custom("Dangrek", size: 50))
              .foregroundStyle(Color(.white))
              .padding(.top, 20)
            
            Button {
//                navigationView.currentView = .mainGame
                gameService.wasRoleRevealed = true
                dismiss()
            } label: {
                Text("Continue ->")
                    .font(Font.custom("Concert One", size: 36))
                    .frame(width: 244, height: 61)
                    .background(Color(red: 0.05, green: 0.06, blue: 0.19))
                    .foregroundStyle(Color(.white))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                          .inset(by: 1.50)
                          .stroke(Color(red: 0.48, green: 0.65, blue: 1), lineWidth: 3.50)
                      )
            }
            .padding(.top, 320)
            
            Spacer()
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Image("resistance-bg").resizable().ignoresSafeArea())
        .interactiveDismissDisabled()
        
    }
}

#Preview {
    ResistanceRevealView()
        .environmentObject(GameService())
        .environmentObject(NavigationViewModel())
}
