//
//  DocumentScannerView.swift
//  Phototizer
//
//  Created by Michael Fluharty on 2026 SEP 02.
//

import SwiftUI
import VisionKit

/// Wraps VisionKit's document camera. It supplies the whole capture rhythm —
/// edge detection, perspective correction, shoot-the-next-one, retake — and
/// hands back one image per page it captured.
///
/// The scanner's own filter control defaults to colour, which is what a
/// photographic print needs. Nothing here overrides it.
struct DocumentScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    /// Called with one image per captured page, in capture order.
    let onFinish: ([UIImage]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {
        // Nothing to update — the scanner owns its own state.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var images: [UIImage] = []
            images.reserveCapacity(scan.pageCount)
            for page in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: page))
            }
            parent.onFinish(images)
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
            parent.dismiss()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.onFinish([])
            parent.dismiss()
        }
    }
}
