import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/main.dart';

class Seferi extends StatelessWidget {
  const Seferi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seferi Hesabı'),
      ),
      body: SeferiCard(),
    );
  }
}

class SeferiCard extends StatelessWidget {
  const SeferiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
      child: Card(
        child: SizedBox.expand(
          child: Padding(
            padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
            child: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Card(
                    color: Theme.of(context).cardColor,
                    child: Center(
                      child: Text('Harita'),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Card(
                    color: Theme.of(context).cardColor,
                    child: Center(
                      child: Text('Mevcut Konum'),
                    ),
                  ),
                ),
                Card(
                  color: Theme.of(context).cardColor,
                  child: Center(
                    child: SwitchListTile(
                      title: Text('En Kısa Yol / Kuş Uçumu'),
                      value: false,
                      onChanged: (value) {},
                    ),
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
