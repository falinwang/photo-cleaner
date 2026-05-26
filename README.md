# Photo Cleaner

A local-only, manual photo organizer for iPhone Photos — built with SwiftUI + PhotoKit.

## Modes

- **On This Day** — Photos from this date in past years, grouped by year
- **Random** — Random picks from Unsorted
- **Largest First** — Videos first, sorted by file size — recover the most space
- **Unsorted** — Everything not yet organized, with media-type filter (All / Videos / Screenshots)
- **Kept for Later** — Temporary staging bucket, one-tap return to Unsorted

## Features

- Button-driven actions: Skip, Keep, Delete, Return to Unsorted
- Swipe left/right to navigate between items
- Swipe down to favorite (with heart overlay, writes to PhotoKit)
- Inline video playback with custom controls (play/pause, seek, fullscreen)
- On This Day grouped by year with thumbnail grid
- Source panel: version stage picker, notes, read-only metadata
- Multi-level undo (up to 20 actions, branches on action type)
- Sort photos to albums
- In-app trash with batch recover/permanent delete via PhotoKit
- Dark mode only

## Requirements

- iOS 17.0+
- Xcode 16+
- Photo Library access

## Setup

```bash
open PhotoCleanerApp.xcodeproj
```

Select an iOS 17+ simulator, then Build & Run (Cmd+R).

## Architecture

```
PhotoCleaner/
├── AppState.swift              # AppMode enum + AppState observable
├── PhotoCleanerApp.swift       # App entry point
├── Models/
│   ├── MediaItem.swift         # MediaItem, MediaType, MediaFilter, CloudStatus
│   ├── SourceInfo.swift        # VersionStage, SourceInfo (UserDefaults-backed)
│   ├── YearGroup.swift         # Year-grouped items for On This Day
│   ├── MockData.swift          # Preview data
│   └── TaskState.swift         # Async task state
├── Services/
│   ├── AssetStore.swift        # UserDefaults-backed persisted ID sets
│   ├── PhotoLibraryService.swift # PhotoKit fetch + async loading + LibrarySnapshot
│   └── ReviewSession.swift     # Review queue, undo stack, actions
└── Views/
    ├── Home/HomeView.swift     # Mode selection grid
    ├── Review/
    │   ├── ReviewView.swift    # Main review screen with async loading
    │   ├── OnThisDayView.swift # Year-grouped thumbnail grid
    │   ├── TopBarView.swift    # Top chrome
    │   ├── MediaCardView.swift # Photo/video card (AVPlayer + time observer)
    │   ├── SourcePanelView.swift # Metadata and provenance panel
    │   ├── ActionBarView.swift # Skip / Keep-Return / Delete + Undo
    │   └── AlbumStripView.swift # Sort-to-album (mock data)
    ├── Shared/
    │   ├── MediaTypeBadge.swift
    │   ├── CloudStatusBadge.swift
    │   └── PermissionView.swift
    └── Trash/TrashView.swift   # In-app trash with batch ops
```

## License

MIT
