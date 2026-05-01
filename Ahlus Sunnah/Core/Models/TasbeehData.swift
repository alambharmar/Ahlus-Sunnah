import SwiftUI
import Combine

// MARK: - ZikrItem Structure
struct ZikrItem: Identifiable, Equatable {
    let id = UUID()
    let arabic: String
    let transliteration: String
    let translation: String
    let benefit: String?
    let targetCount: Int?
    let accentColor: Color
    var count: Int = 0
}

// MARK: - TasbeehManager
class TasbeehManager: ObservableObject {
    @Published var zikrList: [ZikrItem] = []

    init() {
        self.zikrList = [
            ZikrItem(
                arabic: "سُبْحَانَ ٱللَّٰهِ",
                transliteration: "SubhanAllah",
                translation: "Glory be to Allah",
                benefit: "Praising Allah's perfection removes sins like leaves fall from trees",
                targetCount: nil,
                accentColor: Color.cyan
            ),
            ZikrItem(
                arabic: "ٱلْحَمْدُ لِلَّٰهِ",
                transliteration: "Alhamdulillah",
                translation: "All praise is due to Allah",
                benefit: "Fills the scales of good deeds on the Day of Judgment",
                targetCount: nil,
                accentColor: Color.green
            ),
            ZikrItem(
                arabic: "ٱللَّٰهُ أَكْبَرُ",
                transliteration: "Allahu Akbar",
                translation: "Allah is the Greatest",
                benefit: "The greatest phrase in the sight of Allah",
                targetCount: nil,
                accentColor: Color.orange
            ),
            ZikrItem(
                arabic: "لَا إِلَٰهَ إِلَّا ٱللَّٰهُ",
                transliteration: "La ilaha illa Allah",
                translation: "There is no God but Allah",
                benefit: "The key to Paradise and the foundation of faith",
                targetCount: nil,
                accentColor: Color.blue
            ),
            ZikrItem(
                arabic: "أَسْتَغْفِرُ ٱللَّٰهَ",
                transliteration: "Astaghfirullah",
                translation: "I seek forgiveness from Allah",
                benefit: "Opens doors of mercy and increases provisions",
                targetCount: nil,
                accentColor: Color.purple
            ),
            ZikrItem(
                arabic: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِٱللَّٰهِ",
                transliteration: "La hawla wa la quwwata illa billah",
                translation: "There is no power nor strength except with Allah",
                benefit: "A treasure from the treasures of Paradise",
                targetCount: nil,
                accentColor: Color.indigo
            ),
            ZikrItem(
                arabic: "سُبْحَانَ ٱللَّٰهِ وَبِحَمْدِهِ",
                transliteration: "Subhanallahi wa bihamdihi",
                translation: "Glory be to Allah and praise Him",
                benefit: "Two words light on the tongue, heavy on the scales",
                targetCount: nil,
                accentColor: Color.teal
            ),
            ZikrItem(
                arabic: "سُبْحَانَ ٱللَّٰهِ ٱلْعَظِيمِ",
                transliteration: "Subhanallahil Azeem",
                translation: "Glory be to Allah, the Magnificent",
                benefit: "Beloved to the Most Merciful",
                targetCount: nil,
                accentColor: Color.mint
            ),
            ZikrItem(
                arabic: "لَا إِلَٰهَ إِلَّا ٱللَّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ",
                transliteration: "La ilaha illallahu wahdahu la sharika lah",
                translation: "There is no god but Allah alone, with no partner",
                benefit: "Equals freeing ten slaves and earns 100 good deeds",
                targetCount: nil,
                accentColor: Color.pink
            ),
            ZikrItem(
                arabic: "ٱللَّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ",
                transliteration: "Allahumma salli ala Muhammad",
                translation: "O Allah, send blessings upon Muhammad",
                benefit: "Allah sends ten blessings upon you for every one you send",
                targetCount: nil,
                accentColor: Color.yellow
            ),
            ZikrItem(
                arabic: "بِسْمِ ٱللَّٰهِ",
                transliteration: "Bismillah",
                translation: "In the name of Allah",
                benefit: "Protection from Shaytan in all actions",
                targetCount: nil,
                accentColor: Color.red
            ),
            ZikrItem(
                arabic: "حَسْبُنَا ٱللَّٰهُ وَنِعْمَ ٱلْوَكِيلُ",
                transliteration: "Hasbunallahu wa ni'mal wakeel",
                translation: "Allah is sufficient for us, and He is the best Disposer of affairs",
                benefit: "Brings peace in times of distress and reliance on Allah",
                targetCount: nil,
                accentColor: Color.brown
            )
        ]
        
        loadCounts()
    }

    // MARK: - Load saved counts
    func loadCounts() {
        for index in zikrList.indices {
            let key = zikrList[index].transliteration
            let savedCount = UserDefaults.standard.integer(forKey: key)
            zikrList[index].count = savedCount
        }
    }

    // MARK: - Save count for specific Zikr
    func saveCount(for zikr: ZikrItem) {
        UserDefaults.standard.set(zikr.count, forKey: zikr.transliteration)
    }
    
    // MARK: - Reset count for specific Zikr
    func resetCount(for zikr: ZikrItem) {
        if let index = zikrList.firstIndex(where: { $0.id == zikr.id }) {
            zikrList[index].count = 0
            UserDefaults.standard.set(0, forKey: zikr.transliteration)
        }
    }

    // MARK: - Reset all counts
    func resetAllCounts() {
        for index in zikrList.indices {
            zikrList[index].count = 0
            let key = zikrList[index].transliteration
            UserDefaults.standard.set(0, forKey: key)
        }
    }
}
