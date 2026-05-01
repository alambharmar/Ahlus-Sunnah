## Plan: Offline Quran with Parah list and page reader

Add bundled full Quran data and a book-style page-turn reader that uses the existing Quran tab. Wire the 30 Parah list to open the new reader, load offline Juz/page data through the current data manager/provider, and keep bookmarks/last-read intact. Focus changes in the Quran feature files and resources so other tabs remain unaffected.

### Steps 3–6 steps, 5–20 words each
1. Define offline data format and storage under `WaslApp/Resources` for 30 Parah JSON.  
2. Extend `QuranDataManager`/`QuranTextProvider` in `WaslApp/QuranDataStructure.swift` and `WaslApp/QuranTextProvider.swift` to load full content.  
3. Implement book-style page-turn UI in `WaslApp/QuranReaderView.swift` (or new view) using `QuranVerse` pages.  
4. Update `WaslApp/QuranView.swift` to launch the page-turn reader from the Parah list.  
5. Preserve bookmarks/last-read via `WaslApp/QuranManager.swift` using page indexes mapped to verses.  

### Further Considerations 1–3, 5–25 words each
1. Which Quran text source/license is approved for offline bundling?  - any source is fine just make sure its sunni and not any other like shia
2. Page mapping: Mushaf 604 pages or custom per-Parah pages?  idk what u are talking about i just want normal text if user maximaize page the remaining text should head to next page
3. File size constraints for app bundle; optional on-demand resources? - make sure app size doesnt increase more then general size
