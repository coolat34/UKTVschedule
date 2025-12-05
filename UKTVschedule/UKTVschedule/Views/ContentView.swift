//
//  ContentView.swift
//  UKTVschedule
//
//  Created by Chris Milne on 25/08/2025.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var HA: Handler
    @Environment(\.modelContext) var modelContext
    @State private var tabIndex: Int? = nil

    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(red: 0.35, green: 0.05, blue: 0.15), Color(red: 0.15, green: 0.25, blue: 0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 5) {
                    headerSection
                    ForEach(HA.tabBarDataList.indices, id: \.self) { idx in
                        let tabIndex = idx
                        NavigationLink(
                            destination: destinationView(idx),
                            label: {
                                ZStack {
                                    // Card background with gradient
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: HA.tabBarDataList[idx].gradientColors,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: HA.tabBarDataList[idx].gradientColors[0].opacity(0.4), radius: tabIndex == idx ? 15 : 8, x: 0, y: 5)
                                    
                                    // Glossy overlay
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [.white.opacity(0.2), .clear],
                                                startPoint: .topLeading,
                                                endPoint: .center
                                            )
                                        )
                                    
                                    HStack(spacing: 15) {
                                        //MARK:  Left side - Info
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(HA.tabBarDataList[idx].lable)
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            
                                        } /// VStack
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 5)
                                        
                                        Spacer()
                                        
                                    } /// HStack
                                    .padding(20)
                                    
                                } /// ZStack
                                .frame(height: 110)
                                .scaleEffect(tabIndex == idx ? 0.98 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tabIndex)
                            } /// lable
                            //         .buttonStyle(PlainButtonStyle())
                        )   /// NavLink
                    } /// For Each
                    .padding(.top, 15)
                } /// VStack 1
            } /// ZStack
            .toolbar(.hidden, for: .navigationBar)
        } /// NavView
        .navigationViewStyle(StackNavigationViewStyle())
    } /// Body
    
   
    
    // Break into computed properties
    var headerSection: some View {
        VStack(spacing: 15) {
            // Main title with glow effect
            
            VStack(spacing: 5) {
                Text("UKTVschedule\n")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, Color(red: 1.0, green: 0.9, blue: 0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.5), radius: 10, x: 0, y: 0)
                
                Text(" Pick one of the options below.\n\n (1) Choose Channels & View Selection\n\n (2) View Channels & Programs\n")
                
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(" Then either delete unwanted channels or View the programs for your favourites.\n\n You may also choose a preferred start time. 00:00 to 24:00\n\n and select a preferred viewing day. Today or Tomorrow\n\n")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                
            }
            .padding(.horizontal)
        }
    } /// var Header
    
    func destinationView(_ tabIndex: Int) -> some View {
        switch tabIndex {
        case 0: return AnyView(ChannelSelect())
        case 1: return AnyView(ChannelView())
        default: return AnyView(EmptyView())
        } /// func
    } /// Switch
}  /// Struct



