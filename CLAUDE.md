# Project: iOS Photo Cleaner

You are building an iOS native app in Swift/SwiftUI using PhotoKit.
The canonical product spec is `photo-organizer-prd-v1.md` at the repo root — read it when scope questions arise.

## Product goal
A local-first, manual photo organizer that wraps the system Photos app with a focused review-and-organize workflow. Users review videos and screenshots, recover storage via Largest First, inspect source/version history, and manage items through explicit keep/delete/favorite actions. No cloud backend, no AI, no auto-delete, no social features.

## Scope by priority

### P0 — Must ship
- **Unsorted Videos** — filter to `PHAssetMediaType.video`, playable inline in review.
- **Unsorted Screenshots** — filter to screenshot media subtype.
- **Largest First** — videos first, sorted by file size descending. Show file size on cards.
- **Review actions** — Delete, Keep, Favorite, Undo. All via explicit buttons.
- **Left/right swipe** — navigate previous/next item only. Do NOT use swipes for keep/delete.
- **Video playback** — inline AVPlayer in review. Loading state while preparing. Never static thumbnail for videos.
- **Kept for Later** — temporary local bucket. One-tap "Return to Unsorted" action.
- **Source / Version panel** — swipe-up or toggle to reveal (not a separate screen). Shows version stage picker, notes field, and read-only metadata (date, type, size, source, resolution). Supports manual tagging. Missing data shows "Unknown."

### P1 — Important, follow after P0
- Auto-detect "Saved from" metadata when available from PhotoKit.
- Manual source/version tagging UI polish.
- Video progress bar with scrubbing isolated from card navigation gestures.
- Bottom-sheet or pull-up panel presentation for source/version.

### P2 — Later
- Capacity stats dashboard.
- Version history linking across assets.
- Pre-fetching and lazy-loading performance optimization.
- Batch operations.

### Explicitly excluded from current scope
- **Sort to album** — removed to keep stability. Do not build or extend album-sorting features.
- **On This Day** — complete and frozen. Do not touch unless blocked by a bug.
- **Random mode** — not in current scope.
- AI photo cleanup, cloud backup, login/accounts, social sharing, face recognition, content classification, cross-device sync, Lightroom integration.

## Core modes (P0)

### Unsorted Videos
- Filter unsorted media to `PHAssetMediaType.video` only.
- Sort by creation date descending (newest first).
- Entry point for tackling large video files first.

### Unsorted Screenshots
- Filter unsorted media to `PHAssetMediaSubtype.photoScreenshot` only.
- Sort by creation date descending.
- Quick cleanup for screenshot buildup.

### Largest First
- Videos first, then photos, sorted by file size descending.
- Use `PHAssetResource` for file size (may be estimated for iCloud assets — label accordingly).
- Capacity-focused entry point.

### Kept for Later
- "Keep" action moves items into this temporary local bucket (stored in `AssetStore.keptForLaterIDs`).
- User can review kept items and one-tap return them to Unsorted.
- Not a final destination — a staging area.

## Review actions
- **Delete** — moves to in-app trash (`AssetStore.trashedIDs`). User must confirm permanent deletion in TrashView.
- **Keep** — moves to Kept for Later bucket (`AssetStore.keptForLaterIDs`).
- **Favorite** — marks the PHAsset as favorite via PhotoKit write.
- **Undo** — restores the previous action (single-level, up to 20 in stack).
- All actions use explicit buttons in the action bar. Do NOT use swipe gestures for keep/delete.

## Gestures
- **Left/right swipe** — navigate to previous/next item (like system Photos app).
- **Swipe up** — open the source/version detail panel.
- Gestures must not conflict with video playback controls or scrubbing.

## Source / Version panel
- Swipe-up or toggle to reveal an overlay/panel (not a separate navigation screen).
- Editable: version stage picker (`VersionStage` enum), free-text notes field.
- Read-only metadata: date, media type, file size, PHAsset source type, pixel resolution, subtype tags.
- Persisted per-asset via `UserDefaults` keyed by `localIdentifier`.
- Missing data shows "Unknown" or "Not tagged."

## Video playback
- Videos play inline in the review card via AVPlayer / AVPlayerViewController.
- Request `PHImageManager.requestPlayerItem(forVideo:options:resultHandler:)`.
- Show loading indicator while player item prepares.
- Show clear fallback (error icon + "Unable to play") on failure.
- Never display a video asset as a static thumbnail in review mode.

## File size convention
- File sizes stored as `Int64` bytes.
- `formattedFileSize` formats to KB or MB (threshold 1,000,000 bytes).
- Estimated sizes (from iCloud assets) prefixed with `~`.

## UI rules
- Show media type early and clearly: photo, video, screenshot, or other.
- Show local/iCloud status clearly if available.
- Show file size when available. Label estimated sizes.
- Favor explicit buttons over hidden actions.
- Favor clarity over clever gestures.
- Favor stable navigation over fancy interactions.
- Keep the UI simple and native. Prefer Apple HIG.

## Technical rules
- Swift + SwiftUI + PhotoKit.
- Local-first only. No backend. No AI.
- No extra dependencies unless necessary.
- Prefer minimal safe changes over large rewrites.
- Reuse existing views if possible.
- Keep code modular and easy to extend.

## Workflow
- Before coding, explain your plan briefly.
- Identify which files/components will need changes.
- Make the smallest reliable change first.
- Batch related edits together.
- Work autonomously and continue until the task is complete.
- Only stop to ask if something is truly blocking.
- After each milestone, summarize: what changed, how to test it, known limitations, useful follow-ups.
- Do not expand scope without asking.
- If an instruction conflicts with a better product decision, explain why before changing direction.
