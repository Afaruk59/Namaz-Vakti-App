import Flutter
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        
        // Widget güncellemesi için MethodChannel
        let widgetChannel = FlutterMethodChannel(name: "com.afaruk59.namaz_vakti_app/widget", binaryMessenger: controller.binaryMessenger)
        
        widgetChannel.setMethodCallHandler { call, result in
            if call.method == "updateWidget" {
                // Widget verilerini senkronize et
                self.syncDataForWidget()
                
                // Widget'ları güncelle (iOS 14.0+ kontrolü)
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                    print("iOS Widget güncellendi")
                }
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Widget verilerini app başlangıcında da senkronize et
        self.syncDataForWidget()
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Uygulama ön plana geldiğinde widget'ı güncelle
    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        print("Uygulama ön plana geldi - Widget güncelleniyor")
        self.syncDataForWidget()
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // Uygulama arka plana geçtiğinde widget'ı güncelle
    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        print("Uygulama arka plana geçti - Widget güncelleniyor")
        self.syncDataForWidget()
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Widget Data Sync
    private func syncDataForWidget() {
        // Flutter SharedPreferences'dan widget'a veri aktar
        let flutterDefaults = UserDefaults.standard
        
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.afaruk59.namaz_vakti_app") else {
            print("Widget: Could not access app group")
            return
        }
        
        // Flutter'daki key'lerle widget key'lerini senkronize et
        if let location = flutterDefaults.string(forKey: "flutter.location") {
            sharedDefaults.set(location, forKey: "flutter.location")
            print("Widget: Synced location: \(location)")
        }
        
        if let name = flutterDefaults.string(forKey: "flutter.name") {
            sharedDefaults.set(name, forKey: "flutter.name")
            print("Widget: Synced name: \(name)")
        }
        
        // Eğer flutter.* key'leri yoksa, flutter key'lerini dene
        if flutterDefaults.string(forKey: "flutter.location") == nil {
            if let location = flutterDefaults.string(forKey: "location") {
                sharedDefaults.set(location, forKey: "flutter.location")
                print("Widget: Synced location from 'location': \(location)")
            }
        }
        
        if flutterDefaults.string(forKey: "flutter.name") == nil {
            if let name = flutterDefaults.string(forKey: "name") {
                sharedDefaults.set(name, forKey: "flutter.name")
                print("Widget: Synced name from 'name': \(name)")
            }
        }
        
        // Widget'ın timeline'ını yeniden yükle
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "PrayerTimesWidget")
            print("Widget timeline yeniden yüklendi")
        }
    }
}
