import 'package:flutter/material.dart';

class Qibla extends StatelessWidget {
  const Qibla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kıble Pusulası'),
      ),
      body: QiblaCard(),
    );
  }
}

class QiblaCard extends StatelessWidget {
  const QiblaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Card(
                        color: Theme.of(context).cardColor,
                        child: SizedBox.expand(child: Center(child: Text('Pusula'))),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Card(
                        color: Theme.of(context).cardColor,
                        child: SizedBox.expand(child: Center(child: Text('Mevcut Konum'))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
