import WidgetKit
import SwiftUI

// Prayer times data model
struct PrayerTimes {
    let cityName: String
    let imsak: String
    let gunes: String
    let ogle: String
    let ikindi: String
    let aksam: String
    let yatsi: String
    let lastUpdate: Date
}

// Timeline provider
struct PrayerTimesProvider: TimelineProvider {
    typealias Entry = PrayerTimesEntry
    
    func placeholder(in context: Context) -> PrayerTimesEntry {
        print("Widget: placeholder çağrıldı")
        return PrayerTimesEntry(date: Date(), prayerTimes: samplePrayerTimes)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PrayerTimesEntry) -> ()) {
        print("Widget: getSnapshot çağrıldı - preview için")
        let entry = PrayerTimesEntry(date: Date(), prayerTimes: samplePrayerTimes)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            print("Widget: getTimeline çağrıldı - veri çekiliyor")
            let prayerTimes = await fetchPrayerTimes()
            let entry = PrayerTimesEntry(date: Date(), prayerTimes: prayerTimes)
            
            // Her saat başında güncelle
            let now = Date()
            let calendar = Calendar.current
            let nextHour = calendar.nextDate(after: now, matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? calendar.date(byAdding: .hour, value: 1, to: now)!
            
            print("Widget: Sonraki güncelleme zamanı: \(nextHour)")
            let timeline = Timeline(entries: [entry], policy: .after(nextHour))
            completion(timeline)
        }
    }
    
    private var samplePrayerTimes: PrayerTimes {
        PrayerTimes(
            cityName: "İstanbul",
            imsak: "05:30",
            gunes: "07:00",
            ogle: "12:30",
            ikindi: "15:45",
            aksam: "18:30",
            yatsi: "20:00",
            lastUpdate: Date()
        )
    }
}

// Widget entry
struct PrayerTimesEntry: TimelineEntry {
    let date: Date
    let prayerTimes: PrayerTimes
}

// Widget view
struct PrayerTimesWidgetView: View {
    var entry: PrayerTimesEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(prayerTimes: entry.prayerTimes)
        case .systemMedium:
            MediumWidgetView(prayerTimes: entry.prayerTimes)
        case .systemLarge:
            LargeWidgetView(prayerTimes: entry.prayerTimes)
        default:
            MediumWidgetView(prayerTimes: entry.prayerTimes)
        }
    }
}

// Small widget view (2x2) - Tüm vakitler
struct SmallWidgetView: View {
    let prayerTimes: PrayerTimes
    
    var body: some View {
        let currentLanguage = getCurrentLanguage()
        
        VStack(spacing: 2) {
            // Şehir adı - minimal
            Text(prayerTimes.cityName)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            // Ana vakitler - 2x3 grid
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    SmallPrayerTimeItem(name: getPrayerName("imsak", language: currentLanguage), time: prayerTimes.imsak)
                    SmallPrayerTimeItem(name: getPrayerName("gunes", language: currentLanguage), time: prayerTimes.gunes)
                }
                HStack(spacing: 4) {
                    SmallPrayerTimeItem(name: getPrayerName("ogle", language: currentLanguage), time: prayerTimes.ogle)
                    SmallPrayerTimeItem(name: getPrayerName("ikindi", language: currentLanguage), time: prayerTimes.ikindi)
                }
                HStack(spacing: 4) {
                    SmallPrayerTimeItem(name: getPrayerName("aksam", language: currentLanguage), time: prayerTimes.aksam)
                    SmallPrayerTimeItem(name: getPrayerName("yatsi", language: currentLanguage), time: prayerTimes.yatsi)
                }
            }
            
            // Tarih bilgisi - mini
            Text(formattedDate())
                .font(.system(size: 8))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Medium widget view (4x2) - Tek satır
struct MediumWidgetView: View {
    let prayerTimes: PrayerTimes
    
