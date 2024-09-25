import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsPageTitle),
      ),
      body: const SettingsCard(),
    );
  }
}

class SettingsCard extends StatelessWidget {
  static Locale? preLang;
  const SettingsCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    preLang = Provider.of<ChangeSettings>(context).locale;
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 15.0),
          child: Column(
            children: [
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.ln),
                    subtitle: Text(AppLocalizations.of(context)!.lang),
                    trailing: PopupMenuButton<int>(
                      elevation: 10,
                      enabled: true,
                      onSelected: (int result) {
                        Provider.of<ChangeSettings>(context, listen: false).saveLanguage(result);
                      },
                      color: Theme.of(context).cardTheme.color!,
                      itemBuilder: (context) {
                        return <PopupMenuEntry<int>>[
                          const PopupMenuItem<int>(
                            value: 0,
                            child: Center(
                              child: Text(
                                'Türkçe',
                              ),
                            ),
                          ),
                          const PopupMenuItem<int>(
                            value: 1,
                            child: Center(
                              child: Text(
                                'English',
                              ),
                            ),
                          ),
                          const PopupMenuItem<int>(
                            value: 2,
                            child: Center(
                              child: Text(
                                'عربي',
                              ),
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.darkMode),
                    value: Provider.of<ChangeSettings>(context).isDark,
                    onChanged: (_) =>
                        Provider.of<ChangeSettings>(context, listen: false).toggleTheme(),
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.gradient),
                    value: Provider.of<ChangeSettings>(context).gradient,
                    onChanged: (_) =>
                        Provider.of<ChangeSettings>(context, listen: false).toggleGrad(),
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: ListTile(
                    title: Text(AppLocalizations.of(context)!.themeColor),
                    trailing: FilledButton.tonal(
                      style: ElevatedButton.styleFrom(
                        elevation: 10,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.colorPaletteTitle),
                            content: const SizedBox(
                              height: 200,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        ColorCircle(col: Colors.blueGrey),
                                        ColorCircle(col: Colors.red),
                                        ColorCircle(col: Colors.blue),
                                        ColorCircle(col: Colors.green),
                                        ColorCircle(col: Colors.yellow),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        ColorCircle(col: Colors.amber),
                                        ColorCircle(col: Colors.grey),
                                        ColorCircle(col: Colors.indigo),
                                        ColorCircle(col: Colors.lightBlue),
                                        ColorCircle(col: Colors.lightGreen),
                                        ColorCircle(col: Colors.lime),
                                        ColorCircle(col: Colors.orange),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        ColorCircle(col: Colors.pink),
                                        ColorCircle(col: Colors.purple),
                                        ColorCircle(col: Colors.teal),
                                        ColorCircle(col: Colors.brown),
                                        ColorCircle(col: Colors.cyan),
                                        ColorCircle(col: Colors.deepOrange),
                                        ColorCircle(col: Colors.deepPurple),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(AppLocalizations.of(context)!.ok),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Icon(Icons.color_lens),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ColorCircle extends StatelessWidget {
  const ColorCircle({super.key, required this.col});
  final MaterialColor col;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: const CircleBorder(),
        color: col,
        child: TextButton(
          child: Container(),
          onPressed: () {
            Provider.of<ChangeSettings>(context, listen: false).changeCol(col);
            Provider.of<ChangeSettings>(context, listen: false).saveCol(col);
          },
        ),
      ),
    );
  }
}

class ChangeSettings with ChangeNotifier {
  static late SharedPreferences _settings;

  bool isDark = false;
  MaterialColor color = Colors.blueGrey;
  bool gradient = true;

  static String? cityID;
  static String? cityName;
  static String? cityState;
  static bool isLocalized = false;

  static bool isfirst = true;

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

  //LANGUAGE

  void loadLanguage() {
    locale = Locale(_settings.getString('lang') ?? 'tr');
    langCode = _settings.getString('lang') ?? 'tr';
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
    }
    notifyListeners();
  }

  //ALARMS & NOTIFICATIONS

  void loadGaps() {
    for (int i = 0; i < 7; i++) {
      gaps[i] = _settings.getInt('${i}gap') ?? 0;
    }
  }

  void saveGap(int index, int gap) {
    gaps[index] = gap;
    _settings.setInt('${index}gap', gap);
    notifyListeners();
  }

  void falseAll() {
    for (int i = 0; i < 7; i++) {
      alarmList[i] = false;
      _settings.setBool('$i', false);
    }
    notifyListeners();
  }

  void toggleAlarm(int index) {
    if (_settings.getBool('notification') ?? false) {
      alarmList[index] = !alarmList[index];
      _settings.setBool('$index', alarmList[index]);
      notifyListeners();
    }
  }

  void loadAlarm() {
    for (int i = 0; i < 7; i++) {
      alarmList[i] = _settings.getBool('$i') ?? false;
    }
  }

  void toggleNot() {
    isOpen = !isOpen;
    saveNottoSharedPref(isOpen);
    notifyListeners();
  }

  void loadNotFromSharedPref() {
    isOpen = _settings.getBool('notification') ?? false;
  }

  void saveNottoSharedPref(bool value) {
    _settings.setBool('notification', value);
  }

  //THEME SETTINGS

  void toggleGrad() {
    gradient = !gradient;
    saveGradtoSharedPref(gradient);
    notifyListeners();
  }

  void loadGradFromSharedPref() {
    gradient = _settings.getBool('gradient') ?? true;
  }

  void saveGradtoSharedPref(bool value) {
    _settings.setBool('gradient', value);
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
  }

  void saveThemetoSharedPref(bool value) {
    _settings.setBool('darkTheme', value);
  }

  void changeCol(MaterialColor col) {
    color = col;
    notifyListeners();
  }

  void loadCol() {
    int value = _settings.getInt('color') ?? 0;
    switch (value) {
      case 0:
        color = Colors.blueGrey;
      case 1:
        color = Colors.red;
      case 2:
        color = Colors.blue;
      case 3:
        color = Colors.green;
      case 4:
        color = Colors.yellow;
      case 5:
        color = Colors.amber;
      case 6:
        color = Colors.grey;
      case 7:
        color = Colors.indigo;
      case 8:
        color = Colors.lightBlue;
      case 9:
        color = Colors.lightGreen;
      case 10:
        color = Colors.lime;
      case 11:
        color = Colors.orange;
      case 12:
        color = Colors.pink;
      case 13:
        color = Colors.purple;
      case 14:
        color = Colors.teal;
      case 15:
        color = Colors.brown;
      case 16:
        color = Colors.cyan;
      case 17:
        color = Colors.deepOrange;
      case 18:
        color = Colors.deepPurple;
    }
  }

  void saveCol(MaterialColor color) {
    switch (color) {
      case Colors.blueGrey:
        _settings.setInt('color', 0);
      case Colors.red:
        _settings.setInt('color', 1);
      case Colors.blue:
        _settings.setInt('color', 2);
      case Colors.green:
        _settings.setInt('color', 3);
      case Colors.yellow:
        _settings.setInt('color', 4);
      case Colors.amber:
        _settings.setInt('color', 5);
      case Colors.grey:
        _settings.setInt('color', 6);
      case Colors.indigo:
        _settings.setInt('color', 7);
      case Colors.lightBlue:
        _settings.setInt('color', 8);
      case Colors.lightGreen:
        _settings.setInt('color', 9);
      case Colors.lime:
        _settings.setInt('color', 10);
      case Colors.orange:
        _settings.setInt('color', 11);
      case Colors.pink:
        _settings.setInt('color', 12);
      case Colors.purple:
        _settings.setInt('color', 13);
      case Colors.teal:
        _settings.setInt('color', 14);
      case Colors.brown:
        _settings.setInt('color', 15);
      case Colors.cyan:
        _settings.setInt('color', 16);
      case Colors.deepOrange:
        _settings.setInt('color', 17);
      case Colors.deepPurple:
        _settings.setInt('color', 18);
    }
  }

  //LOCATION SETTINGS
  void loadLocalFromSharedPref() {
    cityID = _settings.getString('location') ?? '16741';
    cityName = _settings.getString('name') ?? 'Merkez';
    cityState = _settings.getString('state') ?? 'İstanbul';
  }

  void saveLocaltoSharedPref(String value, String name, String state) {
    _settings.setString('location', value);
    _settings.setString('name', name);
    _settings.setString('state', state);
    cityID = value;
    cityName = name;
    cityState = state;
    isLocalized = true;
  }

  //STARTUP SETTINGS
  void loadFirstFromSharedPref() {
    isfirst = _settings.getBool('startup') ?? true;
  }

  saveFirsttoSharedPref(bool value) {
    _settings.setBool('startup', value);
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
}
