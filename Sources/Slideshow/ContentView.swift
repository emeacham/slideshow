// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = SlideshowViewModel()
    @ObservedObject private var appState = AppState.shared
    @State private var showingSettings = false
    @State private var isDragTargeted = false

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
            }
        }
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
