/*
Copyright [2024-2025] [Afaruk59]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ChangeSettings with ChangeNotifier {
  static late SharedPreferences _settings;
  String version = '1.5.1';

  bool otoLocal = false;

  double? currentHeight;

  bool isDark = false;
  int themeIndex = 0;
  Color color = Colors.blueGrey[500]!;

  String? cityID;
  String? cityName;
  String? cityState;

  bool isfirst = true;

  bool isOpen = false;
  List<bool> alarmList = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];
  List<int> gaps = [0, 0, 0, 0, 0, 0, 0];

  Locale? locale;
  String? langCode;

  bool rounded = false;

  bool notificationsEnabled = false;
  bool lockScreenEnabled = false;

  List<int> alarmVoices = [0, 0, 0, 0, 0, 0, 0];

  //LOAD PROFILE
  void loadProfileFromSharedPref(BuildContext context) {
    //LOCATION
    cityID = _settings.getString('location') ?? '16741';
    cityName = _settings.getString('name') ?? 'Merkez';
    cityState = _settings.getString('state') ?? 'İstanbul';
    otoLocal = _settings.getBool('otoLocation') ?? false;

    //COLOR
    color = _settings.getString('Color')?.toColor() ?? Colors.blueGrey[500]!;

    //THEME
    themeIndex = _settings.getInt('themeIndex') ?? 0;
    switch (themeIndex) {
      case 0:
        try {
          if (Platform.isIOS) {
            final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
            isDark = brightness == Brightness.dark;
          } else {
            isDark = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
          }
        } catch (e) {
          isDark = false;
        }
        break;
      case 1:
        isDark = true;
        break;
      case 2:
        isDark = false;
        break;
    }

    //STARTUP
    isfirst = _settings.getBool('startup') ?? true;

    //LANGUAGE
    String defaultLang;
    try {
      if (Platform.isIOS) {
        defaultLang = PlatformDispatcher.instance.locale.languageCode;
      } else {
        defaultLang = PlatformDispatcher.instance.locale.languageCode;
      }
    } catch (e) {
      defaultLang = 'en';
    }
    if (!['tr', 'en', 'ar', 'de', 'es', 'fr', 'it', 'ru'].contains(defaultLang)) {
      defaultLang = 'en';
    }
    locale = Locale(_settings.getString('lang') ?? defaultLang);
    langCode = _settings.getString('lang') ?? defaultLang;

    //ALARMS
    for (int i = 0; i < 7; i++) {
      alarmList[i] = _settings.getBool('$i') ?? false;
      alarmVoices[i] = _settings.getInt('${i}voice') ?? 0;
      gaps[i] = _settings.getInt('${i}gap') ?? 0;
    }

    //SHAPE
    rounded = _settings.getBool('Shape') ?? true;

    //NOTIFICATIONS
    notificationsEnabled = _settings.getBool('notifications') ?? false;
    lockScreenEnabled = _settings.getBool('lockScreen') ?? false;

    //HEIGHT
    currentHeight = MediaQuery.of(context).size.height;
  }

  //SHAPE
  void toggleShape() {
    rounded = !rounded;
    saveShape(rounded);
    notifyListeners();
  }

  void saveShape(bool value) {
    _settings.setBool('Shape', value);
  }

  void saveLanguage(int val) {
    switch (val) {
      case 0:
        _settings.setString('lang', 'tr');
        locale = const Locale('tr');
        langCode = 'tr';
      case 1:
        _settings.setString('lang', 'en');
        locale = const Locale('en');
        langCode = 'en';
      case 2:
        _settings.setString('lang', 'ar');
        locale = const Locale('ar');
        langCode = 'ar';
      case 3:
        _settings.setString('lang', 'de');
        locale = const Locale('de');
        langCode = 'de';
      case 4:
        _settings.setString('lang', 'es');
        locale = const Locale('es');
        langCode = 'es';
      case 5:
        _settings.setString('lang', 'fr');
        locale = const Locale('fr');
        langCode = 'fr';
      case 6:
        _settings.setString('lang', 'it');
        locale = const Locale('it');
        langCode = 'it';
      case 7:
        _settings.setString('lang', 'ru');
        locale = const Locale('ru');
        langCode = 'ru';
    }
    notifyListeners();
  }

  //ALARMS
  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    _settings.setBool('notifications', value);
    notifyListeners();
  }

  void toggleLockScreen(bool value) {
    lockScreenEnabled = value;
    _settings.setBool('lockScreen', value);
    notifyListeners();
  }

  void saveVoice(int index, int voice) {
    alarmVoices[index] = voice;
    _settings.setInt('${index}voice', voice);
    notifyListeners();
  }

  void saveGap(int index, int gap) {
    gaps[index] = gap;
    _settings.setInt('${index}gap', gap);
    notifyListeners();
  }

  void toggleAlarm(int index) {
    alarmList[index] = !alarmList[index];
    _settings.setBool('$index', alarmList[index]);
    notifyListeners();
  }

  void enableAllAlarms() {
    for (int i = 0; i < 7; i++) {
      alarmList[i] = true;
      _settings.setBool('$i', true);
    }
    notifyListeners();
  }

  void disableAllAlarms() {
    for (int i = 0; i < 7; i++) {
      alarmList[i] = false;
      _settings.setBool('$i', false);
    }
    notifyListeners();
  }

  //THEME SETTINGS
  void toggleTheme(int index) {
    themeIndex = index;
    switch (index) {
      case 0:
        // iOS ve Android için platform-safe tema tespiti
        try {
          if (Platform.isIOS) {
            // iOS için UIUserInterfaceStyle izni ile tema tespiti
            final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
            isDark = brightness == Brightness.dark;
          } else {
            isDark = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
          }
        } catch (e) {
          // Fallback: varsayılan olarak açık tema
          isDark = false;
        }
        break;
      case 1:
        isDark = true;
        break;
      case 2:
        isDark = false;
        break;
    }
    saveThemetoSharedPref(themeIndex);
    notifyListeners();
  }

  Future<void> createSharedPrefObject() async {
    _settings = await SharedPreferences.getInstance();
  }

  void saveThemetoSharedPref(int index) {
    _settings.setInt('themeIndex', index);
  }

  void changeCol(Color col) {
    color = col;
    notifyListeners();
  }

  void saveCol(Color color) {
    _settings.setString('Color', color.toHexString());
  }

  //LOCATION SETTINGS
  void saveLocaltoSharedPref(String value, String name, String state) {
    _settings.setString('location', value);
    _settings.setString('name', name);
    _settings.setString('state', state);
    cityID = value;
    cityName = name;
    cityState = state;
    notifyListeners();
  }

  void toggleOtoLoc() {
    otoLocal = !otoLocal;
    saveOtoLoc(otoLocal);
    notifyListeners();
  }

  void changeOtoLoc(bool val) {
    otoLocal = val;
    saveOtoLoc(otoLocal);
    notifyListeners();
  }

  void saveOtoLoc(bool val) {
    _settings.setBool('otoLocation', val);
  }

  //STARTUP SETTINGS
  saveFirsttoSharedPref(bool value) {
    _settings.setBool('startup', value);
    notifyListeners();
  }

  //KAZA SETTINGS
  int loadKaza(String name) {
    return _settings.getInt(name) ?? 0;
  }

  void saveKaza(String name, int value) {
    _settings.setInt(name, value);
  }

  //ZIKIR SETTINGS
  void saveVib(bool value) {
    _settings.setBool('vibration', value);
  }

  bool loadVib() {
    return _settings.getBool('vibration') ?? false;
  }

  void saveZikirProfile(String name, int count, int set, int stack) {
    _settings.setInt('${name}count', count);
    _settings.setInt('${name}set', set);
    _settings.setInt('${name}stack', stack);
  }

  int loadZikirCount(String name) {
    return _settings.getInt('${name}count') ?? 0;
  }

  int loadZikirSet(String name) {
    return _settings.getInt('${name}set') ?? 33;
  }

  int loadZikirStack(String name) {
    return _settings.getInt('${name}stack') ?? 0;
  }

  void saveProfiles(List<String> list) {
    _settings.setStringList('profiles', list);
  }

  List<String> loadProfiles() {
    return _settings.getStringList('profiles') ?? [' '];
  }

  void saveSelectedProfile(String value) {
    _settings.setString('selectedProfile', value);
  }

  String loadSelectedProfile() {
    return _settings.getString('selectedProfile') ?? ' ';
  }

  // JSON YEDEKLEME VE GERİ YÜKLEME FONKSİYONLARI

  Map<String, dynamic> _getAllSettings() {
    final keys = _settings.getKeys();
    final Map<String, dynamic> settingsMap = {};

    for (String key in keys) {
      final value = _settings.get(key);
      settingsMap[key] = value;
    }

    return settingsMap;
  }

  Future<bool> _loadSettingsFromMap(Map<String, dynamic> settingsMap) async {
    try {
      for (String key in settingsMap.keys) {
        final value = settingsMap[key];

        // Güvenlik önlemi: notifications ayarını her zaman false olarak yükle
        if (key == 'notifications') {
          await _settings.setBool(key, false);
          debugPrint('Güvenlik önlemi: notifications ayarı false olarak yüklendi');
          continue;
        }

        if (value is String) {
          await _settings.setString(key, value);
        } else if (value is int) {
          await _settings.setInt(key, value);
        } else if (value is double) {
          await _settings.setDouble(key, value);
        } else if (value is bool) {
          await _settings.setBool(key, value);
        } else if (value is List<String>) {
          await _settings.setStringList(key, value);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Ayarlar yüklenirken hata oluştu: $e');
      return false;
    }
  }

  Future<bool> importSettingsFromJson(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('Dosya bulunamadı: $filePath');
        return false;
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> settingsMap = jsonDecode(jsonString);

      return await _loadSettingsFromMap(settingsMap);
    } catch (e) {
      debugPrint('Ayarlar içe aktarılırken hata oluştu: $e');
      return false;
    }
  }

  /// Ayarları geçici klasöre kaydedip paylaşma seçeneği sunar
  Future<String?> exportSettingsWithShare() async {
    try {
      final settingsMap = _getAllSettings();
      final jsonString = jsonEncode(settingsMap);

      // Geçici klasöre dosya kaydet
      final directory = await getTemporaryDirectory();
      final fileName = 'nva_settings_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);

      // Dosyayı paylaş (kullanıcı istediği uygulamayı seçebilir)
      await SharePlus.instance.share(ShareParams(
        text: 'Namaz Vakti App',
        subject: 'Uygulama Ayarları Yedek Dosyası',
        files: [XFile(file.path)],
      ));

      return file.path;
    } catch (e) {
      debugPrint('Ayarlar dışa aktarılırken hata oluştu: $e');
      return null;
    }
  }

  /// Kullanıcının seçtiği klasöre kaydetme
  Future<String?> exportSettingsWithFilePicker() async {
    try {
      final settingsMap = _getAllSettings();
      final jsonString = jsonEncode(settingsMap);

      // Kullanıcıdan klasör seçmesini iste
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Kaydetmek istediğiniz klasörü seçin',
      );

      if (selectedDirectory != null) {
        final fileName = 'nva_settings_${DateTime.now().millisecondsSinceEpoch}.json';
        final file = File('$selectedDirectory/$fileName');

        await file.writeAsString(jsonString);
        debugPrint('Dosya kaydedildi: ${file.path}');

        return file.path;
      }

      return null; // Kullanıcı iptal etti
    } catch (e) {
      debugPrint('Ayarlar dışa aktarılırken hata oluştu: $e');
      return null;
    }
  }

  Future<bool> importSettingsWithFilePicker() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Yedek Dosyası Seçin',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        return await importSettingsFromJson(filePath);
      }
      return false;
    } catch (e) {
      debugPrint('Ayarlar içe aktarılırken hata oluştu: $e');
      return false;
    }
  }
}
