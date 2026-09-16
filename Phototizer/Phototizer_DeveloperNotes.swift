//
//  Phototizer_DeveloperNotes.swift
//  Phototizer
//
//  Developer Notes — Persistent Memory for AI Assistants
//  Created: 2026 SEP 02 (Claude Code)
//

// ============================================================================
// MARK: - PROJECT IDENTITY
// ============================================================================
//
//  Name:           Phototizer
//  Bundle ID:      com.nightgard.Phototizer
//  Platform:       iOS (Universal — iPhone & iPad)
//  Version:        1.0
//  Deployment:     iOS 16.0+
//  Language:       Swift 5.0, SwiftUI
//  App Store ID:   (not submitted)
//  Status:         ✅ WORKING END TO END ON DEVICE (2026-09-02 19:29)
//  Location:       /Users/michaelfluharty/Developer.complex/Phototizer/
//  Built with:     Xcode 27.0 (27A5194q), iOS 27.0 SDK

// ============================================================================
// MARK: - WHAT IT IS
// ============================================================================
//
//  A multi-photo digitiser. Michael's words: "its a multi photo digitizer."
//
//  The subject is a STACK OF PHYSICAL PRINTS, and the point is getting through
//  the stack — shoot, shoot, shoot, and every one lands in the camera roll as
//  its own image. He asked for "the scanning experience of a PDF scanner" but
//  explicitly NOT a PDF: "i dint need it ti actually make a multi page pdf.
//  i want every page saved to the camera roll."
//
//  The multi-page capture rhythm IS the feature.

// ============================================================================
// MARK: - WHY IT IS A SEPARATE APP  (settled 2026-08-31 — do not relitigate)
// ============================================================================
//
//  It came out of friction with a shipping app, not a blank page:
//      "the published scankeeper does the workflow but the share sheet step
//       is in the way"
//
//  Snap&ScanKeeper (LIVE, com.NightGard.Snap-ScanKeeper) already scans, but it
//  hands each result to a UIActivityViewController — a destination picker for a
//  destination that never changes.
//
//  The obvious move was to patch that live app. Michael ruled otherwise:
//      "start clean they do two different functions"
//
//  His cut, and it is the right one:
//      Snap&ScanKeeper KEEPS what it scans   (OCR, retention, PDFs, albums)
//      Phototizer      DIGITISES AND LETS GO (straight to camera roll, done)
//
//  Same camera, opposite purpose. Bolting a second purpose onto a live app
//  would have muddied both.
//
//  ⛔ SNAP&SCANKEEPER IS NOT TO BE MODIFIED. Not "probably not" — not at all.

// ============================================================================
// MARK: - ARCHITECTURE
// ============================================================================
//
//  PhototizerApp.swift             — @main entry point
//  ContentView.swift               — the entire UI: one button, one status line
//  DocumentScannerView.swift       — UIViewControllerRepresentable around
//                                    VNDocumentCameraViewController; returns
//                                    [UIImage], one per captured page
//  PhotoSaver.swift                — add-only write of each image to the
//                                    camera roll
//  Phototizer_DeveloperNotes.swift — this file
//
//  There is no model layer, no persistence, and no settings screen, because
//  there is nothing to configure. That is deliberate.

// ============================================================================
// MARK: - THE DELETED STEP IS THE PRODUCT
// ============================================================================
//
//  ⛔ DO NOT REINTRODUCE A SHARE SHEET OR A DESTINATION PICKER.
//
//  The share sheet being in the way is the entire reason this app exists. Any
//  future change that adds a "where would you like to save this?" prompt has
//  undone the app. Scan, tap, it is in the camera roll.
//
//  Same reasoning rules out a save-format setting, an album chooser, and an
//  export menu. One destination, no question asked.

// ============================================================================
// MARK: - PERMISSIONS — deliberately the smallest surface that works
// ============================================================================
//
//  NSCameraUsageDescription             — the scanner itself
//  NSPhotoLibraryAddUsageDescription    — ADD-ONLY
//
//  Add-only means the app can put photographs in and can NEVER read the
//  library back. That is not a nicety; it is why the app creates no album.
//  An album requires PHAssetCollectionChangeRequest, which requires read/write
//  access to the whole library. The camera roll was what he asked for, so the
//  smaller permission is also the correct one.
//
//  ⚠️ NO LOCATION IN EXIF. PHAssetChangeRequest.creationRequestForAsset(from:)
//  writes none, and none is added. iOS's own camera-location setting stays the
//  single authority on whether a photograph carries a location.

