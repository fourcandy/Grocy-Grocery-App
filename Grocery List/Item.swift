//
//  Item.swift
//  Grocery List
//
//  Created by Moksh Bisht on 08/04/2025.
//

import Foundation
import SwiftData

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
