//  ProgramView.swift
//  UKTVschedule
//
//  Created by Chris Milne on 27/08/2025.

import SwiftUI
import SwiftData

struct ProgramView: View {  /// Display the Channel details
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var HA: Handler
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedProgram: SavedProgram?
    @State private var isShowingDetails = false
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.current  // 👈 Ensures local time
        return formatter.string(from: HA.chosenDay)
    }
    var timeSlots: [Date] { HA.generateTimeSlots() } /// Returns 48 half-hour slots
    @Query var savedChannels: [SavedChannel]
    @Query var savedPrograms: [SavedProgram]
    var channels: [String] { savedChannels.map { $0.sortName}}
    var channelCount: Int { savedChannels.count }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

// MARK: Display Banner - horizontal scroll only. No vertcial
                ScrollView(.horizontal, showsIndicators: false) {
                    BannerLineView()
                        .frame(height: HA.rowHeight)
   //             }
 
// MARK: Channels + Programs - vertical scroll
                ScrollView(.vertical) {
                    ScrollViewReader { proxy in
                        HStack(alignment: .top, spacing: 0) {
                            
                            // MARK: Channel column - vertical scroll only
                            LazyVStack(spacing: 0) {
                                
                                ForEach(channels.indices, id: \.self) { index in
                                    Text(channels[index])
                                        .frame(width: HA.channelColumnWidth, height: HA.rowHeight, alignment: .leading)
                                        .padding(.leading, 8)   /// 200  x 60
                                        .background(index.isMultiple(of: 2) ? Color(.systemGray6) : Color.white)
                                } /// For Each
                            } /// LazyStack
                            .frame(width: HA.channelColumnWidth)
                            
                            .id("channelColumn")
                            
// MARK: Program grid - horizontal + vertical scroll
                ScrollView(.horizontal, showsIndicators: true) {
                    ZStack {
                        ForEach(channels.indices, id: \.self) { index in
                            ProgramRowView(
                                channel: channels[index],
                                index: index,
                                timeSlots: timeSlots,
                                savedPrograms: savedPrograms,
                                selectedProgram: $selectedProgram
                            )  /// ProgramRowView
                        } /// forEach
                    } /// ZStack
                    .frame(height: CGFloat(channels.count) * HA.rowHeight)
                    .id("programGrid")
                } /// ScrollView horizontal
            } /// temp
                .onAppear {
                    proxy.scrollTo("programGrid", anchor: .leading)
                }  /// onAppear
            } /// HStack
        } /// ScrollReader proxy
    } /// ScrollView vertcial
}   /// VStack
            
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Programs for \(shortDate) Beginning at \(Int(HA.startHour)):00")
                        .font(.headline)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Return") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .bold()
                } /// toolbarItem
            } /// toolbar
        }   /// NavView
        .sheet(item: $selectedProgram) { program in
            DetailView(program: program, HA: _HA)
        } /// .sheet Item
    } /// body
 
    
} /// struct
    
struct ProgramRowView: View {
    let channel: String
    let index: Int
    let timeSlots: [Date]
    let savedPrograms: [SavedProgram]
    @Binding var selectedProgram: SavedProgram?
    @EnvironmentObject var HA: Handler
      var body: some View {
        ForEach(timeSlots, id: \.self) { slot in    /// Every half-hour

            let matches = getMatches(for: slot, channel: channel)
            let program = matches.first
                CellView(
                    channel: channel,
                    program: program,
                    channelIndex: index
                )
                
                .onTapGesture {
                    selectedProgram = program
            }
        }
    } /// body
    func getMatches(for slot: Date, channel: String) -> [SavedProgram] {
        let matches = savedPrograms.filter {
            $0.channelName == channel
            &&
            abs($0.start.timeIntervalSince(slot)) < 1200 //  ± 15 mins before end of day
        } /// let
        return matches
        }
    } /// struct
    
    struct CellView: View {
        @EnvironmentObject var HA: Handler
        let channel: String
        let program: SavedProgram?
        let channelIndex: Int
        
        var body: some View {
            let x = HA.getXPosition(for: program)
            let progWidth = HA.getWidth(for: program)
            let y = CGFloat(channelIndex) * HA.rowHeight // for stacking channels vertically
            
            ZStack(alignment: .leading) {
                if let program = program {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(program.title ?? "Untitled")
                            .font(.caption)
                            .lineLimit(2)
                            .truncationMode(.tail)
                        
                        Text(program.start.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .bold(true)
                    } /// VStack
                    .padding(3)
                    .frame(width: progWidth, alignment: .leading)
                    .background(channelIndex.isMultiple(of: 2) ? Color(.systemGray6) : Color .white)
                    .cornerRadius(1)
                } /// if let

                /// ⏱️ Current time indicator
                if let program = program {
                 let timeLine = HA.getDateLine(from: program, to: Date())
                 Rectangle()
                        .fill(Color.red.opacity(0.1))
                 .frame(width: 2, height: HA.rowHeight)
                 .offset(x: timeLine)
                 }

            } /// ZStack
//MARK: print values below
            .position(x: x + (progWidth / 2), y: y + HA.rowHeight / 2)
            
        }  /// body
        
    } /// struct
    
    struct DetailView: View {
        let program: SavedProgram
        @Environment(\.dismiss) var dismiss
        @EnvironmentObject var HA: Handler
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(program.title ?? "Untitled")
                    .font(.title2)
                    .bold()
                HStack {
                    Text("Start Time: \(program.start.formatted(date: .omitted, time: .shortened))")
                    Text(" Stop Time: \(program.stop.formatted(date: .omitted, time: .shortened))")
                } /// HStack
                if let episode = program.episode, !episode.isEmpty {
                    let parts = episode.split(separator: ".").compactMap { Int($0) }
                    if parts.count >= 2 {
                        let season = parts[0] + 1
                        let episode = parts[1] + 1
                        let part = parts.count > 2 ? parts[2] + 1 : nil
                        
                        Text("Season \(season), Episode \(episode)\(part != nil ? ", Part \(part!)" : "")")
                    }
                } /// if let episode
                
                if let desc = program.desc, !desc.isEmpty {
                    Text(desc)
                        .padding(.top)
                } /// if let desc
                
                Spacer()
            } /// VStack
            .padding()
            .presentationDetents([.medium]) // 👈 Shrinks the sheet
        } /// Body
    } /// Struct
 
    
struct BannerLineView: View {
    let bannerLine = Array(0...25)
    @EnvironmentObject var HA: Handler
    var body: some View {
        let startTime = Int(HA.startHour)
            HStack(spacing: 0) {
                ForEach(startTime ..< bannerLine.count, id: \.self) { i in
                 Text(String(format: "%02d:00", (bannerLine[i] == 25 ? 0 : bannerLine[i])))
                    .frame(width: HA.hourWidth, height: HA.rowHeight * 0.5, alignment: .leading)
                    .foregroundColor(.white)
                    .background(Color.gray.opacity(0.9))
                    .font(.caption)
                    .bold()
            } /// For i
                    .offset(x: HA.channelColumnWidth)  /// Indent start
            
        } /// HSTack
    } /// Body
}  /// Struct BannerRowView