    var body: some View {
        let currentLanguage = getCurrentLanguage()
        
        VStack(spacing: 4) {
            // Üst kısım - Şehir ve tarih
            HStack {
                Text(prayerTimes.cityName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Text(formattedDate())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            // Vakitler - tek satır
            HStack(spacing: 6) {
                PrayerTimeColumn(name: getPrayerName("imsak", language: currentLanguage), time: prayerTimes.imsak)
                PrayerTimeColumn(name: getPrayerName("gunes", language: currentLanguage), time: prayerTimes.gunes)
                PrayerTimeColumn(name: getPrayerName("ogle", language: currentLanguage), time: prayerTimes.ogle)
                PrayerTimeColumn(name: getPrayerName("ikindi", language: currentLanguage), time: prayerTimes.ikindi)
                PrayerTimeColumn(name: getPrayerName("aksam", language: currentLanguage), time: prayerTimes.aksam)
                PrayerTimeColumn(name: getPrayerName("yatsi", language: currentLanguage), time: prayerTimes.yatsi)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Large widget view (4x4) - Büyük kartlar
struct LargeWidgetView: View {
    let prayerTimes: PrayerTimes
    
    var body: some View {
        let currentLanguage = getCurrentLanguage()
        
        VStack(spacing: 10) {
            // Üst kısım - Şehir ve tarih
            HStack {
                Text(prayerTimes.cityName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Text(formattedDate())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            // Vakitler - 2x3 grid büyük kartlar
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 14) {
                LargePrayerTimeCard(name: getPrayerName("imsak", language: currentLanguage), time: prayerTimes.imsak)
                LargePrayerTimeCard(name: getPrayerName("gunes", language: currentLanguage), time: prayerTimes.gunes)
                LargePrayerTimeCard(name: getPrayerName("ogle", language: currentLanguage), time: prayerTimes.ogle)
                LargePrayerTimeCard(name: getPrayerName("ikindi", language: currentLanguage), time: prayerTimes.ikindi)
                LargePrayerTimeCard(name: getPrayerName("aksam", language: currentLanguage), time: prayerTimes.aksam)
                LargePrayerTimeCard(name: getPrayerName("yatsi", language: currentLanguage), time: prayerTimes.yatsi)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Helper views
struct SmallPrayerTimeItem: View {
    let name: String
    let time: String
    
    var body: some View {
        VStack(spacing: 1) {
            Text(name)
                .font(.system(size: 11))
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.secondary)
            Text(time)
                .font(.system(size: 15))
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 26)
    }
}

struct PrayerTimeColumn: View {
    let name: String
    let time: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundColor(.secondary)
            Text(time)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LargePrayerTimeCard: View {
    let name: String
    let time: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(.secondary)
            Text(time)
                .font(.title2)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// Main widget
struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            if #available(iOS 17.0, *) {
                PrayerTimesWidgetView(entry: entry)
                    .containerBackground(.clear, for: .widget)
            } else {
                PrayerTimesWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Namaz Vakitleri")
        .description("Güncel namaz vakitlerini gösterir")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Network functions - Android ile aynı mantık
func fetchPrayerTimes() async -> PrayerTimes {
    // SharedPreferences'dan şehir ID'sini al - Android'deki "flutter.location" ile aynı
    guard let sharedDefaults = UserDefaults(suiteName: "group.com.afaruk59.namaz_vakti_app"),
          let cityID = sharedDefaults.string(forKey: "flutter.location"),
          !cityID.isEmpty else {
        print("Widget: City ID not found, using sample data")
        return samplePrayerTimes
    }
    
    let cityName = sharedDefaults.string(forKey: "flutter.name") ?? "İstanbul"
    
    let urlString = "https://www.namazvakti.com/XML.php?cityID=\(cityID)"
    
    guard let url = URL(string: urlString) else {
        print("Widget: Invalid URL")
        return getCachedPrayerTimes() ?? samplePrayerTimes
    }
    
    do {
        print("Widget: Fetching data from: \(urlString)")
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 Namaz-Vakti-App Widget", forHTTPHeaderField: "User-Agent")
        request.setValue("application/xml", forHTTPHeaderField: "Accept")
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print("Widget: HTTP Error: \(httpResponse.statusCode)")
            return getCachedPrayerTimes() ?? samplePrayerTimes
        }
        
        if let parsedTimes = parseXMLData(data, cityName: cityName) {
            // Cache the data
            cachePrayerTimes(parsedTimes)
            return parsedTimes
        } else {
            print("Widget: XML parsing failed")
            return getCachedPrayerTimes() ?? samplePrayerTimes
        }
    } catch {
        print("Widget: Network error: \(error)")
        return getCachedPrayerTimes() ?? samplePrayerTimes
    }
}

func parseXMLData(_ data: Data, cityName: String) -> PrayerTimes? {
    guard let xmlString = String(data: data, encoding: .utf8) else {
        print("Widget: Could not convert data to string")
        return nil
    }
    
    print("Widget: XML Response length: \(xmlString.count)")
    
    let currentDate = Date()
    let calendar = Calendar.current
    let currentDay = calendar.component(.day, from: currentDate)
    let currentMonth = calendar.component(.month, from: currentDate)
    
    print("Widget: Looking for day: \(currentDay), month: \(currentMonth)")
    
    // XML'de bugünkü tarihi ara - XML formatı: <prayertimes ... day="8" month="6">
    let dayPattern = "day=\"\(currentDay)\""
    let monthPattern = "month=\"\(currentMonth)\""
    
    // XML'i satır satır kontrol et
    let lines = xmlString.components(separatedBy: .newlines)
    
    for line in lines {
        if line.contains("prayertimes") && line.contains(dayPattern) && line.contains(monthPattern) {
            print("Widget: Found matching line: \(line)")
            
            // XML tag'inden sonraki içeriği al
            if let startIndex = line.range(of: ">")?.upperBound,
               let endIndex = line.range(of: "</prayertimes>")?.lowerBound {
                
                let content = String(line[startIndex..<endIndex])
                print("Widget: Prayer times content: '\(content)'")
                
                // Boşluklarla ayrılmış vakitleri parse et
                let components = content.components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                
                print("Widget: Found \(components.count) components: \(components)")
                
                // Android ile aynı indexleri kullan
                if components.count >= 12 {
                    let times = [
                        components[0],  // İmsak
                        components[2],  // Güneş  
                        components[5],  // Öğle
                        components[6],  // İkindi
                        components[9],  // Akşam
                        components[11]  // Yatsı
                    ]
                    
                    print("Widget: Successfully parsed times: \(times)")
                    return PrayerTimes(
                        cityName: cityName,
                        imsak: times[0],
                        gunes: times[1],
                        ogle: times[2],
                        ikindi: times[3],
                        aksam: times[4],
                        yatsi: times[5],
                        lastUpdate: Date()
                    )
                } else {
                    print("Widget: Not enough components found: \(components.count)")
                }
            }
        }
    }
    
    print("Widget: Could not find today's prayer times in XML")
    return nil
}

func cachePrayerTimes(_ prayerTimes: PrayerTimes) {
    guard let sharedDefaults = UserDefaults(suiteName: "group.com.afaruk59.namaz_vakti_app") else { return }
    
    sharedDefaults.set(prayerTimes.cityName, forKey: "cached_city_name")
    sharedDefaults.set(prayerTimes.imsak, forKey: "cached_imsak")
    sharedDefaults.set(prayerTimes.gunes, forKey: "cached_gunes")
    sharedDefaults.set(prayerTimes.ogle, forKey: "cached_ogle")
    sharedDefaults.set(prayerTimes.ikindi, forKey: "cached_ikindi")
    sharedDefaults.set(prayerTimes.aksam, forKey: "cached_aksam")
    sharedDefaults.set(prayerTimes.yatsi, forKey: "cached_yatsi")
    sharedDefaults.set(Date(), forKey: "cached_date")
}

func getCachedPrayerTimes() -> PrayerTimes? {
    guard let sharedDefaults = UserDefaults(suiteName: "group.com.afaruk59.namaz_vakti_app"),
          let cachedDate = sharedDefaults.object(forKey: "cached_date") as? Date else {
        return nil
    }
    
    // Check if cache is less than 24 hours old
    let hoursSinceCache = Date().timeIntervalSince(cachedDate) / 3600
    if hoursSinceCache > 24 {
        print("Widget: Cached data is too old (\(hoursSinceCache) hours)")
        return nil
    }
    
    guard let cityName = sharedDefaults.string(forKey: "cached_city_name"),
          let imsak = sharedDefaults.string(forKey: "cached_imsak"),
          let gunes = sharedDefaults.string(forKey: "cached_gunes"),
          let ogle = sharedDefaults.string(forKey: "cached_ogle"),
          let ikindi = sharedDefaults.string(forKey: "cached_ikindi"),
          let aksam = sharedDefaults.string(forKey: "cached_aksam"),
          let yatsi = sharedDefaults.string(forKey: "cached_yatsi") else {
        return nil
    }
    
    print("Widget: Using cached data")
    return PrayerTimes(
        cityName: cityName,
        imsak: imsak,
        gunes: gunes,
        ogle: ogle,
        ikindi: ikindi,
        aksam: aksam,
        yatsi: yatsi,
        lastUpdate: cachedDate
    )
}

var samplePrayerTimes: PrayerTimes {
    PrayerTimes(
        cityName: "İstanbul",
        imsak: "05:30",
        gunes: "07:00",
        ogle: "12:30",
        ikindi: "15:45",
        aksam: "18:30",
        yatsi: "20:00",
        lastUpdate: Date()
    )
}

// Tarih formatlama fonksiyonu
func formattedDate() -> String {
    let currentLanguage = getCurrentLanguage()
    
    let currentDate = Date()
    let calendar = Calendar.current
    
    let day = calendar.component(.day, from: currentDate)
    let month = calendar.component(.month, from: currentDate)
    let weekday = calendar.component(.weekday, from: currentDate)
    
    return formatDateForLanguage(day: day, month: month, weekday: weekday, language: currentLanguage)
}

// Dil tespiti fonksiyonu - Otomatik sistem dili
func getCurrentLanguage() -> String {
    // Sistem dilini al
    let systemLanguage = Locale.current.languageCode ?? "en"
    let supportedLanguages = ["tr", "en", "ar", "de", "es", "fr", "it", "ru"]
    
    // Sistem dili destekleniyorsa onu kullan
    if supportedLanguages.contains(systemLanguage) {
        print("Widget: Using system language: \(systemLanguage)")
        return systemLanguage
    }
    
    // Desteklenmiyorsa varsayılan English
    print("Widget: System language '\(systemLanguage)' not supported, using English")
    return "en"
}

// Vakit isimlerini dile göre döndür
func getPrayerName(_ prayer: String, language: String) -> String {
    let translations: [String: [String: String]] = [
        "tr": [
            "imsak": "İmsak",
            "gunes": "Güneş", 
            "ogle": "Öğle",
            "ikindi": "İkindi",
            "aksam": "Akşam",
            "yatsi": "Yatsı"
        ],
        "en": [
            "imsak": "Fajr",
            "gunes": "Sunrise",
            "ogle": "Dhuhr", 
            "ikindi": "Asr",
            "aksam": "Maghrib",
            "yatsi": "Isha"
        ],
        "ar": [
            "imsak": "الفجر",
            "gunes": "الشروق",
            "ogle": "الظهر",
            "ikindi": "العصر", 
            "aksam": "المغرب",
            "yatsi": "العشاء"
        ],
        "de": [
            "imsak": "Fajr",
            "gunes": "Sonnenaufgang",
            "ogle": "Dhuhr",
            "ikindi": "Asr",
            "aksam": "Maghrib", 
            "yatsi": "Isha"
        ],
        "es": [
            "imsak": "Fajr",
            "gunes": "Amanecer",
            "ogle": "Dhuhr",
            "ikindi": "Asr",
            "aksam": "Maghrib",
            "yatsi": "Isha"
        ],
        "fr": [
            "imsak": "Fajr",
            "gunes": "Lever",
            "ogle": "Dhuhr",
            "ikindi": "Asr",
            "aksam": "Maghrib",
            "yatsi": "Isha"
        ],
        "it": [
            "imsak": "Fajr",
            "gunes": "Alba",
            "ogle": "Dhuhr",
            "ikindi": "Asr",
            "aksam": "Maghrib",
            "yatsi": "Isha"
        ],
        "ru": [
            "imsak": "Фаджр",
            "gunes": "Восход",
            "ogle": "Зухр",
            "ikindi": "Аср",
            "aksam": "Магриб",
            "yatsi": "Иша"
        ]
    ]
    
    return translations[language]?[prayer] ?? translations["en"]?[prayer] ?? prayer.capitalized
}

// Tarih formatını dile göre döndür
func formatDateForLanguage(day: Int, month: Int, weekday: Int, language: String) -> String {
    let monthNames: [String: [String]] = [
        "tr": ["", "Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eka", "Kas", "Ara"],
        "en": ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
        "ar": ["", "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"],
        "de": ["", "Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"],
        "es": ["", "Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"],
        "fr": ["", "Jan", "Fév", "Mar", "Avr", "Mai", "Jun", "Jul", "Aoû", "Sep", "Oct", "Nov", "Déc"],
        "it": ["", "Gen", "Feb", "Mar", "Apr", "Mag", "Giu", "Lug", "Ago", "Set", "Ott", "Nov", "Dic"],
        "ru": ["", "Янв", "Фев", "Мар", "Апр", "Май", "Июн", "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"]
    ]
    
    let weekdayNames: [String: [String]] = [
        "tr": ["", "Paz", "Pts", "Sal", "Çar", "Per", "Cum", "Cts"],
        "en": ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
        "ar": ["", "الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"],
        "de": ["", "So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"],
        "es": ["", "Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"],
        "fr": ["", "Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"],
        "it": ["", "Dom", "Lun", "Mar", "Mer", "Gio", "Ven", "Sab"],
        "ru": ["", "Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
    ]
    
    let monthName = monthNames[language]?[month] ?? monthNames["en"]?[month] ?? "\(month)"
    let weekdayName = weekdayNames[language]?[weekday] ?? weekdayNames["en"]?[weekday] ?? ""
    
    // Arapça için özel format (sağdan sola)
    if language == "ar" {
        return "\(weekdayName) \(day) \(monthName)"
    }
    
    return "\(day) \(monthName) \(weekdayName)"
}

// Preview
struct PrayerTimesWidget_Previews: PreviewProvider {
    static var previews: some View {
        PrayerTimesWidgetView(entry: PrayerTimesEntry(date: Date(), prayerTimes: samplePrayerTimes))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
