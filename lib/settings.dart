import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/notification.dart';
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
              Card(
                color: Theme.of(context).cardColor,
                child: ListTile(
                  title: Text('Renk'),
                  trailing: FilledButton.tonal(
                    style: ElevatedButton.styleFrom(
                      elevation: 10,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Renk Seçimi"),
                          content: Container(
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
                              child: Text('Tamam'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Icon(Icons.color_lens),
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
        shape: CircleBorder(),
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
  bool isOpen = false;
  MaterialColor color = Colors.blueGrey;

  static String? id;
  static String? cityName;
  static String? cityState;
  static bool isLocalized = false;

  static bool isfirst = true;

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

  void changeCol(MaterialColor col) {
    color = col;
    print('Color: $color');
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
