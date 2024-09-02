import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/timesPage/calendar.dart';
import 'package:namaz_vakti_app/timesPage/detailedTimes.dart';
import 'package:namaz_vakti_app/timesPage/location.dart';
import 'package:namaz_vakti_app/main.dart';
import 'package:namaz_vakti_app/settings.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:http/http.dart' as http;
import 'package:hijri/hijri_calendar.dart';

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
String? cityID;

class Times extends StatelessWidget {
  const Times({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vakitler'),
        actions: [
          IconButton.outlined(
              iconSize: MainApp.currentHeight! < 700.0 ? 20.0 : 25.0,
              onPressed: () {
                Navigator.pushNamed(context, '/alarms');
              },
              icon: Icon(
                Icons.alarm,
              )),
          SizedBox(
            width: 20,
          )
        ],
      ),
      body: TimesBody(),
    );
  }
}

class TimesBody extends StatelessWidget {
  TimesBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 3.0 : 10.0),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: TimesCard(
                          child: Text(
                            '${DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now())}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TimesCard(
                          child: Text(
                            '${HijriCalendar.now().hDay} ${HijriCalendar.now().longMonthName} ${HijriCalendar.now().hYear}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TimesCard(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                            child: Location(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TimesCard(
                    child: CityNameCard(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: TimesCard(
              child: Clock(),
            ),
          ),
          Expanded(
            flex: 11,
            child: TimesCard(
              child: Padding(
                padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
                child: Stack(
                  children: [
                    PrayerTimesPage(),
                    DetailedTimesBtn(),
                    CalendarBtn(),
                  ],
                ),
              ),
            ),
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
    return Card(
      child: Center(child: child),
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
    cityState = ChangeSettings.cityState;
    city = ChangeSettings.cityName;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$cityState',
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
  @override
  _PrayerTimesPageState createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  List<Map<String, String>> prayerTimes = [];
  static Map<String, String>? selectedDayTimes;
  DateTime? selectedDate;
  static bool isLoading = true;
  String? errorMessage;

  static bool isTimeLoading = true;

  @override
  void initState() {
    super.initState();
    cityID = ChangeSettings.id;
    loadPrayerTimes();
  }

  void selectDate() {
    DateTime today = DateTime.now();

    final DateTime picked = today;

    setState(() {
      selectedDate = picked;
      final formattedDate = DateFormat('d/M').format(picked);
      selectedDayTimes = prayerTimes.firstWhere(
        (pt) => '${pt['day']}/${pt['month']}' == formattedDate,
        orElse: () => {},
      );
    });
  }

  Future<void> loadPrayerTimes() async {
    String url =
        'https://www.namazvakti.com/XML.php?cityID=${cityID}'; // Çevrimiçi XML dosyasının URL'si
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = response.body;
        final document = xml.XmlDocument.parse(data);

        final cityinfo = document.findAllElements('cityinfo').first;
        final prayertimes = cityinfo.findAllElements('prayertimes');

        setState(() {
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
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }

    selectDate();
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
    Provider.of<ChangeSettings>(context, listen: false).loadNotFromSharedPref();
    Provider.of<ChangeSettings>(context, listen: false).openNot();
    isTimeLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: isLoading ? Center(child: CircularProgressIndicator()) : mainTimes(),
      color: Theme.of(context).cardColor,
    );
  }
}

// ignore: must_be_immutable
class detailedTimes extends StatelessWidget {
  detailedTimes({
    super.key,
  });

  TextStyle style = TextStyle(fontSize: MainApp.currentHeight! < 700.0 ? 17.0 : 18.0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.grey, // Kenar rengini belirleyin
                  width: 1.0, // Kenar kalınlığını belirleyin
                ),
                borderRadius: BorderRadius.circular(10.0), // Kenarların yuvarlaklığını belirleyin
              ),
              color: Theme.of(context).cardColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'İmsak',
                    style: style,
                  ),
                  Text(
                    'Sabah',
                    style: style,
                  ),
                  Text(
                    'Güneş',
                    style: style,
                  ),
                  Text(
                    'İşrak',
                    style: style,
                  ),
                  Text(
                    'Kerahat',
                    style: style,
                  ),
                  Text(
                    'Öğle',
                    style: style,
                  ),
                  Text(
                    'İkindi',
                    style: style,
                  ),
                  Text(
                    'Asri Sani',
                    style: style,
                  ),
                  Text(
                    'İsfirar-ı şems',
                    style: style,
                  ),
                  Text(
                    'Akşam',
                    style: style,
                  ),
                  Text(
                    'İstibak-ı nücum',
                    style: style,
                  ),
                  Text(
                    'Yatsı',
                    style: style,
                  ),
                  Text(
                    'İşa-i Sani',
                    style: style,
                  ),
                  Text(
                    'Kıble',
                    style: style,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.grey, // Kenar rengini belirleyin
                  width: 1.0, // Kenar kalınlığını belirleyin
                ),
                borderRadius: BorderRadius.circular(10.0), // Kenarların yuvarlaklığını belirleyin
              ),
              color: Theme.of(context).cardColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    '${DateFormat('HH:mm').format(imsak!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(sabah!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(gunes!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(israk!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(kerahat!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(ogle!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(ikindi!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(asrisani!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(isfirar!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(aksam!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(istibak!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(yatsi!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(isaisani!)}',
                    style: style,
                  ),
                  Text(
                    '${kible != null ? DateFormat('HH:mm').format(kible!) : '-'}',
                    style: style,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class mainTimes extends StatelessWidget {
  mainTimes({
    super.key,
  });

  TextStyle timeStyle = TextStyle(fontSize: MainApp.currentHeight! < 700.0 ? 18.0 : 20.0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.grey, // Kenar rengini belirleyin
                  width: 1.0, // Kenar kalınlığını belirleyin
                ),
                borderRadius: BorderRadius.circular(10.0), // Kenarların yuvarlaklığını belirleyin
              ),
              color: Theme.of(context).cardColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'İmsak',
                    style: timeStyle,
                  ),
                  Text(
                    'Sabah',
                    style: timeStyle,
                  ),
                  Text(
                    'Güneş',
                    style: timeStyle,
                  ),
                  Text(
                    'Öğle',
                    style: timeStyle,
                  ),
                  Text(
                    'İkindi',
                    style: timeStyle,
                  ),
                  Text(
                    'Akşam',
                    style: timeStyle,
                  ),
                  Text(
                    'Yatsı',
                    style: timeStyle,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.grey, // Kenar rengini belirleyin
                  width: 1.0, // Kenar kalınlığını belirleyin
                ),
                borderRadius: BorderRadius.circular(10.0), // Kenarların yuvarlaklığını belirleyin
              ),
              color: Theme.of(context).cardColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    '${DateFormat('HH:mm').format(imsak ?? DateTime.now())}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(sabah ?? DateTime.now())}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(gunes ?? DateTime.now())}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(ogle ?? DateTime.now())}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(ikindi ?? DateTime.now())}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(aksam ?? DateTime.now())}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(yatsi ?? DateTime.now())}',
                    style: timeStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class Clock extends StatefulWidget {
  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  _PrayerTimesPageState timesPage = _PrayerTimesPageState();
  @override
  void initState() {
    super.initState();
    _updateTime();
    Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
  }

  String clock = '';
  Duration? difference;
  String pray = '';
  DateTime soontime = DateTime.now();
  bool hour = true;
  bool minute = true;

  void _updateTime() {
    if (mounted) {
      setState(() {
        DateTime now = DateTime.now();
        clock = DateFormat('HH:mm:ss').format(now);
        if (now.hour == 0 && now.minute == 0 && now.second == 0) {
          timesPage.loadPrayerTimes();
        }

        if (_PrayerTimesPageState.isTimeLoading == false && imsak != null) {
          if (DateTime(now.year, now.month, now.day, imsak!.hour, imsak!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'İmsaka';
            soontime = imsak!;
          } else if (DateTime(now.year, now.month, now.day, sabah!.hour, sabah!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Sabaha';
            soontime = sabah!;
          } else if (DateTime(now.year, now.month, now.day, gunes!.hour, gunes!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Güneşe';
            soontime = gunes!;
          } else if (DateTime(now.year, now.month, now.day, ogle!.hour, ogle!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Öğleye';
            soontime = ogle!;
          } else if (DateTime(now.year, now.month, now.day, ikindi!.hour, ikindi!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'İkindiye';
            soontime = ikindi!;
          } else if (DateTime(now.year, now.month, now.day, aksam!.hour, aksam!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Akşama';
            soontime = aksam!;
          } else if (DateTime(now.year, now.month, now.day, yatsi!.hour, yatsi!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Yatsıya';
            soontime = yatsi!;
          } else {
            pray = 'Ertesi Güne';
            soontime = DateTime(now.year, now.month, now.day, 23, 59, 59);
          }

          difference = DateTime(now.year, now.month, now.day, soontime.hour, soontime.minute, 0)
              .difference(now);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
      child: Card(
        color: Theme.of(context).cardColor,
        child: _PrayerTimesPageState.isTimeLoading
            ? Center(child: CircularProgressIndicator())
            : SizedBox.expand(
                child: Padding(
                  padding: EdgeInsets.all(MainApp.currentHeight! < 700.0 ? 5.0 : 10.0),
                  child: Card(
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Colors.grey, // Kenar rengini belirleyin
                        width: 1.0, // Kenar kalınlığını belirleyin
                      ),
                      borderRadius:
                          BorderRadius.circular(10.0), // Kenarların yuvarlaklığını belirleyin
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: MainApp.currentHeight! < 700.0 ? 30.0 : 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$pray Kalan: ',
                            style:
                                TextStyle(fontSize: MainApp.currentHeight! < 700.0 ? 16.0 : 18.0),
                          ),
                          imsak != null
                              ? Text(
                                  '${(difference!.inHours).toString().padLeft(2, '0')} : ${(difference!.inMinutes % 60).toString().padLeft(2, '0')} : ${(difference!.inSeconds % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                      fontSize: MainApp.currentHeight! < 700.0 ? 16.0 : 18.0,
                                      fontWeight: FontWeight.bold),
                                )
                              : Text('0'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
