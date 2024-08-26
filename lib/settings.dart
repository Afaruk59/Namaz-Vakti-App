import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/notification.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayarlar'),
      ),
      body: ChangeNotifierProvider<ChangeNotification>(
          create: (context) => ChangeNotification(), child: SettingsCard()),
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Provider.of<ChangeNotification>(context, listen: false).loadNotFromSharedPref();
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
                  value: Provider.of<changeTheme>(context).isDark,
                  onChanged: (_) => Provider.of<changeTheme>(context, listen: false).toggleTheme(),
                ),
              ),
              Card(
                color: Theme.of(context).cardColor,
                child: SwitchListTile(
                  title: Text('Kalıcı Bildirim'),
                  value: Provider.of<ChangeNotification>(context).isOpen,
                  onChanged: (_) {
                    Provider.of<ChangeNotification>(context, listen: false).toggleNot();
                    Provider.of<ChangeNotification>(context, listen: false).openNot();
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
