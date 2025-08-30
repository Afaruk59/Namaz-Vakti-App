import Flutter
import WidgetKit
import AVFoundation
import MediaPlayer

@objc class MediaController: NSObject {
    private var methodChannel: FlutterMethodChannel?
    var callbackChannel: FlutterMethodChannel?
    private var nowPlayingInfo: [String: Any] = [:]
    private var isServiceRunning = false
    
    // Playback states
    static let STATE_NONE = 0
    static let STATE_STOPPED = 1  
    static let STATE_PAUSED = 2
    static let STATE_PLAYING = 3
    
    init(methodChannel: FlutterMethodChannel, callbackChannel: FlutterMethodChannel) {
        super.init()
        self.methodChannel = methodChannel
        self.callbackChannel = callbackChannel
        
        // Hemen audio session'ı aktif et ve remote command'ları ayarla
        setupAudioSession()
        activateAudioSession()
        setupRemoteCommandCenter()
        
        print("🎵 MediaController: Initialized and activated immediately")
    }
    
    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ MediaController: Audio session activated immediately")
        } catch {
            print("❌ MediaController: Failed to activate audio session immediately: \(error)")
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("MediaController: Audio session setup failed: \(error)")
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.addTarget { [weak self] event in
            print("🎵 MediaController: Play command received from iOS")
            self?.callbackChannel?.invokeMethod("play", arguments: nil) { result in
                if let error = result as? FlutterError {
                    print("❌ MediaController: Play command error: \(error)")
                } else {
                    print("✅ MediaController: Play command sent to Flutter successfully")
                }
            }
            return .success
        }
        
        // Pause command  
        commandCenter.pauseCommand.addTarget { [weak self] event in
            print("⏸️ MediaController: Pause command received from iOS")
            self?.callbackChannel?.invokeMethod("pause", arguments: nil) { result in
                if let error = result as? FlutterError {
                    print("❌ MediaController: Pause command error: \(error)")
                } else {
                    print("✅ MediaController: Pause command sent to Flutter successfully")
                }
            }
            return .success
        }
        
        // Stop command
        commandCenter.stopCommand.addTarget { [weak self] event in
            print("⏹️ MediaController: Stop command received from iOS")
            self?.callbackChannel?.invokeMethod("stop", arguments: nil) { result in
                if let error = result as? FlutterError {
                    print("❌ MediaController: Stop command error: \(error)")
                } else {
                    print("✅ MediaController: Stop command sent to Flutter successfully")
                }
            }
            return .success
        }
        
        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            print("MediaController: Toggle play/pause command received")
            // Check current state and toggle appropriately
            let nowPlayingCenter = MPNowPlayingInfoCenter.default()
            let playbackRate = nowPlayingCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Double ?? 0.0
            
            if playbackRate > 0 {
                // Currently playing, so pause
                self?.callbackChannel?.invokeMethod("pause", arguments: nil) { result in
                    if let error = result as? FlutterError {
                        print("MediaController: Toggle pause error: \(error)")
                    }
                }
            } else {
                // Currently paused/stopped, so play
                self?.callbackChannel?.invokeMethod("play", arguments: nil) { result in
                    if let error = result as? FlutterError {
                        print("MediaController: Toggle play error: \(error)")
                    }
                }
            }
            return .success
        }
        
        // Next track command
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            print("⏭️ MediaController: Next track command received from iOS")
            self?.callbackChannel?.invokeMethod("next", arguments: nil) { result in
                if let error = result as? FlutterError {
                    print("❌ MediaController: Next command error: \(error)")
                } else {
                    print("✅ MediaController: Next command sent to Flutter successfully")
                }
            }
            return .success
        }
        
        // Previous track command
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            print("⏮️ MediaController: Previous track command received from iOS")
            self?.callbackChannel?.invokeMethod("previous", arguments: nil) { result in
                if let error = result as? FlutterError {
                    print("❌ MediaController: Previous command error: \(error)")
                } else {
                    print("✅ MediaController: Previous command sent to Flutter successfully")
                }
            }
            return .success
        }
        
        // Seek command
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                let positionMs = Int(positionEvent.positionTime * 1000)
                print("MediaController: Seek command received: \(positionMs)ms")
                self?.callbackChannel?.invokeMethod("seekTo", arguments: positionMs) { result in
                    if let error = result as? FlutterError {
                        print("MediaController: Seek command error: \(error)")
                    }
                }
                return .success
            }
            return .commandFailed
        }
        
        // Enable the commands
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.stopCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
    }
    
    func startService() {
        print("🎵 MediaController: Starting service (isServiceRunning: \(isServiceRunning))")
        isServiceRunning = true
        
        // Ensure audio session is active with proper configuration
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
            try audioSession.setActive(true)
            print("🎵 MediaController: Audio session activated successfully")
        } catch {
            print("❌ MediaController: Failed to activate audio session: \(error)")
        }
        
        // Ensure remote command center is properly set up
        setupRemoteCommandCenter()
        
        print("✅ MediaController: Service started successfully")
    }
    
    func stopService() {
        print("MediaController: Stopping service")
        isServiceRunning = false
        
        // Clear now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("MediaController: Failed to deactivate audio session: \(error)")
        }
    }
    
    func updatePlaybackState(_ state: Int) {
        print("MediaController: Updating playback state to \(state)")
        
        let nowPlayingCenter = MPNowPlayingInfoCenter.default()
        
        switch state {
        case MediaController.STATE_PLAYING:
            var nowPlayingInfo = nowPlayingCenter.nowPlayingInfo ?? [:]
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            nowPlayingCenter.nowPlayingInfo = nowPlayingInfo
            print("MediaController: Set playback state to PLAYING")
        case MediaController.STATE_PAUSED:
            var nowPlayingInfo = nowPlayingCenter.nowPlayingInfo ?? [:]
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            nowPlayingCenter.nowPlayingInfo = nowPlayingInfo
            print("MediaController: Set playback state to PAUSED")
        case MediaController.STATE_STOPPED:
            // Clear all info for stopped state
            nowPlayingCenter.nowPlayingInfo = nil
            print("MediaController: Cleared now playing info (STOPPED)")
            return
        default:
            var nowPlayingInfo = nowPlayingCenter.nowPlayingInfo ?? [:]
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            nowPlayingCenter.nowPlayingInfo = nowPlayingInfo
            print("MediaController: Set playback state to default (0.0)")
        }
        
        // Ensure remote command center is enabled when we have active playback
        if state == MediaController.STATE_PLAYING || state == MediaController.STATE_PAUSED {
            let commandCenter = MPRemoteCommandCenter.shared()
            commandCenter.playCommand.isEnabled = true
            commandCenter.pauseCommand.isEnabled = true
            commandCenter.stopCommand.isEnabled = true
            commandCenter.togglePlayPauseCommand.isEnabled = true
            commandCenter.nextTrackCommand.isEnabled = true
            commandCenter.previousTrackCommand.isEnabled = true
            commandCenter.changePlaybackPositionCommand.isEnabled = true
        }
    }
    
    func updateMetadata(title: String, author: String, coverUrl: String, duration: Int) {
        print("🎵 MediaController: Updating metadata - Title: '\(title)', Author: '\(author)', Duration: \(duration)ms")
        
        let nowPlayingCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo: [String: Any] = [:]
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = author
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Namaz Vakti App"
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Double(duration) / 1000.0
        
        // Set initial playback rate to 1.0 (playing)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
        
        // Set default artwork if no cover URL provided
        if let image = UIImage(named: "AppIcon") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in
                return image
            }
        }
        
        nowPlayingCenter.nowPlayingInfo = nowPlayingInfo
        print("✅ MediaController: Now playing info updated with \(nowPlayingInfo.count) properties")
        
        // Force update the now playing info center
        DispatchQueue.main.async {
            nowPlayingCenter.nowPlayingInfo = nowPlayingInfo
            print("🔄 MediaController: Force updated now playing info on main thread")
        }
    }
    
    func updatePosition(_ positionMs: Int) {
        let nowPlayingCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingCenter.nowPlayingInfo ?? [:]
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(positionMs) / 1000.0
        
        nowPlayingCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    func updateAudioPageState(bookCode: String, currentPage: Int, firstPage: Int, lastPage: Int) {
        print("MediaController: Updating audio page state - Book: \(bookCode), Page: \(currentPage), Boundaries: \(firstPage)-\(lastPage)")
        // Store page information for boundary checking
        // This could be stored in UserDefaults or passed to the command handlers
    }
    
    func handleAppStateChange(isActive: Bool) {
        if isActive {
            print("MediaController: App became active")
            // Reactivate audio session if needed
            if isServiceRunning {
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print("MediaController: Failed to reactivate audio session: \(error)")
                }
            }
        } else {
            print("MediaController: App became inactive")
            // Keep audio session active for background playback
        }
    }
    
    func dispose() {
        print("MediaController: Disposing")
        stopService()
        
        // Disable remote commands
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.stopCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        
        // Remove all targets
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.stopCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var mediaController: MediaController?
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        
        // Widget güncellemesi için MethodChannel
        let widgetChannel = FlutterMethodChannel(name: "com.afaruk59.namaz_vakti_app/widget", binaryMessenger: controller.binaryMessenger)
        
        // Media controls için MethodChannel
        let mediaControlsChannel = FlutterMethodChannel(name: "com.afaruk59.namaz_vakti_app/media_controls", binaryMessenger: controller.binaryMessenger)
        
        // Media controls callback için MethodChannel (iOS -> Flutter çağrıları için)
        let mediaCallbackChannel = FlutterMethodChannel(name: "com.afaruk59.namaz_vakti_app/media_callback", binaryMessenger: controller.binaryMessenger)
        
        // Initialize media controller
        mediaController = MediaController(methodChannel: mediaControlsChannel, callbackChannel: mediaCallbackChannel)
        
        // Media controls method handler
        mediaControlsChannel.setMethodCallHandler { [weak self] call, result in
            print("iOS MediaController: Received method call: \(call.method)")
            
            guard let self = self, let mediaController = self.mediaController else {
                print("iOS MediaController: ERROR - Media controller not available")
                result(FlutterError(code: "UNAVAILABLE", message: "Media controller not available", details: nil))
                return
            }
            
            print("iOS MediaController: Processing method: \(call.method)")
            switch call.method {
            case "startService":
                mediaController.startService()
                result(nil)
            case "stopService":
                mediaController.stopService()
                result(nil)
            case "updatePlaybackState":
                if let args = call.arguments as? [String: Any],
                   let state = args["state"] as? Int {
                    mediaController.updatePlaybackState(state)
                }
                result(nil)
            case "updateMetadata":
                if let args = call.arguments as? [String: Any] {
                    let title = args["title"] as? String ?? ""
                    let author = args["author"] as? String ?? ""
                    let coverUrl = args["coverUrl"] as? String ?? ""
                    let duration = args["duration"] as? Int ?? 0
                    mediaController.updateMetadata(title: title, author: author, coverUrl: coverUrl, duration: duration)
                }
                result(nil)
            case "updatePosition":
                if let args = call.arguments as? [String: Any],
                   let position = args["position"] as? Int {
                    mediaController.updatePosition(position)
                }
                result(nil)
            case "updateAudioPageState":
                if let args = call.arguments as? [String: Any] {
                    let bookCode = args["bookCode"] as? String ?? ""
                    let currentPage = args["currentPage"] as? Int ?? 0
                    let firstPage = args["firstPage"] as? Int ?? 1
                    let lastPage = args["lastPage"] as? Int ?? 999
                    mediaController.updateAudioPageState(bookCode: bookCode, currentPage: currentPage, firstPage: firstPage, lastPage: lastPage)
                }
                result(nil)
            case "audio_completed":
                // iOS'ta audio completion event'ini handle et
                print("🎵 MediaController: Audio completed - notifying Flutter")
                
                // Callback channel üzerinden Flutter'a bildir
                if let callbackChannel = mediaController.callbackChannel {
                    callbackChannel.invokeMethod("audio_completed", arguments: nil) { callbackResult in
                        if let error = callbackResult as? FlutterError {
                            print("❌ MediaController: Audio completion callback error: \(error)")
                        } else {
                            print("✅ MediaController: Audio completion sent to Flutter successfully")
                        }
                    }
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
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
        
        // Media controller'a app state değişikliğini bildir
        mediaController?.handleAppStateChange(isActive: true)
    }
    
    // Uygulama arka plana geçtiğinde widget'ı güncelle
    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        print("Uygulama arka plana geçti - Widget güncelleniyor")
        self.syncDataForWidget()
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        // Media controller'a app state değişikliğini bildir
        mediaController?.handleAppStateChange(isActive: false)
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        super.applicationWillTerminate(application)
        // Media controller'ı temizle
        mediaController?.dispose()
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
