# Photo Cleaner

[EN](README.md) | **中文**

一款本機離線的手動照片整理工具，基於 SwiftUI + PhotoKit 打造。

## 模式

- **On This Day** — 往年今日的照片，按年份分組
- **Random** — 從未整理中隨機挑選
- **Largest First** — 影片優先，按檔案大小排序 — 釋放最多空間
- **Unsorted** — 所有尚未整理的內容，支援類型篩選（全部 / 影片 / 截圖）
- **Kept for Later** — 暫存區，一鍵退回未整理

## 功能

- 按鈕操作：跳過、保留、刪除、退回未整理
- 左右滑動切換項目
- 向下滑動加入收藏（顯示愛心動畫，寫入 PhotoKit）
- 內嵌影片播放器，支援自訂控制項（播放 / 暫停 / 拖曳進度 / 全螢幕）
- 雲端狀態指示器（本機、iCloud 下載中、下載失敗）
- On This Day 按年份分組，縮圖網格瀏覽
- 來源面板：版本階段選擇器、備註、唯讀中繼資料
- 多層級復原（最多 20 步，依動作類型分支處理）
- 整理至相簿（UI 已完成，待串接真實 PhotoKit 相簿資料）
- 內建垃圾桶，支援批次復原 / 永久刪除（透過 PhotoKit）
- 自訂 App 圖示
- 僅深色模式

## 需求

- iOS 17.0+
- Xcode 16+
- 相簿存取權限

## 安裝

```bash
open PhotoCleanerApp.xcodeproj
```

選擇 iOS 17+ 模擬器，按下 Build & Run（Cmd+R）。

## 架構

```
PhotoCleaner/
├── AppState.swift              # AppMode 列舉 + AppState 可觀察物件
├── PhotoCleanerApp.swift       # App 進入點
├── Models/
│   ├── MediaItem.swift         # MediaItem、MediaType、MediaFilter、CloudStatus
│   ├── SourceInfo.swift        # VersionStage、SourceInfo（UserDefaults 持久化）
│   ├── YearGroup.swift         # On This Day 的年份分組
│   ├── MockData.swift          # 預覽用假資料
│   └── TaskState.swift         # 非同步任務狀態
├── Services/
│   ├── AssetStore.swift        # UserDefaults 持久化的 ID 集合
│   ├── PhotoLibraryService.swift # PhotoKit 查詢 + 非同步載入 + LibrarySnapshot
│   └── ReviewSession.swift     # 檢視佇列、復原堆疊、操作邏輯
└── Views/
    ├── Home/HomeView.swift     # 模式選擇網格
    ├── Review/
    │   ├── ReviewView.swift    # 主要檢視畫面（含非同步載入）
    │   ├── OnThisDayView.swift # 年份分組縮圖網格
    │   ├── TopBarView.swift    # 頂部工具列
    │   ├── MediaCardView.swift # 照片 / 影片卡片（AVPlayer + 時間觀察器）
    │   ├── SourcePanelView.swift # 中繼資料與來源面板
    │   ├── ActionBarView.swift # 跳過 / 保留-退回 / 刪除 + 復原
    │   └── AlbumStripView.swift # 整理至相簿（Mock 資料）
    ├── Shared/
    │   ├── MediaTypeBadge.swift
    │   ├── CloudStatusBadge.swift
    │   └── PermissionView.swift
    └── Trash/TrashView.swift   # 內建垃圾桶（含批次操作）
```

## 授權

MIT
