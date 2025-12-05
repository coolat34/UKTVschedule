//
//  ChannelView.swift
//  UKTVschedule
//
//  Created by Chris Milne on 25/08/2025.

import Foundation
import SwiftUI
import SwiftData
import LightXMLParser
import XMLTV
// MARK: Displays the header and calls the List of channels and Pickers for Day and Start Hour
struct ChannelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State var path = [SavedChannel]()
    @AppStorage("startHour") private var storedStartHour: Double = 9.0
    @EnvironmentObject var HA: Handler
    @Query(sort: [SortDescriptor(\SavedProgram.start, order: .forward)]) var savedPrograms: [SavedProgram]
    
    @State private var isViewing = false
    @Query var savedChannels: [SavedChannel]
    var channels: [String] { savedChannels.map { $0.sortName}}
    // MARK: View all chosen channels
    var body: some View {
        NavigationStack(path: $path) {
        GeometryReader { geo in
            HStack(spacing: 0) {
                List {
                    ForEach(channels.indices, id: \.self) { index in
                        Text(channels[index])
                        .frame(width: HA.channelColumnWidth, height: HA.rowHeight * 0.5, alignment: .leading)
                        .padding(.leading, 8)
                        .background(index.isMultiple(of: 2) ? Color(.systemGray6) : Color.white)
                    } /// ForEach
                } /// List
                        .frame(width: HA.channelColumnWidth + 20) 
                        .listStyle(PlainListStyle()) /// removes default padding

                Divider()
                VStack(spacing: 12) {
                    
                    DayPickerView()
                    StartHourPicker()
                } /// VStack
                .padding(.bottom)
                .background(Color(.systemGroupedBackground))
                .frame(maxWidth: .infinity)  /// Takes up remaining space
                 } /// HStack
               
            .frame(width: geo.size.width, height: geo.size.height)
          } /// Geo. geo.size.width * 0.25 gives it a quater of the screen
         
        .navigationTitle("Favourite Channels for Today or Tomorrow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Return") {
                        dismiss()
                    }
                    .bold()
                    .buttonStyle(.borderedProminent)
                } /// ToolbarItem
                
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("View Programs") {
                        isViewing.toggle()
                    } ///Button
                    .buttonStyle(.borderedProminent)
                    .bold()
                    .disabled(HA.isDownloading)
                }
            } /// toolbar

            .fullScreenCover(isPresented: $isViewing) {
                ProgramView()
            }
        } ///  NavView
        .navigationBarBackButtonHidden(true)

        .onAppear {
            HA.startHour = storedStartHour
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MM-yyyy"
            formatter.timeZone = TimeZone.current  // 👈 Ensures local time
        }
    } /// Body
} /// struct ChannelView


struct DayPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var HA: Handler
    @Query var savedChannels: [SavedChannel]
    var daySelection: [String] = ["Today", "Tomorrow"]
    @State var daySelected: String = "Today"

    var body: some View {
       
        let dateString = DateforDaySelection(for: HA.chosenDay)
        VStack(spacing: 12) {
            Text("Select Day to View. Currently \(dateString)")
                .font(.headline)
            Picker("ChosenDay", selection: $daySelected) {
                ForEach(daySelection, id: \.self) { Text($0) }
            } /// Picker
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 300)
            .onChange(of: daySelected) {
                
                HA.selectedDate = programDay(for: daySelected) // Returns Date for Today / Tomorrow
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
                formatter.timeZone = TimeZone(identifier: "Europe/London")
                HA.chosenDay = HA.selectedDate
                if shouldDownload(for: HA.chosenDay) {
                    downloadProgs(for: HA.chosenDay)
                    
                } /// If
            } /// onChange
            .onAppear {
               HA.selectedDate = programDay(for: daySelected) // Date for Today / Tomorrow
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
                formatter.timeZone = TimeZone(identifier: "Europe/London")
                    if shouldDownload(for: HA.selectedDate) {
                    downloadProgs(for: HA.selectedDate)
                    
                } /// If
            }
        }
    } /// Body

    func DateforDaySelection(for chosenDay: Date) -> String {  /// convert date to Today/Tomorrow
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        switch chosenDay {
        case calendar.startOfDay(for: Date()):
            return "Today"
        case calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!:
            return "Tomorrow"
        default:
            return "Today"
        }
    }
    func programDay(for label: String) -> Date {
        let calendar = Calendar.london
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)

        switch label {
        case "Today":
            return calendar.date(from: components)!
        case "Tomorrow":
            var tomorrowComponents = components
            tomorrowComponents.day! += 1
            return calendar.date(from: tomorrowComponents)!
        default:
            return calendar.date(from: components)!
        }
    }

