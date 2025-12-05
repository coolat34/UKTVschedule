//
//  UKTVscheduleApp.swift
//  UKTVschedule
//
//  Created by Chris Milne on 05/11/2025.
//

import SwiftUI
import SwiftData

@main
struct UKTVscheduleApp: App {
    @StateObject private var handler = Handler()


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(handler)
        }
        .modelContainer(for: [SavedChannel.self, SavedProgram.self])

    }
}

