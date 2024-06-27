//
//  MissionDetailView.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/22/24.
//

import SwiftUI

struct MissionDetailView: View {
    
    var missionLeader: String
    var missionStatus: GameState.MissionStatus
    let missionID: String // Changed to String
//    var onNavigate: () -> Void // Closure to handle navigation

    var body: some View {
        
//        Button(action: onNavigate) { // Execute the onNavigate closure when tapped
        HStack {
            Text(missionStatus != .notStarted ? "\(missionLeader)'s Mission" : "Mission not started")
                .font(Font.custom("Jockey One", size: 30))
                .foregroundColor(.black)
                .opacity(missionStatus == .notStarted ? 0.5 : 1.0) // Set opacity conditionally

                .padding()

            Spacer()

            Image(systemName: "arrow.right")
                .foregroundColor(missionStatus != .notStarted ? .black : .gray)
                .padding()
        }
        .frame(width: 361, height: 70)
        .foregroundStyle(Color.black)
        .background(Color(red: 0.85, green: 0.85, blue: 0.85))
        .cornerRadius(10)
//        }
//        .disabled(missionStatus == .notStarted) // Disable the button if the mission has not started
    }
}

struct MissionDetailView_Previews: PreviewProvider {
    @State static var missionStatus = GameState.MissionStatus.notStarted

    static var previews: some View {
        MissionDetailView(missionLeader: "Melanie", missionStatus: missionStatus, missionID: "mission1")
            .previewLayout(.sizeThatFits)
    }
}
