import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/pages/timesPage/calendar.dart';
import 'package:namaz_vakti_app/pages/timesPage/detailed_times.dart';
import 'package:namaz_vakti_app/pages/timesPage/location.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/pages/settings.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:http/http.dart' as http;
import 'package:hijri/hijri_calendar.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class TimeData extends ChangeSettings {
  DateTime? yatsi2;
  DateTime? imsak2;
  DateTime? imsak;
  DateTime? sabah;
  DateTime? gunes;
  DateTime? ogle;
  DateTime? ikindi;
  DateTime? aksam;
  DateTime? yatsi;
  DateTime? israk;
  DateTime? kerahat;
  DateTime? asrisani;
  DateTime? isfirar;
  DateTime? istibak;
  DateTime? isaisani;
  DateTime? kible;
  String? city;
  String? cityState;

  List<Map<String, String>> prayerTimes = [];
  Map<String, String>? selectedDayTimes;
  DateTime? selectedDate;
  bool isLoading = true;

  bool isTimeLoading = true;

  String clock = '';
  Duration difference = const Duration(minutes: 1);
  int pray = 0;
  DateTime soontime = DateTime.now();
  bool hour = true;
  bool minute = true;
  DateTime preTime = DateTime.now();
  Duration mainDifference = const Duration(minutes: 1);
  bool isEnabled = true;

  String miladi = DateFormat('dd MMMM yyyy').format(DateTime.now());

  void selectDate(DateTime time) {
    final DateTime picked = time;

    selectedDate = picked;
    final formattedDate = DateFormat('d/M').format(picked);
    selectedDayTimes = prayerTimes.firstWhere(
      (pt) => '${pt['day']}/${pt['month']}' == formattedDate,
      orElse: () => {},
    );
    notifyListeners();
  }

  Future<void> loadPrayerTimes(DateTime time) async {
    String url =
        'https://www.namazvakti.com/XML.php?cityID=${ChangeSettings.cityID}'; // Çevrimiçi XML dosyasının URL'si
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = response.body;
      final document = xml.XmlDocument.parse(data);

      final cityinfo = document.findAllElements('cityinfo').first;
      final prayertimes = cityinfo.findAllElements('prayertimes');

      prayerTimes = prayertimes.map((pt) {
        // ignore: deprecated_member_use
        final times = pt.text.split(RegExp(r'\s+'));
        return {
          'day': pt.getAttribute('day') ?? '',
          'month': pt.getAttribute('month') ?? '',
          'imsak': times.isNotEmpty ? times[0] : '',
          'sabah': times.length > 1 ? times[1] : '',
          'güneş': times.length > 2 ? times[2] : '',
          'işrak': times.length > 3 ? times[3] : '',
          'kerahat': times.length > 4 ? times[4] : '',
          'öğle': times.length > 5 ? times[5] : '',
          'ikindi': times.length > 6 ? times[6] : '',
          'asrisani': times.length > 7 ? times[7] : '',
          'isfirar': times.length > 8 ? times[8] : '',
          'akşam': times.length > 9 ? times[9] : '',
          'iştibak': times.length > 10 ? times[10] : '',
          'yatsı': times.length > 11 ? times[11] : '',
          'işaisani': times.length > 12 ? times[12] : '',
          'kıble': times.length > 13 ? times[13] : '',
        };
      }).toList();
      isLoading = false;

      selectDate(time);
      try {
        imsak = DateFormat('HH:mm').parse((selectedDayTimes?['imsak']).toString());
      } on Exception catch (_) {
        imsak = null;
      }
      try {
        sabah = DateFormat('HH:mm').parse((selectedDayTimes?['sabah']).toString());
      } on Exception catch (_) {
        sabah = null;
      }
      try {
        gunes = DateFormat('HH:mm').parse((selectedDayTimes?['güneş']).toString());
      } on Exception catch (_) {
        gunes = null;
      }
      try {
        ogle = DateFormat('HH:mm').parse((selectedDayTimes?['öğle']).toString());
      } on Exception catch (_) {
        ogle = null;
      }
      try {
        ikindi = DateFormat('HH:mm').parse((selectedDayTimes?['ikindi']).toString());
      } on Exception catch (_) {
        ikindi = null;
      }
      try {
        aksam = DateFormat('HH:mm').parse((selectedDayTimes?['akşam']).toString());
      } on Exception catch (_) {
        aksam = null;
      }
      try {
        yatsi = DateFormat('HH:mm').parse((selectedDayTimes?['yatsı']).toString());
      } on Exception catch (_) {
        yatsi = null;
      }

      try {
        israk = DateFormat('HH:mm').parse((selectedDayTimes?['işrak']).toString());
      } on Exception catch (_) {
        israk = null;
      }
      try {
        kerahat = DateFormat('HH:mm').parse((selectedDayTimes?['kerahat']).toString());
      } on Exception catch (_) {
        kerahat = null;
      }
      try {
        asrisani = DateFormat('HH:mm').parse((selectedDayTimes?['asrisani']).toString());
      } on Exception catch (_) {
        asrisani = null;
      }
      try {
        isfirar = DateFormat('HH:mm').parse((selectedDayTimes?['isfirar']).toString());
      } on Exception catch (_) {
        isfirar = null;
      }
      try {
        istibak = DateFormat('HH:mm').parse((selectedDayTimes?['iştibak']).toString());
      } on Exception catch (_) {
        istibak = null;
      }
      try {
        isaisani = DateFormat('HH:mm').parse((selectedDayTimes?['işaisani']).toString());
      } on Exception catch (_) {
        isaisani = null;
      }
      try {
        kible = DateFormat('HH:mm').parse((selectedDayTimes?['kıble']).toString());
      } on Exception catch (_) {
        kible = null;
      }

      selectDate(time.add(const Duration(days: 1)));
      try {
        imsak2 = DateFormat('HH:mm').parse((selectedDayTimes?['imsak']).toString());
      } on Exception catch (_) {
        imsak2 = null;
      }
      selectDate(time.subtract(const Duration(days: 1)));
      try {
        yatsi2 = DateFormat('HH:mm').parse((selectedDayTimes?['yatsı']).toString());
      } on Exception catch (_) {
        yatsi2 = null;
      }
      isTimeLoading = false;
      notifyListeners();
    }
  }

  void switchClock(bool value) {
    if (value) {
      isEnabled = true;
    } else {
      isEnabled = false;
    }
  }

  void switchLoading(bool value) {
    if (value) {
      isLoading = true;
    } else {
      isLoading = false;
    }

    notifyListeners();
  }

  void updateTime() {
    DateTime now = DateTime.now();
    clock = DateFormat('HH:mm:ss').format(now);

    if (isTimeLoading == false && imsak != null) {
      if (DateTime(now.year, now.month, now.day, imsak!.hour, imsak!.minute, 0).difference(now) >
          DateTime.now().difference(now)) {
        pray = 0;
        soontime = imsak!;
        preTime = yatsi2!;
      } else if (DateTime(now.year, now.month, now.day, sabah!.hour, sabah!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 1;
        soontime = sabah!;
        preTime = imsak!;
      } else if (DateTime(now.year, now.month, now.day, gunes!.hour, gunes!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 2;
        soontime = gunes!;
        preTime = sabah!;
      } else if (DateTime(now.year, now.month, now.day, ogle!.hour, ogle!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 3;
        soontime = ogle!;
        preTime = gunes!;
      } else if (DateTime(now.year, now.month, now.day, ikindi!.hour, ikindi!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 4;
        soontime = ikindi!;
        preTime = ogle!;
      } else if (DateTime(now.year, now.month, now.day, aksam!.hour, aksam!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 5;
        soontime = aksam!;
        preTime = ikindi!;
      } else if (DateTime(now.year, now.month, now.day, yatsi!.hour, yatsi!.minute, 0)
              .difference(now) >
          DateTime.now().difference(now)) {
        pray = 6;
        soontime = yatsi!;
        preTime = aksam!;
      } else {
        pray = 7;
        soontime = imsak2!;
        preTime = yatsi!;
      }

      if (soontime == imsak2) {
        mainDifference = DateTime(1970, 1, 2, soontime.hour, soontime.minute, soontime.second)
            .difference(preTime);
        difference = soontime.difference(DateTime(1969, 12, 31, now.hour, now.minute, now.second));
      } else if (soontime == imsak) {
        mainDifference = DateTime(1970, 1, 2, soontime.hour, soontime.minute, soontime.second)
            .difference(preTime);
        difference = soontime.difference(DateTime(1970, 1, 1, now.hour, now.minute, now.second));
      } else {
        mainDifference = soontime.difference(preTime);
        difference = soontime.difference(DateTime(1970, 1, 1, now.hour, now.minute, now.second));
      }
      notifyListeners();
    }
  }

  void changeTime(String time) {
    miladi = time;
  }
}

class Times extends StatelessWidget {
  const Times({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.timesPageTitle),
        // actions: [
        //   IconButton(
        //       iconSize: MainApp.currentHeight! < 700.0 ? 22.0 : 25.0,
        //       onPressed: () {
        //         Navigator.pushNamed(context, '/alarms');
        //       },
        //       icon: const Icon(
        //         Icons.alarm,
        //       )),
        //   const SizedBox(
        //     width: 20,
        //   ),
        // ],
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

  @override
  void initState() {
    super.initState();
    miladi =
        DateFormat('dd MMMM yyyy', Provider.of<ChangeSettings>(context, listen: false).langCode)
            .format(DateTime.now());
    hicri = HijriCalendar.fromDate(DateTime.now()).toFormat('dd MMMM yy');
    Provider.of<TimeData>(context, listen: false).changeTime(miladi);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 0.0 : 5.0),
      child: Column(
        children: [
          Expanded(
            flex: MainApp.currentHeight! < 700.0 ? 6 : 5,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
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
                                        miladi = DateFormat(
                                                'dd MMMM yyyy',
                                                Provider.of<ChangeSettings>(context, listen: false)
                                                    .langCode)
                                            .format(DateTime.now().add(Duration(days: count)));
                                        hicri = HijriCalendar.fromDate(
                                                DateTime.now().add(Duration(days: count)))
                                            .toFormat('dd MMMM yy');
                                      });
                                      Provider.of<TimeData>(context, listen: false).loadPrayerTimes(
                                          DateTime.now().add(Duration(days: count)));
                                      Provider.of<TimeData>(context, listen: false)
                                          .changeTime(miladi);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          miladi,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: MainApp.currentHeight! < 700.0 ? 13 : 15,
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
                                              miladi = DateFormat(
                                                      'dd MMMM yyyy',
                                                      Provider.of<ChangeSettings>(context,
                                                              listen: false)
                                                          .langCode)
                                                  .format(
                                                      DateTime.now().add(Duration(days: count)));
                                              hicri = HijriCalendar.fromDate(
                                                      DateTime.now().add(Duration(days: count)))
                                                  .toFormat('dd MMMM yy');
                                            });
                                            Provider.of<TimeData>(context, listen: false)
                                                .loadPrayerTimes(
                                                    DateTime.now().add(Duration(days: count)));
                                            Provider.of<TimeData>(context, listen: false)
                                                .changeTime(miladi);
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
                                              miladi = DateFormat(
                                                      'dd MMMM yyyy',
                                                      Provider.of<ChangeSettings>(context,
                                                              listen: false)
                                                          .langCode)
                                                  .format(
                                                      DateTime.now().add(Duration(days: count)));
                                              hicri = HijriCalendar.fromDate(
                                                      DateTime.now().add(Duration(days: count)))
                                                  .toFormat('dd MMMM yy');
                                            });
                                            Provider.of<TimeData>(context, listen: false)
                                                .loadPrayerTimes(
                                                    DateTime.now().add(Duration(days: count)));
                                            Provider.of<TimeData>(context, listen: false)
                                                .changeTime(miladi);
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
                        child: Card(
                          child: Center(
                            child: Text(
                              textAlign: TextAlign.center,
                              hicri,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: MainApp.currentHeight! < 700.0 ? 13 : 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Card(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                              child: Location(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
            flex: 11,
            child: Card(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
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

class CityNameCard extends StatefulWidget {
  const CityNameCard({super.key});

  @override
  State<CityNameCard> createState() => _CityNameCardState();
}

class _CityNameCardState extends State<CityNameCard> {
  static String? cityName;
  @override
  void initState() {
    super.initState();
    cityName = ChangeSettings.cityName;
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<TimeData>(context).cityState = ChangeSettings.cityState;
    Provider.of<TimeData>(context).city = ChangeSettings.cityName;
    return Padding(
      padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${Provider.of<TimeData>(context).cityState}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: MainApp.currentHeight! < 700.0 ? 15.0 : 18.0),
          ),
          SizedBox(
            width: MainApp.currentHeight! < 700.0 ? 70.0 : 100.0,
            child: Divider(
              height: MainApp.currentHeight! < 700.0 ? 10.0 : 20.0,
            ),
          ),
          Text(
            '$cityName',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: MainApp.currentHeight! < 700.0 ? 16.0 : 18.0,
                fontWeight: FontWeight.bold),
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
  void initState() {
    super.initState();

    Provider.of<TimeData>(context, listen: false).switchClock(true);
    Provider.of<TimeData>(context, listen: false).loadPrayerTimes(DateTime.now());
  }

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

class MainTimes extends StatelessWidget {
  const MainTimes({
    super.key,
  });

  static TextStyle timeStyle = TextStyle(fontSize: MainApp.currentHeight! < 700.0 ? 18.0 : 20.0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        color: Colors.grey, // Kenar rengini belirleyin
                        width: 1.0, // Kenar kalınlığını belirleyin
                      ),
                      borderRadius:
                          BorderRadius.circular(10.0), // Kenarların yuvarlaklığını belirleyin
                    ),
                    color: Theme.of(context).cardColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.imsak,
                          style: timeStyle,
                        ),
                        Text(
                          AppLocalizations.of(context)!.sabah,
                          style: timeStyle,
                        ),
                        Text(
                          AppLocalizations.of(context)!.gunes,
                          style: timeStyle,
                        ),
                        Text(
                          AppLocalizations.of(context)!.ogle,
                          style: timeStyle,
                        ),
                        Text(
                          AppLocalizations.of(context)!.ikindi,
                          style: timeStyle,
                        ),
                        Text(
                          AppLocalizations.of(context)!.aksam,
                          style: timeStyle,
                        ),
                        Text(
                          AppLocalizations.of(context)!.yatsi,
                          style: timeStyle,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        color: Colors.grey, // Kenar rengini belirleyin
                        width: 1.0, // Kenar kalınlığını belirleyin
                      ),
                      borderRadius:
                          BorderRadius.circular(10.0), // Kenarların yuvarlaklığını belirleyin
                    ),
                    color: Theme.of(context).cardColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).imsak ?? DateTime.now()),
                          style: timeStyle,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).sabah ?? DateTime.now()),
                          style: timeStyle,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).gunes ?? DateTime.now()),
                          style: timeStyle,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).ogle ?? DateTime.now()),
                          style: timeStyle,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).ikindi ?? DateTime.now()),
                          style: timeStyle,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).aksam ?? DateTime.now()),
                          style: timeStyle,
                        ),
                        Text(
                          DateFormat('HH:mm')
                              .format(Provider.of<TimeData>(context).yatsi ?? DateTime.now()),
                          style: timeStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 1,
            child: Clock(),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class Clock extends StatefulWidget {
  const Clock({super.key});

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        if (DateTime.now().hour == 00 &&
            DateTime.now().minute == 00 &&
            DateTime.now().second == 01) {
          Navigator.popAndPushNamed(context, '/');
        }
        Provider.of<TimeData>(context, listen: false).updateTime();
      }
    });
  }

  final List<String> _prayList = [
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
  ];

  @override
  Widget build(BuildContext context) {
    _prayList[0] = AppLocalizations.of(context)!.timeLeftImsak;
    _prayList[1] = AppLocalizations.of(context)!.timeLeftSabah;
    _prayList[2] = AppLocalizations.of(context)!.timeLeftGunes;
    _prayList[3] = AppLocalizations.of(context)!.timeLeftOgle;
    _prayList[4] = AppLocalizations.of(context)!.timeLeftIkindi;
    _prayList[5] = AppLocalizations.of(context)!.timeLeftAksam;
    _prayList[6] = AppLocalizations.of(context)!.timeLeftYatsi;
    _prayList[7] = AppLocalizations.of(context)!.timeLeftImsak;
    return Provider.of<TimeData>(context).isEnabled == false
        ? IconButton.filledTonal(
            iconSize: 25,
            style: IconButton.styleFrom(shape: const CircleBorder()),
            onPressed: () {
              Navigator.popAndPushNamed(context, '/');
            },
            icon: const Icon(Icons.replay_outlined),
          )
        : Padding(
            padding: MainApp.currentHeight! < 700.0
                ? const EdgeInsets.fromLTRB(60, 0, 60, 0)
                : const EdgeInsets.fromLTRB(60, 5, 60, 5),
            child: SizedBox(
              height: 55,
              child: Stack(
                children: [
                  Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25), // Gölge rengi ve opaklığı
                          spreadRadius: 5, // Gölgenin yayılma alanı
                          blurRadius: 10, // Gölgenin bulanıklığı
                          offset: const Offset(0, 5), // Gölgenin yatay ve dikey kayması
                        ),
                      ],
                    ),
                    child: LinearProgressIndicator(
                      value: (Provider.of<TimeData>(context).mainDifference.inSeconds -
                              Provider.of<TimeData>(context).difference.inSeconds) /
                          Provider.of<TimeData>(context).mainDifference.inSeconds,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: Theme.of(context).cardColor,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).cardTheme.color!),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              _prayList[Provider.of<TimeData>(context).pray],
                              style:
                                  TextStyle(fontSize: MainApp.currentHeight! < 700.0 ? 15.0 : 17.0),
                            ),
                            Provider.of<TimeData>(context).imsak != null
                                ? Text(
                                    '${(Provider.of<TimeData>(context).difference.inHours).toString().padLeft(2, '0')} : ${(Provider.of<TimeData>(context).difference.inMinutes % 60).toString().padLeft(2, '0')} : ${(Provider.of<TimeData>(context).difference.inSeconds % 60).toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                        fontSize: MainApp.currentHeight! < 700.0 ? 15.0 : 17.0,
                                        fontWeight: FontWeight.bold),
                                  )
                                : const Text('0'),
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
