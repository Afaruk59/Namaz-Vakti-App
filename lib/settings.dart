import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:provider/provider.dart';

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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Card(
                  color: Theme.of(context).cardColor,
                  child: SwitchListTile(
                    title: Text('Koyu Tema'),
                    value: Provider.of<changeTheme>(context).isDark,
                    onChanged: (_) =>
                        Provider.of<changeTheme>(context, listen: false).toggleTheme(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
