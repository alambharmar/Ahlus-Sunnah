//
//  TasbeehView_macOS.swift
//  WaslApp
//
//  macOS-native Tasbeeh interface - Clean, elegant, Apple-style design
//

import SwiftUI

#if os(macOS)

struct TasbeehView_macOS: View {
    @StateObject var manager = TasbeehManager()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedZikrID: UUID? = nil
    @State private var showingResetAllAlert = false
    
    var body: some View {
        HSplitView {
            // MARK: - Left Sidebar (Zikr List)
            ZikrListSidebar(
                manager: manager,
                selectedZikrID: $selectedZikrID
            )
            .frame(minWidth: 180, idealWidth: 210, maxWidth: 240)

            // MARK: - Right Detail View
            if let selectedID = selectedZikrID,
               let index = manager.zikrList.firstIndex(where: { $0.id == selectedID }) {
                ScrollView {
                    ZikrDetailPane(
                        zikr: $manager.zikrList[index]
                    )
                    .frame(minWidth: 260, idealWidth: 320)
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Select a Zikr")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Choose a zikr from the list to begin counting")
                        .font(.body)
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Tasbeeh")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    showingResetAllAlert = true
                }) {
                    Label("Reset All", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .alert("Reset All Counters?", isPresented: $showingResetAllAlert) {
            Button("Reset All", role: .destructive) {
                manager.resetAllCounts()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset the count for all Zikr items to zero.")
        }
        .onAppear {
            // Select first zikr by default
            if selectedZikrID == nil, let firstZikr = manager.zikrList.first {
                selectedZikrID = firstZikr.id
            }
        }
    }
}

// MARK: - Zikr List Sidebar
struct ZikrListSidebar: View {
    @ObservedObject var manager: TasbeehManager
    @Binding var selectedZikrID: UUID?
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        List(selection: $selectedZikrID) {
            ForEach($manager.zikrList) { $zikr in
                ZikrListRow(zikr: zikr)
                    .tag(zikr.id)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Zikr List Row
struct ZikrListRow: View {
    let zikr: ZikrItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(zikr.transliteration)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            HStack(spacing: 4) {
                Text("\(zikr.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(zikr.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Zikr Detail Pane
struct ZikrDetailPane: View {
    @Binding var zikr: ZikrItem
    @EnvironmentObject var themeManager: ThemeManager
    
    // For now, use a fixed target of 100, or create a custom target system later
    private let defaultTarget = 100
    
    var progress: Double {
        let target = zikr.targetCount ?? defaultTarget
        guard target > 0 else { return 0 }
        return min(Double(zikr.count) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Section (Arabic Text & Progress)
            VStack(spacing: 16) {
                // Arabic Text
                Text(zikr.arabic)
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Transliteration
                Text(zikr.transliteration)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // Translation
                Text(zikr.translation)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Benefit (if available)
                if let benefit = zikr.benefit {
                    Text(benefit)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .italic()
                        .padding(.horizontal, 24)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            Spacer(minLength: 12)

            // MARK: - Counter Circle (Main interaction area)
            ZStack {
                // Progress Ring
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        themeManager.accentColorManager.accentColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)

                // Counter Button
                Button(action: {
                    zikr.count += 1
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                }) {
                    VStack(spacing: 6) {
                        Text("\(zikr.count)")
                            .font(.system(size: 48, weight: .light, design: .rounded))
                            .foregroundColor(.primary)
                            .contentTransition(.numericText())

                        if let target = zikr.targetCount {
                            Text("of \(target)")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                        } else {
                            Text("tap to count")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(width: 170, height: 170)
                .background(
                    Circle()
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                )
                .overlay(
                    Circle()
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
            }
            .padding(.bottom, 20)

            // MARK: - Bottom Controls
            HStack(spacing: 12) {
                Button(action: {
                    zikr.count = 0
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                }) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(zikr.count == 0)

                Button(action: {
                    if let target = zikr.targetCount {
                        zikr.count = min(zikr.count + 10, target)
                    } else {
                        zikr.count += 10
                    }
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                }) {
                    Label("+10", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(zikr.accentColor)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#endif
