//
//  ItemCategory.swift
//  Grocery List
//
//  Created by Moksh Bisht on 16/02/2026.
//

import SwiftUI

enum ItemCategory: String, CaseIterable, Identifiable, Codable {
    case fruitAndVeg = "Fruit & Veg"
    case dairyAndEggs = "Dairy & Eggs"
    case meatAndSeafood = "Meat & Seafood"
    case bakeryAndBread = "Bakery & Bread"
    case pantry = "Pantry"
    case snacks = "Snacks"
    case household = "Household"
    case other = "Other"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .fruitAndVeg:
            return .green
        case .dairyAndEggs:
            return .blue
        case .meatAndSeafood:
            return .red
        case .bakeryAndBread:
            return .orange
        case .pantry:
            return .brown
        case .snacks:
            return .pink
        case .household:
            return .teal
        case .other:
            return .gray
        }
    }
}
