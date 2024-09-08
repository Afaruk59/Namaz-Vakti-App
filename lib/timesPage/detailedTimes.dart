import 'package:flutter/material.dart';
import 'package:namaz_vakti_app/timesPage/times.dart';

class DetailedTimesBtn extends StatelessWidget {
  const DetailedTimesBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 15,
      left: 15,
      child: IconButton(
        iconSize: 25,
        icon: Icon(Icons.menu),
        onPressed: () {
          showModalBottomSheet(
            backgroundColor: Theme.of(context).cardTheme.color,
            context: context,
            showDragHandle: true,
            scrollControlDisabledMaxHeightRatio: 0.7,
            elevation: 10,
            builder: (BuildContext context) {
              return Card(
                color: Theme.of(context).cardColor,
                child: detailedTimes(),
              );
            },
          );
        },
      ),
    );
  }
}
