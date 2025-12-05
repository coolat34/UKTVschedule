//
//  Handler.swift
//  UKTVschedule
//
//  Created by Chris Milne on 07/09/2025.
//
import Foundation
import SwiftData
import SwiftUI
public class Handler: ObservableObject {
    
    @Published public var selectedDate: Date = Date()
    @Published public var chosenDay: Date = Date() {
        didSet { updateTimelineStart() }
        }

    @Published var totalWidth: CGFloat = 0.0
    @Published var minProgDuration: CGFloat = 300  /// 5 mins in secs
    @Published var minProgWidth: CGFloat = 30
    @Published var timelineStart: Date = Date()
    @Published var startHour : Double = 9.0 {
        didSet { updateTimelineStart() }
    }
    
    public var pointsPerMinute: CGFloat = 2.666
    public var channelColumnWidth: CGFloat = 200
    public var rowHeight: CGFloat = 60
    public var hourWidth: CGFloat = 60 * 2.666
    @Published var isDownloading: Bool = false

    @Published public var tabIndex: Int? = nil
    @Published public var tabBarDataList: [barData] = [
        barData(lable: "(1) Choose Channels"),
        barData(lable: "(2) View Channels")
        
    ]
    
    
    
    public init() { updateTimelineStart() }
    
    public class barData: Identifiable {
        public var id = UUID()
        var lable: String
        var gradientColors: [Color] = [.blue, .purple]
        
        public init(lable: String,  gradientColors: [Color] = [.blue, .purple]) {
            self.lable = lable
        }
    }
    
    
    /// Returns 48 half-hour slots
   public func generateTimeSlots(to end: Double = 24.0, step: Double = 0.5) -> [Date] {
        stride(from: startHour, to: end, by: step).compactMap { hour in
            let intHour = Int(hour)
            let minute = hour.truncatingRemainder(dividingBy: 1) == 0.5 ? 30 : 0
            return Calendar.current.date(bySettingHour: intHour, minute: minute, second: 0, of: chosenDay)
        }
    }

///    Returns the Horizontal starting pos on the screen for a given program
    func getXPosition(for program: SavedProgram?) -> CGFloat {
        guard let program = program else { return 0 }
        let minutesFromStart = Calendar.current.dateComponents([.minute], from: timelineStart, to: program.start).minute ?? 0
        return CGFloat(minutesFromStart) * pointsPerMinute
    }

   ///    Returns duration in minutes for a given program
        func getDuration(for program: SavedProgram?) -> CGFloat {
            guard let program = program else { return 0 }
            let minStart = Calendar.current.dateComponents([.minute], from: timelineStart, to: program.start).minute ?? 0
            let minEnd = Calendar.current.dateComponents([.minute], from: timelineStart, to: program.stop).minute ?? 0
            let minDuration = minEnd - minStart
            return CGFloat(minDuration)
        }
    
/// If showing a vertical line to indicate current time
    func getDateLine(from program: SavedProgram?, to TimeNow: Date) -> CGFloat {
        guard let program = program else { return 0 }
        let timeProgramStart =  Calendar.current.dateComponents([.minute], from: program.start, to: TimeNow).minute ?? 0
        return CGFloat(timeProgramStart) * pointsPerMinute
    }
    
/// Get width for program 1 hour is 159.96 pixels
    func getWidth(for program: SavedProgram?) -> CGFloat {
        guard let program = program else { return 0 }
        let duration = Calendar.current.dateComponents([.minute], from: program.start, to: program.stop).minute ?? 0
             return max(CGFloat(duration) * pointsPerMinute, minProgWidth)
    }

    func updateTimelineStart() {
        let calendar = Calendar.current
        timelineStart = calendar.date(
            bySettingHour: Int(startHour), minute: 0, second: 0,
            of: chosenDay) ?? Date()
    }
    
   
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.timeZone = TimeZone.current  // 👈 Ensures local time
        return formatter.string(from: date)
    } /// funcFormatted Date
} /// Class
