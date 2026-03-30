// Slideshow — native macOS image slideshow
// Copyright (C) 2026 Ed Meacham (edmeacham.com)
// GNU General Public License v3 — see LICENSE

import SwiftUI

struct SlideshowView: View {
    @ObservedObject var viewModel: SlideshowViewModel
    @Binding var showSettings: Bool

    @State private var controlsVisible = true
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            if let url = viewModel.currentImageURL {
                AsyncImageView(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(viewModel.currentIndex)
                    .transition(viewModel.transitionType.swiftUITransition)
            }

            if controlsVisible {
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 120)
                        .allowsHitTesting(false)
                }

                VStack(spacing: 0) {
                    Spacer()
                    ControlsView(viewModel: viewModel, showSettings: $showSettings)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onContinuousHover { phase in
            switch phase {
            case .active: showControlsTemporarily()
            case .ended:  scheduleHide()
            }
        }
        .onChange(of: viewModel.isPlaying) { playing in
            if playing {
                scheduleHide()
            } else {
                hideTask?.cancel()
                withAnimation(.easeIn(duration: 0.2)) { controlsVisible = true }
            }
        }
        .onAppear { showControlsTemporarily() }
    }

    private func showControlsTemporarily() {
        hideTask?.cancel()
        withAnimation(.easeIn(duration: 0.15)) { controlsVisible = true }
        scheduleHide()
    }

    private func scheduleHide() {
        hideTask?.cancel()
        guard viewModel.isPlaying else { return }
        hideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { controlsVisible = false }
        }
    }
}
