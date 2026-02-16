//
//  Tip.swift
//  Grocery List
//
//  Created by Moksh Bisht on 11/04/2025.
//

import Foundation
import TipKit

struct ButtonTip: Tip {
    var title: Text = Text("Essential Foods")
    var message: Text? = Text("Add some everyday items to the shopping list with the tap of a button!")
    var image: Image? = Image(systemName: "info.circle")
}