// ============================================================================
// MARK: - ⚠️ THE MEASUREMENT THAT IS STILL OWED
// ============================================================================
//
//  VNDocumentCameraViewController is tuned for PAPER. Its processing pushes
//  contrast and it offers greyscale/black-and-white filters — correct for a
//  receipt, WRONG for a photograph, where it can crush the tones of a print.
//
//  Its filter control defaults to colour, and nothing in this app overrides
//  that. So the default is right. What has NOT been verified is whether the
//  colour path still applies document-style contrast enhancement to a
//  photographic print.
//
//  ⬜ VERIFY AGAINST A REAL PRINT before assuming VisionKit is the final
//     engine. This is a MEASUREMENT, not a decision.
//
//  Michael's ruling on when, 2026-09-02: "If we find problems in [VisionKit]
//  will come to those when we cross the bridge." So: ship on VisionKit, look
//  at real output, revisit only if the prints come back wrong.
//
//  IF IT FAILS, the fallback is AVCapturePhotoOutput + VNDetectRectanglesRequest
//  with manual perspective correction — more work, full control of the pixels.

// ============================================================================
// MARK: - 🔥 FIRST DEVICE TEST — 2026-09-02 ~19:2x, iPhone 14 Pro Max / iOS 27
// ============================================================================
//
//  ✅ VERIFIED END TO END AT 19:29 — "2 photographs saved", both written to
//  the camera roll, permission prompt showed the shipped usage string
//  verbatim, and the button correctly flipped to "Scan More".
//  Nothing was mocked and nothing was inferred: this was read off his
//  actual device screen, not claimed. -> feedback_real_world_testing_requires_chat_record
//
//  It built, installed and launched first try, and it DOES scan prints to the
//  camera roll. Three real findings came out of the first stack, all of them
//  the paper-vs-photograph difference showing up in practice:
//
//  1. ⛔ FLASH RUINS IT. He found this himself: "There ago it was a flash."
//     A photographic print is GLOSSY. The flash puts a blown hotspot on the
//     surface, which wrecks both the image and the edge detection. Documents
//     are matte, so VisionKit's defaults never had to care.
//     ⚠️ There is NO API to preset the flash on VNDocumentCameraViewController
//        — it is Apple's UI and the toggle is the user's. So today this is a
//        manual "turn the flash off" every session, which is exactly the kind
//        of step this app exists to delete.
//     ⭐ THIS IS THE STRONGEST ARGUMENT SO FAR for the AVCapturePhotoOutput
//        fallback, where flash is ours to force off permanently.
//
//  2. EDGE DETECTION NEEDS CONTRAST WITH THE SURFACE. "It's not cramping
//     [cropping] this picture it did the first one." One print cropped, the
//     next did not — the second was lying on something too close in tone for
//     VisionKit to find a border. Workaround: contrasting surface, or the
//     scanner's Auto→Manual toggle to place corners by hand.
//
//  3. SKEW. "It keeps making it skewed." Perspective correction warping the
//     print — either shot at an angle, or the wrong quadrilateral was locked
//     (a table edge or a shadow instead of the print's own edge).
//
//  ✅ 4. TONE FIDELITY — MEASURED, AND VISIONKIT PASSED. The standing worry
//     since 2026-08-31 was that document processing would crush a print's
//     tones. On a real print it did not.
//     THE TEST PRINT WAS ~30 YEARS OLD — his words: "this photograph is like
//     30 years old" — which is a harder case than a fresh print, because
//     decades-old prints usually carry a colour cast. It came back clean:
//     square crop, no border, natural sand/sky tones, and a saturated blue
//     that reproduced as blue.
//     ⚠️ Claude first read that blue as WATER; Michael corrected it to SPRAY
//        PAINT ("I guess the water is spray paint"). The correction does not
//        change the finding — arguably strengthens it, since a sprayed colour
//        surviving intact is a real colour-path result — but it is recorded
//        because his account of his own photograph outranks a read of pixels.
//        -> Skills Lab, "Photograph description"
//
//     SO: VisionKit STAYS. The AVCapturePhotoOutput fallback is no longer
//     needed for tone. The only remaining argument for it is FLASH CONTROL
//     (finding 1) — and that is a real one.

