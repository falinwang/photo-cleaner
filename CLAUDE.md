# CLAUDE.md — iOS Photo Cleaner

**Single authority for all implementation work.** When this file contradicts any other document (AGENT.md, memory files, old session transcripts), this file wins. The only exception is the canonical product spec below.

---

## Precedence rules

1. **`photo-organizer-prd-v1.md`** — canonical product spec. Wins on **WHAT** to build (features, modes, scope).
2. **This file** (`CLAUDE.md`) — canonical implementation spec. Wins on **HOW** to build, current implementation state, code patterns, and technical rules.
3. **`AGENT.md`** — handoff summary. Read for architecture overview, but defer to this file on any conflict.
4. **Memory files** (`~/.claude/.../memory/`) — historical record of past sessions. Describe what happened and why. Not authority on current state.
5. **The code itself** — ground truth on what actually exists. If this file says something is done but the code says otherwise, the code is right; update this file.

When you find a contradiction between any two sources, resolve in the order above and flag it.

---

## What this project is

A local-only, manual iOS photo organizer. Swift + SwiftUI + PhotoKit + AVFoundation. No backend, no AI, no cloud sync. The user reviews photos/videos one at a time and decides their fate.

---

## Active Xcode project

```
PhotoCleanerApp/PhotoCleanerApp.xcodeproj
```

All source under:
```
PhotoCleanerApp/PhotoCleanerApp/PhotoCleaner/
```

---

## Product modes (from PRD v1 — all P0)

| Mode | Status | Description |
|---|---|---|
| On This Day | Done | Photos from this date in past years, grouped by year. Frozen — only fix bugs. |
| Random | Done | Random picks from Unsorted. |
| Largest First | Done | Videos first, sorted by file size descending. Eager file-size loading for sort. |
| Unsorted | Done | Main todo list — everything not yet organized. |
| Kept for Later | Done | Temporary staging bucket. One-tap return to Unsorted. |

`AppMode` enum in `AppState.swift` currently has 4 values — missing `largestFirst`. PRD requires all 5.

**Divergence from PRD:** PRD specifies Unsorted Videos and Unsorted Screenshots as separate modes. Current implementation has a single Unsorted mode with a media-type filter (All / Videos / Screenshots segmented control) rather than splitting into separate modes.

---

## Review actions (from PRD v1)

| Action | Implementation | Status |
|---|---|---|
| Delete → app trash | Button in ActionBar. `session.delete()` → `AssetStore.trashedIDs` | Done |
| Keep → Kept for Later | Button in ActionBar. `session.keep()` → `AssetStore.keptForLaterIDs` | Done |
| Return to Unsorted | In keptForLater mode, KEEP becomes RETURN. `session.returnToUnsorted()` | Done |
| Skip | Button in ActionBar. `session.skip()` cycles item to end of queue | Done |
| Favorite | Swipe-down gesture on card. PhotoKit `isFavorite = true`. Undo un-favorites. | Done |
| Sort to Album | AlbumStripView exists with mock data. `sortToAlbum()` wired. | UI done, data mock |
| Undo | Stack-based, capped at 20. `session.undo()` | Done |

**Divergence from PRD:** PRD specifies swipe gestures for skip (left), delete (right-up), and favorite (down). Current implementation uses **buttons only** for actions and reserves swipes for left/right navigation. This was an intentional UX decision — buttons are more discoverable and avoid gesture conflicts with video controls. Do not revert to gesture-based actions without explicit discussion.

**Known undo bug:** `ReviewSession.undo()` at line 85-93 unconditionally calls `store.keptForLaterIDs.remove()`, but when undoing a `returnToUnsorted` action the item was already removed — it should re-add it. `UndoRecord.actionLabel` is stored but never read. Fix: branch on `record.actionLabel` in `undo()`.

---

## Architecture — 22 Swift files

### Models (5)
- `Models/MediaItem.swift` — `MediaItem`, `MediaType`, `CloudStatus`, mock data
- `Models/SourceInfo.swift` — `VersionStage` enum, `SourceInfo` (UserDefaults-backed per-item metadata)
- `Models/YearGroup.swift` — year grouping for On This Day
- `Models/TaskState.swift` — async task state
- `Models/MockData.swift` — mock items and albums for previews

### Services (3)
- `Services/PhotoLibraryService.swift` — PHAsset fetch for all modes. `fetchOnThisDayGrouped()`, `fileSize(from:)` (lazy), `makeItem()`
- `Services/ReviewSession.swift` — item queue, currentIndex, undo stack (max 20), skip/keep/delete/returnToUnsorted/sortToAlbum/undo, navigation
- `Services/AssetStore.swift` — `@Observable`, persisted Sets: `keptForLaterIDs`, `trashedIDs`, `sortedIDs`. `isUnsorted(id)` = not in any set

