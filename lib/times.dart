import 'package:flutter/material.dart';

class Times extends StatelessWidget {
  const Times({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vakitler'),
      ),
      body: TimesBody(),
    );
  }
}

class TimesBody extends StatelessWidget {
  const TimesBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TimesCard(
                          child: Text('Miladi takvim'),
                        ),
                        TimesCard(
                          child: Text('Hicri takvim'),
                        ),
                        TimesCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25.0),
                            child: FilledButton.tonal(
                                onPressed: () {},
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_on),
                                    Text('Güncelle'),
                                  ],
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TimesCard(
                    child: Text('Konum'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: TimesCard(
              child: Text('Kalan vakit'),
            ),
          ),
          TimesCard(
            child: Text('Namaz Vakitleri'),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class TimesCard extends StatelessWidget {
  Widget child;
  TimesCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: SizedBox.expand(
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }
}
