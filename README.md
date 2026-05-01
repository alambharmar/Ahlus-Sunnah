# Wasl Quran Tab

This update focuses on the Quran tab with offline downloads, a 30 Parah list, and a book-style reader.

## What Changed
- Quran text downloads per Juz and caches locally for offline use.
- Parah list shows availability and opens a book-style reader.
- Book reader paginates text based on screen size and font settings.

## Data Source
- Quran text is fetched from the Quran.com API (Uthmani text).
- If you need a different source or license, update `WaslApp/QuranDownloadManager.swift`.

## Run
Open `WaslApp.xcodeproj` in Xcode and run the iOS target. The Quran will download on demand.

## Notes
- Downloaded text is stored in Application Support under `Wasl/Quran/`.
- App bundle size stays small because text is downloaded at runtime.