### Views — Review flow (7)
- `Views/Review/ReviewView.swift` — main review: TopBar → MediaCard → SourcePanel (toggle) → toggleRow → ActionBar → AlbumStrip (toggle). Horizontal-only swipe nav (80pt threshold). Dynamic card height via GeometryReader.
- `Views/Review/MediaCardView.swift` — photo (UIImage) or video (AVPlayerLayer via UIViewRepresentable). Custom video controls with auto-hide. Full-screen via `.fullScreenCover`.
- `Views/Review/OnThisDayView.swift` — 3-column year-grouped thumbnail grid → NavigationLink → ReviewView
- `Views/Review/SourcePanelView.swift` — collapsible panel: version stage picker, notes, read-only metadata. Auto-saves onDisappear.
- `Views/Review/TopBarView.swift` — close/help/trash + mode label + progress + compact date row
- `Views/Review/ActionBarView.swift` — SKIP / KEEP(RETURN) / DELETE + undo. Mode-aware button swap for keptForLater.
- `Views/Review/AlbumStripView.swift` — album grid for sort-to-album. Currently uses `MockAlbum` data.

### Views — Shared (3)
- `Views/Shared/MediaTypeBadge.swift`
- `Views/Shared/CloudStatusBadge.swift`
- `Views/Shared/PermissionView.swift`

### Views — Other (2)
- `Views/Home/HomeView.swift` — mode selection grid, branches to OnThisDayView or ReviewView
- `Views/Trash/TrashView.swift` — trashed items grid, batch recover/delete

### Root (2)
- `PhotoCleanerApp.swift` — `@main`
- `AppState.swift` — `AppMode` enum + `AppState` observable

---

## Key design decisions

- **Buttons-first for actions.** All review actions use explicit buttons. Swipes are for left/right navigation only.
- **In-app trash first.** Delete → `trashedIDs` set → user confirms permanent deletion in TrashView.
- **AssetStore is source of truth** for unsorted/kept/trashed/sorted state, not PhotoKit albums.
- **Video rendering.** AVPlayerLayer via UIViewRepresentable for inline card (avoids gesture conflicts). Native VideoPlayer only for full-screen.
- **File size.** Lazy-loaded on background thread via `PhotoLibraryService.fileSize(from:)`. Not computed synchronously in `makeItem()` (was causing main-thread watchdog kills).
- **Undo.** Stack-based, capped at 20, restores item to original index. FIFO eviction when full.
- **File size format.** `Int64` bytes, `formattedFileSize` to KB/MB, threshold 1,000,000 bytes. Estimated sizes (iCloud) prefixed with `~`.
- **No extra dependencies.** No animation libraries, no third-party frameworks.

---

## UI rules (enforced — do not violate)

### HStack overflow defense (mandatory for every bar/row)
1. Every `Text` gets `.lineLimit(1)` + `.truncationMode(.tail)` unless wrapping is intended
2. Every `Spacer()` uses `Spacer(minLength: X)` — 0 to allow collapse, 8+ for guaranteed gap
3. Custom-styled buttons get `.buttonStyle(.plain)`
4. Dates/sizes/numbers in tight bars use compact formatters (e.g. `"MMM d, yyyy"` not `.medium`)
5. Pin icon/button sizes with `.frame(width:height:)`
6. Test Previews with longest realistic content, not just `MockData[0]`
7. User/library data in bars (album names, metadata) = untrusted length, always truncate

### Chrome distillation
- Max 3 action buttons in the main action row, one visually primary (filled capsule)
- Meta-actions (help, settings) go to top bar
- Secondary actions (sort to album, source panel) collapse behind toggles
- Before adding any UI element, ask: does this earn its place against the photo card?

### Mode-aware button swap
- When a mode inverts the meaning of a primary action, swap label + icon + color
- `mode == .keptForLater` → KEEP becomes RETURN (tray icon, blue), calls `returnToUnsorted()`

### Gesture rules
- Swipe axes must be simple 1D (horizontal only for nav, vertical only for panels)
- Never use diagonal gestures
- Video scrub gesture must be isolated from card navigation

---

## Technical rules

- Swift + SwiftUI + PhotoKit + AVFoundation. No backend, no AI.
- `@Observable` for state, `@Environment` for DI
- Persistence via `UserDefaults` + `Codable`
- Prefer minimal safe changes over rewrites
- Reuse existing views when possible
- Verify with actual Xcode build, not SourceKit diagnostics (SourceKit produces frequent false positives)
- Keep code modular and easy to extend

### Propagation rule (mandatory)

When you change behavior in a UI-layer file, you MUST check every Service and Model file that backs it. A UI change is never complete until its reversal path (undo), state transition, and persistence are verified.

**Checklist — after any UI behavior change, verify:**
1. Can the action be undone? If yes, does `ReviewSession.undo()` correctly invert it?
2. Does the action mutate `AssetStore`? If yes, is the set operation reversible?
3. If the action changes meaning per-mode (like KEEP→RETURN), does the undo branch on `actionLabel` to invert the correct direction?

**UI → Service dependency map:**

