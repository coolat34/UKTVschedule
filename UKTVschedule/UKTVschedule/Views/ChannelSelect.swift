//
//  ChannelSelect.swift
//  UKTVschedule
//
//  Created by Chris Milne on 25/08/2025.
//
import Foundation
import SwiftUI
import SwiftData
import LightXMLParser
import XMLTV

struct Getxmldata {
    var channels: [Channel]
}

struct Channel: Identifiable {
    var id = UUID()
    var name: String
    var icon: String
    var xmltvID: String?
    var sortName: String
}

struct ChannelSelect: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var HA: Handler
    @State private var path = NavigationPath()
    @Query var savedChannels: [SavedChannel]
    @State var channels: [Channel] = []
    @State private var viewChannels = false
   
    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(channels) { channel in
                  let isSaved = savedChannels.contains { $0.name == channel.name }
                    
                    HStack(spacing: 20) {
                        Text(channel.name).foregroundColor(isSaved ?  Color.red : Color.black)
                        Spacer()
                    
                        Button(action: {
                         if !isSaved {
                                let saved = SavedChannel(name: channel.name,
                                                         icon: channel.icon,
                                                         xmltvID: channel.xmltvID ??
                                                         channel.name,
                                                         sortName: channel.sortName)
                          
                                modelContext.insert(saved)
                            }
                            else {
                              
                                // Find the saved channel to delete
                    if let savedChannel = savedChannels.first(where: { $0.name == channel.name }) {
                            modelContext.delete(savedChannel)
                                    }
                                }
                        })
                        {
                            Label("Add / Delete", systemImage: "star.slash.fill")
                                .foregroundColor(isSaved ?  Color.red : Color.gray)
                        }
                    }
                }
            } /// List
            .onAppear {
                fetchXMLTV(from: "https://raw.githubusercontent.com/dp247/Freeview-EPG/master/epg.xml")
                
            } /// onAppear
            .navigationTitle(Text("UKTV Channels (\(channels.count)) - Red means already chosen: \(savedChannels.count)"))
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("View Selection") {
                        viewChannels.toggle()
                    } ///Button
                    .buttonStyle(.borderedProminent)
                    .bold()
                    .disabled(HA.isDownloading)
                } /// toolbaritem View
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Return") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .bold()
                    
                } /// ToolbarItem

                    } /// ToolBar
            .fullScreenCover(isPresented: $viewChannels) {
                ChannelView()
            } /// fullscreencover
        } ///  NavStack
    } /// Body
    
    func fetchXMLTV(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let xmltv = try? XMLTV(data: data) else {
                print("Failed to fetch or parse XMLTV")
                return
            }
            DispatchQueue.main.async {
                let tvChannels = xmltv.getChannels()
                channels = tvChannels.map {
                    let name = $0.name ?? "Unknown"
                    return Channel(name: name,
                                   icon: $0.icon ?? "",
                                   xmltvID: $0.id,
                                   sortName: name.trimmingCharacters(in: .whitespaces))
                }
            }
        }.resume()
    }/// fetch
} /// struct


