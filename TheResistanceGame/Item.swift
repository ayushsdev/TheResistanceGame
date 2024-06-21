//
//  Item.swift
//  TheResistanceGame
//
//  Created by Ayush Sharma on 6/21/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
