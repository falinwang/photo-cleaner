# Photo Cleaner

A local-only, manual photo organizer for iPhone Photos — built with SwiftUI + PhotoKit.

## Modes

- **On This Day** — Photos from this date in past years
- **Random** — Random picks from Unsorted
- **Unsorted** — Everything not yet organized
- **Kept for Later** — Temporary bucket for review

## Features

- Swipe left/right/up/down to skip, keep, delete, or favorite
- Multi-level undo (up to 20 actions)
- Sort photos to albums
- In-app trash with permanent delete via PhotoKit
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
├── AppState.swift              # App mode enum + global state
├── PhotoCleanerApp.swift       # App entry point
├── Models/
│   ├── MediaItem.swift         # Photo/video model
│   ├── MockData.swift          # Preview data
│   └── TaskState.swift         # Item state enum
├── Services/
│   ├── AssetStore.swift        # UserDefaults-backed state persistence
│   ├── PhotoLibraryService.swift # PhotoKit fetch + authorization
│   └── ReviewSession.swift     # Review queue with undo stack
└── Views/
    ├── Home/HomeView.swift     # Mode selection
    ├── Review/
    │   ├── ReviewView.swift    # Main review screen
    │   ├── TopBarView.swift    # Top chrome
    │   ├── MediaCardView.swift # Photo card with badges
    │   ├── ActionBarView.swift # Skip / Keep / Delete
    │   └── AlbumStripView.swift # Sort-to-album chips
    ├── Shared/
    │   ├── MediaTypeBadge.swift
    │   ├── CloudStatusBadge.swift
    │   └── PermissionView.swift
    └── Trash/TrashView.swift   # In-app trash
```

## License

MIT
