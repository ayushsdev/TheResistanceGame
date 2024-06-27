//
//  MissionCircle.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/22/24.
//

import SwiftUI

struct MissionCircle: View {
    
    @EnvironmentObject var gameService: GameService
    
    var numberOfPeople: Int
    var status: GameState.MissionStatus
    
    private var backgroundColor: Color {
        switch status {
        case .notStarted:
            return Color(red: 0.08, green: 0.16, blue: 0.22)
        case .inProgress:
            return Color(red: 0.08, green: 0.16, blue: 0.22)
        case .success:
            return Color(red: 0.02, green: 0.4, blue: 0.19)
        case .fail:
            return Color(red: 0.59, green: 0.05, blue: 0.05)
        }
    }
    
    var body: some View {
        VStack {
            Text("\(numberOfPeople)")
                .font(Font.custom("Inter", size: 45))
                .foregroundStyle(Color(red: 0.85, green: 0.85, blue: 0.85))

        }
        .frame(width: 64, height: 64)
        .background(backgroundColor)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.orange, lineWidth: status == .inProgress ? 5 : 0)
        )
    }
}

struct MissionCircle_Previews: PreviewProvider {
    @State static var numberOfPeople = 3
    @State static var status = GameState.MissionStatus.success

    static var previews: some View {
        MissionCircle(numberOfPeople: numberOfPeople, status: status)
            .padding()
            .background(Color.black)
    }
}
