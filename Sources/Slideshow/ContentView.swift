// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = SlideshowViewModel()
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var debugLog = DebugLog.shared
    @State private var showingSettings = false
    @State private var isDragTargeted = false
    @State private var showDebugLog = false

    var body: some View {
        ZStack {
            if viewModel.hasImages {
                SlideshowView(viewModel: viewModel, showSettings: $showingSettings)
            } else {
                WelcomeView(viewModel: viewModel, isDragTargeted: isDragTargeted)
            }

            if isDragTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
                    .background(Color.accentColor.opacity(0.08).clipShape(RoundedRectangle(cornerRadius: 12)))
                    .padding(8)
                    .allowsHitTesting(false)
            }

            if showDebugLog {
                DebugLogOverlay(debugLog: debugLog, isShowing: $showDebugLog)
            }
        }
        .frame(minWidth: 640, minHeight: 480)
        .onDrop(of: [UTType.fileURL], isTargeted: $isDragTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                guard let data,
                      let urlString = String(data: data, encoding: .utf8),
                      let url = URL(string: urlString) else { return }
                DispatchQueue.main.async { viewModel.loadURL(url) }
            }
            return true
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $appState.showingCredits) {
            CreditsView()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.selectDirectory()
                } label: {
                    Label("Open Folder", systemImage: "folder")
                }
                .keyboardShortcut("o", modifiers: .command)

                if viewModel.hasImages {
                    Button { showingSettings = true } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }

                Button { showDebugLog.toggle() } label: {
                    Label("Debug Log", systemImage: "ladybug")
                }
                .keyboardShortcut("d", modifiers: .command)
            }
        }
    }
}

struct DebugLogOverlay: View {
    @ObservedObject var debugLog: DebugLog
    @Binding var isShowing: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                HStack {
                    Text("Debug Log")
                        .font(.headline.monospaced())
                    Spacer()
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(debugLog.text, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Button("Clear") { debugLog.clear() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button { isShowing = false } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(debugLog.entries) { entry in
                                Text(entry.formatted)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(colorForCategory(entry.category))
                                    .textSelection(.enabled)
                                    .id(entry.id)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: debugLog.entries.count) { _ in
                        if let last = debugLog.entries.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(height: 220)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 10)
            .padding(12)
        }
    }

    private func colorForCategory(_ cat: String) -> Color {
        if cat.contains("ERR") { return .red }
        if cat == "WK-NAV" { return .orange }
        if cat == "JS" { return .cyan }
        if cat == "FILE" { return .yellow }
        return .primary
    }
}

struct WelcomeView: View {
    let viewModel: SlideshowViewModel
    var isDragTargeted: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isDragTargeted ? "arrow.down.circle.fill" : "photo.stack")
                .font(.system(size: 80))
                .foregroundStyle(isDragTargeted ? Color.accentColor : Color.secondary)
                .animation(.easeInOut(duration: 0.15), value: isDragTargeted)

            VStack(spacing: 8) {
                Text("Slideshow")
                    .font(.largeTitle.bold())
                Text(isDragTargeted
                     ? "Drop to load images"
                     : "Choose a folder of images to get started.")
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut(duration: 0.15), value: isDragTargeted)
            }

            Button {
                viewModel.selectDirectory()
            } label: {
                Label("Open Folder…", systemImage: "folder.badge.plus")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("o", modifiers: .command)

            Text("or drag a folder or image here")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
