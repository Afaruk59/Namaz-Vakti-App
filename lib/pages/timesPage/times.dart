/*
Copyright [2024] [Afaruk59]

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
import 'package:namaz_vakti_app/pages/timesPage/calendar.dart';
import 'package:namaz_vakti_app/pages/timesPage/city_names.dart';
import 'package:namaz_vakti_app/pages/timesPage/detailed_times.dart';
import 'package:namaz_vakti_app/pages/timesPage/location.dart';
import 'package:namaz_vakti_app/data/change_settings.dart';
import 'package:namaz_vakti_app/pages/timesPage/main_times.dart';
import 'package:namaz_vakti_app/data/time_data.dart';
import 'package:provider/provider.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class Times extends StatelessWidget {
  const Times({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.timesPageTitle),
        actions: [
          const SizedBox(
            width: 20,
          ),
          IconButton(
              iconSize: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 22.0 : 25.0,
              onPressed: () {
                Navigator.pushNamed(context, '/alarms');
              },
              icon: const Icon(
                Icons.alarm,
              )),
          const SizedBox(
            width: 20,
          ),
        ],
      ),
      body: const TimesBody(),
    );
  }
}

class TimesBody extends StatefulWidget {
  const TimesBody({super.key});

  @override
  State<TimesBody> createState() => _TimesBodyState();
}

class _TimesBodyState extends State<TimesBody> {
  String miladi = '';
  String hicri = '';
  int count = 0;
  DateTime customDate = DateTime.now();
  static bool alertOpen = false;

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

  void _checkWifi() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (alertOpen == false) {
        _showWifiAlert();
        alertOpen = true;
      }
    } else {
      Provider.of<TimeData>(context, listen: false).switchClock(true);
      Provider.of<TimeData>(context, listen: false).loadPrayerTimes(DateTime.now());
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
    });

    Provider.of<TimeData>(context, listen: false).changeTime(miladi);
  }

  @override
  void initState() {
    super.initState();
    _checkWifi();
    _changeDate();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.all(Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 0.0 : 5.0),
      child: Column(
        children: [
          Expanded(
            flex: Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 6 : 5,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Card(
                          child: Center(
                            child: Stack(
                              children: [
                                Center(
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                        foregroundColor:
                                            Theme.of(context).textTheme.displayMedium!.color),
                                    onPressed: () async {
                                      var now = DateTime.now();
                                      await _selectDate(context);
                                      Provider.of<TimeData>(context, listen: false)
                                          .switchLoading(true);
                                      setState(() {
                                        count = customDate
                                            .difference(
                                                DateTime(now.year, now.month, now.day, 00, 00))
                                            .inDays;
                                        if (count != 0) {
                                          Provider.of<TimeData>(context, listen: false)
                                              .switchClock(false);
                                        } else {
                                          Provider.of<TimeData>(context, listen: false)
                                              .switchClock(true);
                                        }
                                      });
                                      _changeDate();
                                      Provider.of<TimeData>(context, listen: false).loadPrayerTimes(
                                          DateTime.now().add(Duration(days: count)));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          miladi,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
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
                                            if (DateTime.now().add(Duration(days: count)).day !=
                                                    1 ||
                                                DateTime.now().add(Duration(days: count)).month !=
                                                    1) {
                                              Provider.of<TimeData>(context, listen: false)
                                                  .switchLoading(true);
                                              setState(() {
                                                count--;
                                                if (count != 0) {
                                                  Provider.of<TimeData>(context, listen: false)
                                                      .switchClock(false);
                                                } else {
                                                  Provider.of<TimeData>(context, listen: false)
                                                      .switchClock(true);
                                                }
                                              });
                                              _changeDate();
                                              Provider.of<TimeData>(context, listen: false)
                                                  .loadPrayerTimes(
                                                      DateTime.now().add(Duration(days: count)));
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
                                            if (DateTime.now().add(Duration(days: count)).day !=
                                                    31 ||
                                                DateTime.now().add(Duration(days: count)).month !=
                                                    12) {
                                              Provider.of<TimeData>(context, listen: false)
                                                  .switchLoading(true);
                                              setState(() {
                                                count++;
                                                if (count != 0) {
                                                  Provider.of<TimeData>(context, listen: false)
                                                      .switchClock(false);
                                                } else {
                                                  Provider.of<TimeData>(context, listen: false)
                                                      .switchClock(true);
                                                }
                                              });
                                              _changeDate();
                                              Provider.of<TimeData>(context, listen: false)
                                                  .loadPrayerTimes(
                                                      DateTime.now().add(Duration(days: count)));
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
                        child: Card(
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
                                child: const Column(
                                  children: [
                                    Expanded(
                                      child: Location(),
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
                  ),
                ),
                const Expanded(
                  child: Card(
                    child: Stack(
                      children: [
                        Center(
                          child: CityNameCard(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 11,
            child: Card(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(
                      Provider.of<ChangeSettings>(context).currentHeight! < 700.0 ? 5.0 : 10.0),
                  child: const Stack(
                    children: [
                      PrayerTimesPage(),
                      DetailedTimesBtn(),
                      CalendarBtn(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  PrayerTimesPageState createState() => PrayerTimesPageState();
}

class PrayerTimesPageState extends State<PrayerTimesPage> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Provider.of<TimeData>(context).isLoading
          ? const Center(child: CircularProgressIndicator())
          : const MainTimes(),
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
      style: IconButton.styleFrom(
        shape: const CircleBorder(),
      ),
      icon: const Icon(Icons.search),
      onPressed: () {
        Navigator.pushNamed(context, '/search');
      },
    );
  }
}
