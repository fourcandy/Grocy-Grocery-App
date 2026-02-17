//
//  Item.swift
//  Grocery List
//
//  Created by Moksh Bisht on 08/04/2025.
//

import Foundation
import SwiftData
import SwiftUI

@Model class Item {
    var title: String
    var notes: String
    var isCompleted: Bool
    var category: String
    var dateAdded: Date
    
    init(
        title: String,
        notes: String = "",
        isCompleted: Bool,
        category: ItemCategory = .fruitAndVeg,
        dateAdded: Date = Date()
    ) {
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.category = category.rawValue
        self.dateAdded = dateAdded
    }
}

extension Item {
    var itemCategory: ItemCategory {
        get { ItemCategory(rawValue: category) ?? .other }
        set { category = newValue.rawValue }
    }
}
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

