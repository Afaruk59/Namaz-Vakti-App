import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/notification.dart';
import 'package:namaz_vakti_app/themes.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayarlar'),
      ),
      body: SettingsCard(),
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Provider.of<ChangeSettings>(context, listen: false).loadNotFromSharedPref();
    return Padding(
      padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 15.0),
          child: Column(
            children: [
              Card(
                color: Theme.of(context).cardColor,
                child: SwitchListTile(
                  title: Text('Koyu Tema'),
                  value: Provider.of<ChangeSettings>(context).isDark,
                  onChanged: (_) =>
                      Provider.of<ChangeSettings>(context, listen: false).toggleTheme(),
                ),
              ),
              Card(
                color: Theme.of(context).cardColor,
                child: SwitchListTile(
                  title: Text('Kalıcı Bildirim'),
                  value: Provider.of<ChangeSettings>(context).isOpen,
                  onChanged: (_) {
                    Provider.of<ChangeSettings>(context, listen: false).toggleNot();
                    Provider.of<ChangeSettings>(context, listen: false).openNot();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangeSettings with ChangeNotifier {
  static late SharedPreferences _settings;

  bool isDark = false;

  bool isOpen = false;

  static String? id;
  static String? cityName;
  static String? cityState;
  static bool isLocalized = false;

  static bool isfirst = true;

  //THEME SETTINGS
  ThemeData get themeData {
    return isDark ? Themes.darkTheme : Themes.lightTheme;
  }

  void toggleTheme() {
    isDark = !isDark;
    saveThemetoSharedPref(isDark);
    notifyListeners();
  }

  Future<void> createSharedPrefObject() async {
    _settings = await SharedPreferences.getInstance();
  }

  void loadThemeFromSharedPref() {
    isDark = _settings.getBool('darkTheme') ?? false;
    print('loaded: $isDark');
  }

  void saveThemetoSharedPref(bool value) {
    _settings.setBool('darkTheme', value);
    print('saved: $isDark');
  }

  //NOTIFICATION SETTINGS
  void openNot() async {
    if (isOpen == true) {
      NotificationService.showPersistentNotification(0);
    } else {
      await NotificationService.flutterLocalNotificationsPlugin.cancel(0);
    }
  }

  void toggleNot() {
    isOpen = !isOpen;
    saveNottoSharedPref(isOpen);
    notifyListeners();
  }

  void loadNotFromSharedPref() {
    isOpen = _settings.getBool('notification') ?? false;
    print('loaded persistent: $isOpen');
  }

  void saveNottoSharedPref(bool value) {
    _settings.setBool('notification', value);
    print('saved persistent: $isOpen');
  }

  //LOCATION SETTINGS
  void loadLocalFromSharedPref() {
    id = _settings.getString('location') ?? '16741';
    cityName = _settings.getString('name') ?? 'İstanbul Merkez';
    cityState = _settings.getString('state') ?? 'İstanbul';
    print('Loaded: $id');
  }

  void saveLocaltoSharedPref(String value, String name, String state) {
    _settings.setString('location', value);
    _settings.setString('name', name);
    _settings.setString('state', state);
    id = value;
    cityName = name;
    cityState = state;
    print('Saved: $id');
    isLocalized = true;
  }

  //STARTUP SETTINGS
  static void loadFirstFromSharedPref() {
    isfirst = _settings.getBool('startup') ?? true;
    print('First: $isfirst');
  }

  static saveFirsttoSharedPref(bool value) {
    _settings.setBool('startup', value);
    print('First: $isfirst');
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
    return _settings.getStringList('profiles') ?? ['Varsayılan'];
  }

  void saveSelectedProfile(String value) {
    _settings.setString('selectedProfile', value);
  }

  String loadSelectedProfile() {
    return _settings.getString('selectedProfile') ?? 'Varsayılan';
  }
}
