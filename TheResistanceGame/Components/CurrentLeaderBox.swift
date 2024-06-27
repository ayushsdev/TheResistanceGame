//
//  CurrentLeaderBox.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/23/24.
//

import SwiftUI

struct CurrentLeaderBox: View {
    var currentLeader: String
    var message: String
    var borderColor: Color

    var body: some View {
        NavigationStack {
            HStack (spacing: 30)    {
                Text("\(message) \(currentLeader)")
                    .font(Font.custom("Jockey One", size: 20))
                    .foregroundStyle(Color.black)
//                    .padding(.leading, 0)
                
                NavigationLink {
                    PlayerOrderView()
                } label: {
                    Text("View Player Order")
                        .frame(width: 168, height: 50)
                        .foregroundStyle(Color.white)
                        .background(.black)
                        .cornerRadius(5)
                        .shadow(
                            color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4, y: 4
                        )
                }

                

            }
            .frame(width: 349, height: 70)
            .background(Color(red: 0.11, green: 0.70, blue: 0.56))
            .border(borderColor, width: 4)
        .cornerRadius(10)
        }
    }
}

#Preview {
    CurrentLeaderBox(currentLeader: "Ayush", message: "Leader: ", borderColor: Color(red: 0.11, green: 0.70, blue: 0.56))
        .environmentObject(GameService())
}
