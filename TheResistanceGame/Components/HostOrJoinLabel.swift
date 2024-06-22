//
//  HostOrJoinLabel.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/21/24.
//

import SwiftUI

struct HostOrJoinLabel: View {
    var text: String
    @Binding var StartState: StartModeState
    var selected: Bool {
        switch StartState {
        case .join:
            return text == "Join"
        case .host:
            return text == "Host"
        }
    }
    var computedOpacity: Double {
        return selected == true ? 0.04 : 0.40
    }
    
    var body: some View {
        Text(text)
            .font(Font.custom("Menlo", size: 20).weight(.bold))
            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            .frame(width: 123, height: 61)
            .background(.white.opacity(computedOpacity))
            .foregroundColor(selected == false ? Color(red: 0.11, green: 0.07, blue: 0.07) : Color.white)
            .clipShape(
                UnevenRoundedRectangle(cornerRadii:.init(
                    topLeading: 10.0,
                    bottomLeading: 0.0,
                    bottomTrailing: 0.0,
                    topTrailing: 10.0))
            )

            .overlay(
                UnevenRoundedRectangle(cornerRadii:.init(
                    topLeading: 10.0,
                    bottomLeading: 0.0,
                    bottomTrailing: 0.0,
                    topTrailing: 10.0))
                .stroke(
                    Color(.white).opacity(selected == false ? 0.29 : 0)
                )
            )
    }
}

struct HostOrJoinLabel_Previews: PreviewProvider {
    @State static var isEnabled: StartModeState = .join

    static var previews: some View {
        HostOrJoinLabel(text: "Join", StartState: $isEnabled)
    }
}
