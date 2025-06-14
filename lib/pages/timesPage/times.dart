/*
Copyright [2024-2025] [Afaruk59]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/components/scaffold_layout.dart';
import 'package:namaz_vakti_app/components/transparent_card.dart';
import 'package:namaz_vakti_app/pages/timesPage/city_names.dart';
import 'package:namaz_vakti_app/pages/timesPage/location.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/pages/timesPage/main_times.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:provider/provider.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class Times extends StatelessWidget {
  const Times({super.key, this.pageIndex = 0});
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return ScaffoldLayout(
      title: AppLocalizations.of(context)!.timesPageTitle,
      actions: [
        const SizedBox(
          width: 20,
        ),
        // Image.asset(
        //   "assets/img/logo.png",
        // ),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/alarms');
          },
          icon: const Icon(
            Icons.alarm,
            size: 24,
          ),
        ),
        const SizedBox(
          width: 20,
        ),
      ],
      body: TimesBody(pageIndex: pageIndex),
    );
  }
}

class TimesBody extends StatefulWidget {
  const TimesBody({super.key, required this.pageIndex});
  final int pageIndex;

  @override
  State<TimesBody> createState() => _TimesBodyState();
}

class _TimesBodyState extends State<TimesBody> {
  static bool alertOpen = false;

  void _checkWifi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (alertOpen == false) {
        _showWifiAlert();
        alertOpen = true;
      }
    } else {
      Provider.of<TimeData>(context, listen: false).switchClock(true);
      Provider.of<TimeData>(context, listen: false).loadPrayerTimes(DateTime.now(), context);
    }
  }

  void _showWifiAlert() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(AppLocalizations.of(context)!.wifiMessageTitle),
          content: Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 100,
                  child: Column(
                    children: [
                      Text(AppLocalizations.of(context)!.wifiMessageBody),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(AppLocalizations.of(context)!.wifiMessageBody2),
                    ],
                  ),
                ),
              ),
              const Expanded(
                flex: 1,
                child: Icon(
                  Icons.wifi_off,
                  size: 45,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.retry),
              onPressed: () {
                Navigator.pop(context);
                alertOpen = false;
                _checkWifi();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkWifi();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.all(Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 0.0 : 5.0),
      child: MediaQuery.of(context).orientation == Orientation.portrait
          ? Column(
              children: [
                Expanded(
                  flex: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 6 : 5,
                  child: Row(
                    children: [
                      Expanded(
                        child: TopTimesCard(pageIndex: widget.pageIndex),
                      ),
                      Expanded(
                        child: TransparentCard(
                          blur: widget.pageIndex == 2 ? true : false,
                          child: const Center(
                            child: CityNameCard(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 11, child: BottomTimesCard(pageIndex: widget.pageIndex)),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 6 : 5,
                  child: Column(
                    children: [
                      Expanded(
                        child: TopTimesCard(pageIndex: widget.pageIndex),
                      ),
                      const Expanded(
                        child: Card(
                          child: Center(
                            child: CityNameCard(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: BottomTimesCard(pageIndex: widget.pageIndex),
                ),
              ],
            ),
    );
  }
}

class TopTimesCard extends StatefulWidget {
  const TopTimesCard({super.key, required this.pageIndex});
  final int pageIndex;

  @override
  State<TopTimesCard> createState() => _TopTimesCardState();
}

class _TopTimesCardState extends State<TopTimesCard> {
  String miladi = '';
  String hicri = '';
  String day = '';
  int count = 0;
  DateTime customDate = DateTime.now();

  List<String> hijriList = [
    'Muharrem',
    'Safer',
    'Rebiülevvel',
    'Rebiülahir',
    'Cemayizelevvel',
    'Cemayizelahir',
    'Recep',
    'Şaban',
    'Ramazan',
    'Şevval',
    'Zilkade',
    'Zilhicce'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year, 1, 1),
      lastDate: DateTime(DateTime.now().year, 12, 31),
    );

    if (pickedDate != null && pickedDate != customDate) {
      setState(() {
        customDate = pickedDate;
      });
    }
  }

  void _changeDate() {
    setState(() {
      miladi =
          DateFormat('dd MMMM yyyy', Provider.of<ChangeSettings>(context, listen: false).langCode)
              .format(DateTime.now().add(Duration(days: count)));
      if (Provider.of<ChangeSettings>(context, listen: false).langCode == 'tr') {
        hicri =
            '${HijriCalendar.fromDate(DateTime.now().add(Duration(days: count))).toFormat('dd')} ${hijriList[HijriCalendar.fromDate(DateTime.now().add(Duration(days: count))).hMonth - 1]} ${HijriCalendar.fromDate(DateTime.now().add(Duration(days: count))).toFormat('yy')}';
      } else {
        hicri = HijriCalendar.fromDate(DateTime.now().add(Duration(days: count)))
            .toFormat('dd MMMM yy');
      }
      day = DateFormat('EEEE', Provider.of<ChangeSettings>(context, listen: false).langCode)
          .format(DateTime.now().add(Duration(days: count)));
    });

    Provider.of<TimeData>(context, listen: false).changeTime(miladi);
  }

  @override
  void initState() {
    super.initState();
    _changeDate();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: TransparentCard(
            blur: widget.pageIndex == 2 ? true : false,
            child: Center(
              child: Stack(
                children: [
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).textTheme.displayMedium!.color),
                      onPressed: () async {
                        var now = DateTime.now();
                        await _selectDate(context);
                        Provider.of<TimeData>(context, listen: false).switchLoading(true);
                        setState(() {
                          count = customDate
                              .difference(DateTime(now.year, now.month, now.day, 00, 00))
                              .inDays;
                          if (count != 0) {
                            Provider.of<TimeData>(context, listen: false).switchClock(false);
                          } else {
                            Provider.of<TimeData>(context, listen: false).switchClock(true);
                          }
                        });
                        _changeDate();
                        Provider.of<TimeData>(context, listen: false)
                            .loadPrayerTimes(DateTime.now().add(Duration(days: count)), context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                miladi,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (DateTime.now().add(Duration(days: count)).day != 1 ||
                                  DateTime.now().add(Duration(days: count)).month != 1) {
                                Provider.of<TimeData>(context, listen: false).switchLoading(true);
                                setState(() {
                                  count--;
                                  if (count != 0) {
                                    Provider.of<TimeData>(context, listen: false)
                                        .switchClock(false);
                                  } else {
                                    Provider.of<TimeData>(context, listen: false).switchClock(true);
                                  }
                                });
                                _changeDate();
                                Provider.of<TimeData>(context, listen: false).loadPrayerTimes(
                                    DateTime.now().add(Duration(days: count)), context);
                              }
                            },
                            icon: const Icon(Icons.arrow_back_ios_new),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (DateTime.now().add(Duration(days: count)).day != 31 ||
                                  DateTime.now().add(Duration(days: count)).month != 12) {
                                Provider.of<TimeData>(context, listen: false).switchLoading(true);
                                setState(() {
                                  count++;
                                  if (count != 0) {
                                    Provider.of<TimeData>(context, listen: false)
                                        .switchClock(false);
                                  } else {
                                    Provider.of<TimeData>(context, listen: false).switchClock(true);
                                  }
                                });
                                _changeDate();
                                Provider.of<TimeData>(context, listen: false).loadPrayerTimes(
                                    DateTime.now().add(Duration(days: count)), context);
                              }
                            },
                            icon: const Icon(Icons.arrow_forward_ios),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: TransparentCard(
            blur: widget.pageIndex == 2 ? true : false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    textAlign: TextAlign.center,
                    hicri,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Column(
                    children: [
                      Expanded(
                        child: Location(
                          title: AppLocalizations.of(context)!.locationButtonText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Column(
                  children: [
                    Expanded(
                      child: SearchButton(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BottomTimesCard extends StatelessWidget {
  const BottomTimesCard({super.key, required this.pageIndex});
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TransparentCard(
        blur: pageIndex == 2 ? true : false,
        child: Provider.of<TimeData>(context).isLoading
            ? const Center(child: CircularProgressIndicator())
            : const MainTimes(),
      ),
    );
  }
}

class SearchButton extends StatelessWidget {
  const SearchButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () {
        Navigator.pushNamed(context, '/search');
      },
    );
  }
}
