//
//  Item.swift
//  UKTVschedule
//
//  Created by Chris Milne on 25/08/2025.
//

import Foundation
import SwiftData

@Model
final class SavedProgram: Identifiable {
    var id: UUID = UUID()
    var start: Date
    var stop: Date
    var channel: String
    var channelName: String?
    var title: String?
    var desc: String?
    var date: String?
    var episode: String?
    var icon: String?

       init(start: Date,
            stop: Date,
            channel: String,
            channelName: String?,
            title: String,
            desc: String?,
            date: String?,
            episode: String?,
            icon: String?) {
  
           self.start = start
           self.stop = stop
           self.channel = channel
           self.channelName = channelName
           self.title = title
           self.desc = desc
           self.date = date
           self.episode = episode
           self.icon = icon
       }
   }

