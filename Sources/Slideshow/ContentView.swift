// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SlideshowViewModel()
    @ObservedObject private var appState = AppState.shared
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            if viewModel.hasImages {
                SlideshowView(viewModel: viewModel, showSettings: $showingSettings)
            } else {
                WelcomeView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 640, minHeight: 480)
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
            }
        }
    }
}

struct WelcomeView: View {
    let viewModel: SlideshowViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.stack")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Slideshow")
                    .font(.largeTitle.bold())
                Text("Choose a folder of images to get started.")
                    .foregroundStyle(.secondary)
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