// ============================================================================
// MARK: - 📝 VOCABULARY — HIS RULE, AND IT GOVERNS ALL COPY IN THIS APP
// ============================================================================
//
//  A PRINT IS A DEVELOPED PHOTOGRAPH. His words, 2026-09-02: "print is a
//  developed photo print." It is not what a printer does.
//
//  He caught the first draft of the subtitle, which read "Prints straight to
//  your camera roll," and diagnosed it precisely:
//
//      "prints can mean print from the phone or to a printer but prints is a
//       verb and needs to be a noun because a physical photograph is refered
//       to as a print so prints needs to be singular or needs a helping word
//       before it"
//
//  He is right. Leading with a bare plural "Prints" makes the reader parse it
//  as a VERB — the app prints something — which is the opposite of what it does.
//
//  ✅ SHIPPING COPY, his fix: "Scan prints straight to your camera roll."
//     An imperative verb up front frees "prints" to be the noun it is.
//
//  RULE FOR ANY FUTURE COPY, listing text or screenshot caption: never open a
//  line with a bare "Prints". Either make it singular ("a print"), or put a
//  verb or article in front of it. Same trap applies to "Scans."

// ============================================================================
// MARK: - ⬜ OPEN QUESTIONS — HIS TO ANSWER, DO NOT DECIDE THESE
// ============================================================================
//
//  1. BORDERS. Old prints are often not rectangular on the mat — white
//     borders, rounded corners, deckle edges, Polaroid frames. Keep them or
//     crop them out? A digitiser that silently trims the white frame off a
//     1970s print is destroying part of the artifact. Currently: whatever
//     edge VisionKit detects is what you get. Not asked yet.
//
//  2. TRACK. App Store Connect, or personal deployment only?
//     See project_lighthouse_two_tracks_personal_vs_asc.
//
//  3. NAME CHECK. "Phototizer" is his coinage, confirmed for use 2026-09-02.
//     ⬜ HE still needs to search the App Store for collisions — Claude
//        cannot reach ASC, and Apple is the source of truth.

// ============================================================================
// MARK: - DEPLOYMENT TARGET — 16 NOW, 27 LATER, ON PURPOSE
// ============================================================================
//
//  iOS 16.0 is the real floor: VNDocumentCameraViewController is iOS 13, and
//  add-only Photos authorisation is iOS 14. Nothing in this app is newer, and
//  16 is a floor he has already proven — it is what Snap&ScanKeeper ships.
//
//  His plan, 2026-09-02: "We just have to have 16 for when we submitted it
//  after we upgraded or do any additions we're gonna move it up to 27."
//  So 16 gets it submitted; the move to 27 comes with the first feature work.

// ============================================================================
// MARK: - STANDING RULES THAT ALREADY APPLY  (so nobody re-asks)
// ============================================================================
//
//  - ⚠️ NEVER name anything here "Claude". Every Claude-named app in the
//    account was taken down under App Store Guideline 4.1a.
//  - English-only, Americas-only distribution.
//  - Shipped user-facing text is second person. No personal names in it.
//  - Light and dark app icons only — never tinted, never auto-generated.
//  - No bundled audio, no third-party IP in screenshots.

// ============================================================================
// MARK: - 1.0 SUBMITTED 2026-09-16 09:07 — AND WHAT IT SHIPPED WITHOUT, ON PURPOSE
// ============================================================================
//
//  1.0 (5), App Apple ID 6812775746, Photo & Video / Productivity. Support page
//  https://fluharty.me/phototizer-support.html.
//
//  ⚠️ NO (i) / ABOUT SCREEN AND NO BUILD NUMBER ON SCREEN. His call, knowingly:
//      "i looked and phototizer doesnt have an (i) either so no where to put
//       contact information, i figured it should be ultra basic so i didnt push
//       for that or the build number, its kinda too late now anyway"
//  The build-number rule (every build shows its commit count) is NOT met by 1.0.
//  ⬜ Next build: add an (i) with version, build number, build time and the
//     support contact — ask him first, since the minimal UI was deliberate.

// ============================================================================
// MARK: - HISTORY
// ============================================================================
//
//  2026-08-31 ~21:45  Idea captured at bedtime.
//  2026-08-31 ~21:55  Ruled a separate app: "start clean they do two
//                     different functions."
//  2026-08-31 ~22:00  Scope sharpened: "its a multi photo digitizer."
//  2026-08-31 ~22:05  Name coined: "photo digitizer phototizer?"
//  2026-09-02 ~19:01  Session crashed mid-request while pulling the idea up.
//  2026-09-02 ~19:1x  Name confirmed, iOS 16 set, project scaffolded.
//                     Built MOSTLY by voice dictation. His correction:
//                     "Well mostly voice I did kind of type the really
//                     long sentences out." The typed parts were the ones
//                     needing exact wording — chiefly the grammar
//                     explanation of why "Prints" read as a verb.
