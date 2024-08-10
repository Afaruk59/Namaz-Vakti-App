import 'package:flutter/material.dart';

class homePage extends StatelessWidget {
  const homePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Namaz Vakti App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            homeCard(
              title: 'Vakitler',
            ),
            homeCard(
              title: 'Title',
            ),
            homeCard(
              title: 'Title',
            ),
            homeCard(
              title: 'Title',
            ),
            homeCard(
              title: 'Title',
            ),
          ],
        ),
      ),
    );
  }
}

class homeCard extends StatelessWidget {
  final String title;

  const homeCard({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Card(
                child: TextButton(
                  style: ButtonStyle(
                    // ignore: deprecated_member_use
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                  onPressed: () {},
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 15,
                        left: 20,
                        child: Text(
                          title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