//MARK: Check if programs should download
    func shouldDownload(for selectedDate: Date) -> Bool {
        let calendar = Calendar.current
        let request = FetchDescriptor<SavedProgram>(predicate: nil, sortBy: [SortDescriptor(\.start, order: .forward)])

        do {
            let programs = try modelContext.fetch(request)
            guard let first = programs.first else {
                return true // No programs at all — definitely need to download
            }

            let firstDate = calendar.startOfDay(for: first.start)
            let selectedDay = calendar.startOfDay(for: selectedDate)

            return !calendar.isDate(firstDate, inSameDayAs: selectedDay)
        } catch {
            print("❌ Failed to fetch programs: \(error)")
            return true
        }
    }

//MARK: Download progs for selected Day and selected channels
    func downloadProgs(for selectedDate: Date) {
        let chosenDate = Calendar.london.startOfDay(for: selectedDate)
        guard let url = URL(string: "https://raw.githubusercontent.com/dp247/Freeview-EPG/master/epg.xml") else {
            print("Invalid URL")
            return
        }
        HA.isDownloading = true
///  URLSession runs in the background asynchronously
        URLSession.shared.dataTask(with: url) {
                data, _, error in
                guard let data = data, error == nil,
                  let xmltv = try? XMLTV(data: data) else {
                print("Failed to fetch or parse XMLTV")
                return
            }

            /// DispatchQueue.main.async ensures SwiftData insertions happen on the main thread.
            DispatchQueue.main.async {
                HA.isDownloading = false
                let request = FetchDescriptor<SavedProgram>()
                do {
                    let existingPrograms = try modelContext.fetch(request)
                    for program in existingPrograms { modelContext.delete(program) }
                } catch {
                    print("❌ Failed to fetch existing programs: \(error)")
                }
                for channel in savedChannels {
                    let tvChannel = TVChannel(
                        id: channel.xmltvID,
                        name: channel.name,
                        icon: channel.icon
                    )
                    let programs = xmltv.getPrograms(channel: tvChannel)
                    var insertedCount = 0
                        for program in programs {
                            guard let start = program.start,
                            Calendar.london.isDate(start, inSameDayAs: chosenDate)
                            else { continue }
                            let progDuration = program.stop?.timeIntervalSince(start) ?? 0
                            guard progDuration > HA.minProgDuration else { continue } 
                            insertedCount += 1
                            let saved = SavedProgram(
                                start: start,
                                stop: program.stop ?? start.addingTimeInterval(3600),
                                channel: channel.xmltvID,
                                channelName: channel.name,
                                title: program.title ?? "No Title",
                                desc: program.description,
                                date: program.date ?? "",
                                episode: program.episode,
                                icon: program.icon
                            )
                            modelContext.insert(saved)
                        } /// for program in programs
             } ///  for channel in channels

            } /// 2
        } /// 1
        .resume()
    } /// func downloadProgs
    
} /// structDayPickerView

extension Calendar {
    static var london: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        return cal
    }
}

//MARK:
struct StartHourPicker: View {
    let pickerHours = Array(0...23)
   @AppStorage("startHour") private var storedStartHour: Double = 9.0
    @EnvironmentObject var HA: Handler
    var body: some View {
            VStack(spacing: 8) {
                Text("Change your Start Time. Currently set to \(Int(HA.startHour))")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(pickerHours, id: \.self) { hour in
                            Button(action: {
                                storedStartHour = Double(hour)
                                HA.startHour = Double(hour)
                            }) {
                                Text(String(format: "%02d:00", hour))
                                    .font(.caption)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .foregroundStyle(HA.startHour == Double(hour) ? Color.black : Color.blue)
                                    .background(
                                        HA.startHour == Double(hour) ? Color.white : Color.blue.opacity(0.1))
                                    .bold(hour == Int(HA.startHour))
                                    
                                    .cornerRadius(6)
                            } /// Button Text
                        } /// ForEach
                    } /// HStack
                } /// ScrollView
                .padding(.horizontal)
            } /// VStack
            .frame(maxHeight: 80)
        } /// Body
} /// struct StartHourPicker

//MARK:



struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
       ChannelView().environmentObject(Handler())
    }
} /// struct preview

