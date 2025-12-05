//
//  Item.swift
//  UKTVschedule
//
//  Created by Chris Milne on 25/08/2025.
//

import Foundation
import SwiftData

@Model
final class SavedChannel: Identifiable  {
    var name: String
    var icon: String
    var xmltvID: String // ✅ store the real XMLTV ID
    var sortName: String
    var isFavorite: Bool = true
    
    init(name: String = "",  icon: String = "", xmltvID: String = "", sortName: String = "") {
        self.name = name
        self.icon = icon
        self.xmltvID = xmltvID
        self.sortName = name.trimmingCharacters(in: .whitespaces)
    }
    }

