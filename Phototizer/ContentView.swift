//
//  ContentView.swift
//  Phototizer
//
//  Created by Michael Fluharty on 2026 SEP 02.
//

import SwiftUI

struct ContentView: View {

    private enum Outcome: Equatable {
        case waiting
        case saving(Int)
        case saved(Int)
        case failed(String)
        case permissionNeeded
    }

    @State private var isScanning = false
    @State private var outcome: Outcome = .waiting

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Phototizer")
                    .font(.largeTitle.weight(.semibold))
                Text("Scan prints straight to your camera roll.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            statusView
                .frame(minHeight: 76)
                .padding(.horizontal)

            Spacer()

            Button {
                outcome = .waiting
                isScanning = true
            } label: {
                Label(scanButtonTitle, systemImage: "camera.viewfinder")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSaving)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding()
        .fullScreenCover(isPresented: $isScanning) {
            DocumentScannerView(
                onFinish: { images in save(images) },
                onCancel: { }
            )
            .ignoresSafeArea()
        }
    }

    private var scanButtonTitle: String {
        if case .saved = outcome { return "Scan More" }
        return "Scan Photos"
    }

    private var isSaving: Bool {
        if case .saving = outcome { return true }
        return false
    }

    @ViewBuilder
    private var statusView: some View {
        switch outcome {
        case .waiting:
            Text("Point at a print. Shoot as many as you like — every one lands in your camera roll.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

        case .saving(let total):
            VStack(spacing: 12) {
                ProgressView()
                Text(total == 1 ? "Saving 1 photograph…" : "Saving \(total) photographs…")
                    .font(.title3)
            }

        case .saved(let count):
            Label(
                count == 1 ? "1 photograph saved" : "\(count) photographs saved",
                systemImage: "checkmark.circle.fill"
            )
            .font(.title2.weight(.medium))
            .foregroundStyle(.green)

        case .permissionNeeded:
            VStack(spacing: 12) {
                Text("Phototizer needs permission to add photographs to your library.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.title3.weight(.semibold))
            }

        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.body)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }

    private func save(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        outcome = .saving(images.count)

        Task {
            do {
                let written = try await PhotoSaver.save(images)
                outcome = .saved(written)
            } catch PhotoSaver.Failure.permissionDenied {
                outcome = .permissionNeeded
            } catch {
                outcome = .failed(error.localizedDescription)
            }
        }
    }
}

#Preview {
    ContentView()
}