| UI file | Must also check |
|---|---|
| `ActionBarView.swift` | `ReviewSession.swift` — `keep()`, `returnToUnsorted()`, `delete()`, `undo()`, `UndoRecord.actionLabel`; `AssetStore.swift` — all three ID sets |
| `ReviewView.swift` (swipe handlers) | `ReviewSession.swift` — `moveToNext()`, `moveToPrevious()`, `favorite()`, `undo()`, navigation guards |
| `SourcePanelView.swift` | `SourceInfo.swift` — `VersionStage`, `UserDefaults` persistence; `ReviewSession.swift` — `updateCloudStatus()` |
| `TopBarView.swift` (trash button) | `ReviewSession.swift` — `delete()` + `undo()`; `AssetStore.swift` — `trashedIDs` |
| `AlbumStripView.swift` | `ReviewSession.swift` — `sortToAlbum()` + `undo()`; `AssetStore.swift` — `sortedIDs` |
| `HomeView.swift` (mode cards) | `AppState.swift` — `AppMode` enum; `PhotoLibraryService.swift` — `fetchItems(for:store:)` |
| `TrashView.swift` | `AssetStore.swift` — `trashedIDs`; `PHAssetChangeRequest.deleteAssets` |

**Example of a propagation failure (do not repeat):** The KEEP→RETURN swap was implemented in `ActionBarView.swift` (UI) but `ReviewSession.undo()` continued to blindly `remove` from `keptForLaterIDs` instead of branching on `actionLabel`. Undoing a RETURN corrupted state: the item disappeared from both Kept and Unsorted. The fix was one `switch` statement. The root cause was no propagation check.

### Verification gate (mandatory)

A memory must NOT be marked `verified.status: true` until both conditions below pass. This applies to all `type: feedback` memories. No exceptions.

**Gate 1 — Build:**
```
xcodebuild -project PhotoCleanerApp/PhotoCleanerApp.xcodeproj \
  -scheme PhotoCleanerApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```
- Exit code must be `0`. Warnings are acceptable. Errors are not.
- Record the date and result in the memory's `verified.build` field.

**Gate 2 — Regression test:**
- Run the scenario described in the memory's `## Regression test` section.
- All assertions must pass. If the test relies on UI inspection (screenshot, view debugger), attach or describe the evidence.
- Record the date and result in the memory's `verified.regression_test` field.

**Verified metadata format:**

```yaml
verified:
  status: true          # true only if both gates passed, false otherwise
  date: 2026-05-26
  build:
    passed: true
    date: 2026-05-26
  regression_test:
    passed: true
    date: 2026-05-26
    notes: "all assertions passed on iPhone 16 Simulator"
```

**Ordering:** always run the build gate first. If the project doesn't compile, the regression test is meaningless.

---

## Bugs

| ID | Status | Description | File |
|---|---|---|---|
| BUG-001 | Fixed (2026-05-26) | Play button hidden behind video badge row. Root cause: outer `ZStack(alignment: .bottom)` rendered `badgeRow` on top of `mediaLayer`. Fix: moved `badgeRow` inside each branch of `mediaLayer` behind interactive elements. | `MediaCardView.swift:29-32` |
| BUG-002 | Fixed (2026-05-26) | Cloud-status badge always shows "Local." Root cause: `makeItem(from:)` hardcoded `.local`, lazy correction unreliable. Fix: eager `cloudStatus(for:)` sync check + `.downloading`/`.failed` signals. | `PhotoLibraryService.swift:192-204`, `MediaCardView.swift:253,275` |
| BUG-003 | Fixed (2026-05-26) | Photos appear broken/blurry during card navigation swipe. Root cause: `deliveryMode: .opportunistic` delivered degraded images; snap-back nav animation caused visual glitches. Fix: skip degraded deliveries via `PHImageResultIsDegradedKey`; slide-in from opposite side instead of snap-back. | `MediaCardView.swift:299`, `ReviewView.swift:234-250` |

## Known sharp edges

- New Swift files must be added to Xcode project manually (on disk ≠ in pbxproj)
- SourceKit frequently false-positives on cross-file types and UIViewRepresentable — trust the build, not the inline diagnostics
- Hardcoded layout constants (`topBarHeight: 72`, `actionBarHeight: 110` in ReviewView) will drift from reality if Dynamic Type or content changes the actual bar heights
- BUG-001 fix: `badgeRow` now lives in each branch of `mediaLayer` rather than the outer ZStack. When adding new media types or modifying the card layout, keep interactive elements (Play button, gestures) in front of `badgeRow` in z-order.

---

## Pending work (priority order)

### P0
*(none — all P0 items complete)*

### P1
4. Wire AlbumStripView to real PhotoKit album data instead of `MockAlbum`
5. ~~Add media-type filter (videos / screenshots / all) to Unsorted mode~~ Done
6. ~~Ensure video scrub gesture is isolated from card swipe~~ Done — `onScrubbing` callback suppresses `navGesture` during slider drag

### P2
7. Capacity stats dashboard
8. Pre-fetching and lazy-loading optimization
9. Batch operations
