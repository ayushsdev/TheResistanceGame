//
//  NavigationViewModel.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/21/24.
//

import Foundation

@MainActor
class NavigationViewModel: ObservableObject {
    @Published var currentView: navigationViews = .hostOrJoin
    
    enum navigationViews {
        case hostOrJoin
        case waitingLobby
        case spyReveal
        case resistanceReveal
    }
}
