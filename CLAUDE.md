# Project: iOS Photo Organizer MVP

You are building an iOS native app in Swift/SwiftUI using PhotoKit.

## Product goal
Build a local-first, manual photo organizer for iPhone Photos.
No cloud backend, no AI, no auto-delete, no social features.
The app helps users review memories, inspect source/version history, and manage videos and screenshots in a focused workflow.

## Core modes

### On This Day (complete — do not touch unless blocked by a bug)
- Show media from the same month/day across previous years.
- Includes photos, videos, screenshots, and other media.
- Group by year sections (last year, two years ago, three years ago, etc.).
- Uses `PHAsset.creationDate` as the date source.

### Unsorted Videos
- Filter unsorted media to `PHAssetMediaType.video` only.

### Unsorted Screenshots
- Filter unsorted media to screenshots only.

### Largest First
- Prioritize videos first, then sort by file size descending.
- A capacity-focused cleanup entry point.

### Kept for Later
- Keep moves items into a temporary local bucket.
- User can one-tap move items back to Unsorted.

## Review actions
- **Delete** — moves to in-app trash first.
- **Keep** — moves to Kept for Later bucket.
- **Favorite** — marks the item as favorite.
- **Sort to album** — sorts item into a PhotoKit album.
- **Undo** — restores the previous action.
- Actions use explicit buttons, not swipe gestures.

## Gestures
- **Left/right swipe** — navigate to previous/next item like the Photos app.
- **Swipe up** — open the source/version detail panel.
- Gestures must not conflict with video playback or scrubbing.

## Source / Version panel
- Swipe-up or toggle to reveal a detail panel (not a separate screen).
- Shows: source/app, version stage, user notes, metadata.
- Example version labels: original, Lightroom export, Meitu edit, Instagram upload, X upload.
- Missing data shows "Unknown" or "Not tagged".
- Supports manual source/version tagging.

## Video playback
- Videos play inline in the review flow via AVPlayer/AVPlayerItem.
- Loading state while preparing, clear fallback on failure.
- Never show videos as static images in review mode.

## Source / metadata
- Surface Photos metadata about where a photo was saved from, if available.
- If no metadata, allow manual source/version tagging.

## Suggested MVP scope
- On This Day (done), Unsorted Videos, Unsorted Screenshots, Largest First
- Review actions (Delete, Keep, Favorite, Sort to album, Undo)
- Left/right navigation, Swipe-up source/version panel
- Video playback, Kept for Later, Manual source/version tags

## Out of scope
AI photo cleanup, cloud backup, login/accounts, social sharing, face recognition,
content classification, cross-device sync, Lightroom integration.

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
- After each milestone, summarize what changed, how to test it, any known limitations, and useful follow-ups.
- Do not expand scope without asking.
- If an instruction conflicts with a better product decision, explain why before changing direction.
