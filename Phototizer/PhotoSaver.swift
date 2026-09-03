//
//  PhotoSaver.swift
//  Phototizer
//
//  Created by Michael Fluharty on 2026 SEP 02.
//

import UIKit
import Photos

/// Writes captured pages straight to the camera roll.
///
/// Add-only authorisation on purpose: the app can put photographs in and can
/// never read the library back. That is the whole permission surface.
///
/// No album is created. An album would require read/write access to the whole
/// library, and the camera roll was the destination asked for.
///
/// No location is attached. `creationRequestForAsset(from:)` writes no location
/// of its own, and none is added here — the system camera setting stays the
/// single authority on whether a photograph carries a location.
enum PhotoSaver {

    enum Failure: LocalizedError {
        case permissionDenied
        case writeFailed(Error)

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Phototizer needs permission to add photographs to your library. Turn it on in Settings, under Phototizer."
            case .writeFailed(let underlying):
                return "A photograph could not be saved: \(underlying.localizedDescription)"
            }
        }
    }

    /// Saves every image to the camera roll. Returns how many were written.
    static func save(_ images: [UIImage]) async throws -> Int {
        guard !images.isEmpty else { return 0 }
        try await requestAddOnlyAccess()

        var written = 0
        for image in images {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                written += 1
            } catch {
                throw Failure.writeFailed(error)
            }
        }
        return written
    }

    private static func requestAddOnlyAccess() async throws {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            return
        case .notDetermined:
            let granted = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard granted == .authorized || granted == .limited else {
                throw Failure.permissionDenied
            }
        default:
            throw Failure.permissionDenied
        }
    }
}
