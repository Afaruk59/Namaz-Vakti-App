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
String? cityID;

class Times extends StatelessWidget {
  const Times({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vakitler'),
        actions: [
          IconButton(
              iconSize: MainApp.currentHeight! < 700.0 ? 22.0 : 25.0,
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

class TimesBody extends StatefulWidget {
  TimesBody({super.key});

  @override
  State<TimesBody> createState() => _TimesBodyState();
}

class _TimesBodyState extends State<TimesBody> {
  final List<String> turkishMonths = [
    'Muharrem',
    'Safer',
    'Rebiülevvel',
    'Rebiülahir',
    'Cemaziyelevvel',
    'Cemaziyelahir',
    'Recep',
    'Şaban',
    'Ramazan',
    'Şevval',
    'Zilkade',
    'Zilhicce'
  ];

  String miladi = '';
  String hicri = '';
  static int count = 0;

  @override
  void initState() {
    super.initState();
    miladi = DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now());
    hicri =
        '${HijriCalendar.now().hDay} ${turkishMonths[HijriCalendar.now().hMonth - 1]} ${HijriCalendar.now().hYear}';
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
                        child: TimesCard(
                          child: Stack(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            count--;
                                            miladi = DateFormat('dd MMMM yyyy', 'tr_TR')
                                                .format(DateTime.now().add(Duration(days: count)));
                                          });
                                        },
                                        icon: Icon(Icons.arrow_back_ios_new),
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
                                          setState(() {
                                            count++;
                                            miladi = DateFormat('dd MMMM yyyy', 'tr_TR')
                                                .format(DateTime.now().add(Duration(days: count)));
                                          });
                                        },
                                        icon: Icon(Icons.arrow_forward_ios),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Center(
                                child: Text(
                                  miladi,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TimesCard(
                          child: Text(
                            textAlign: TextAlign.center,
                            hicri,
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
    loadPrayerTimes(DateTime.now());
  }

  void selectDate(DateTime time) {
    final DateTime picked = time;

    setState(() {
      selectedDate = picked;
      final formattedDate = DateFormat('d/M').format(picked);
      selectedDayTimes = prayerTimes.firstWhere(
        (pt) => '${pt['day']}/${pt['month']}' == formattedDate,
        orElse: () => {},
      );
    });
  }

  Future<void> loadPrayerTimes(DateTime time) async {
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

    selectDate(time.add(Duration(days: 1)));
    try {
      imsak2 = DateFormat('HH:mm').parse((selectedDayTimes?['imsak']).toString());
    } on Exception catch (_) {
      imsak2 = null;
    }
    selectDate(time.subtract(Duration(days: 1)));
    try {
      yatsi2 = DateFormat('HH:mm').parse((selectedDayTimes?['yatsı']).toString());
    } on Exception catch (_) {
      yatsi2 = null;
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

class mainTimes extends StatelessWidget {
  mainTimes({
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
                      side: BorderSide(
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
                        Container(),
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
                      borderRadius:
                          BorderRadius.circular(10.0), // Kenarların yuvarlaklığını belirleyin
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
          ),
          Expanded(
            child: Clock(),
            flex: 1,
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
    print('Yatsı: $yatsi Imsak2: $imsak2 Fark: $mainDifference Kalan: $difference');
    Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
  }

  String clock = '';
  Duration difference = Duration(minutes: 1);
  String pray = '';
  DateTime soontime = DateTime.now();
  bool hour = true;
  bool minute = true;
  DateTime preTime = DateTime.now();
  Duration mainDifference = Duration(minutes: 1);
  static bool isEnabled = true;

  void _updateTime() {
    if (mounted) {
      setState(() {
        DateTime now = DateTime.now();
        clock = DateFormat('HH:mm:ss').format(now);

        if (_PrayerTimesPageState.isTimeLoading == false && imsak != null) {
          if (DateTime(now.year, now.month, now.day, imsak!.hour, imsak!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'İmsaka';
            soontime = imsak!;
            preTime = yatsi2!;
          } else if (DateTime(now.year, now.month, now.day, sabah!.hour, sabah!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Sabaha';
            soontime = sabah!;
            preTime = imsak!;
          } else if (DateTime(now.year, now.month, now.day, gunes!.hour, gunes!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Güneşe';
            soontime = gunes!;
            preTime = sabah!;
          } else if (DateTime(now.year, now.month, now.day, ogle!.hour, ogle!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Öğleye';
            soontime = ogle!;
            preTime = gunes!;
          } else if (DateTime(now.year, now.month, now.day, ikindi!.hour, ikindi!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'İkindiye';
            soontime = ikindi!;
            preTime = ogle!;
          } else if (DateTime(now.year, now.month, now.day, aksam!.hour, aksam!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Akşama';
            soontime = aksam!;
            preTime = ikindi!;
          } else if (DateTime(now.year, now.month, now.day, yatsi!.hour, yatsi!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Yatsıya';
            soontime = yatsi!;
            preTime = aksam!;
          } else {
            pray = 'İmsaka';
            soontime = imsak2!;
            preTime = yatsi!;
          }

          mainDifference = soontime == imsak2
              ? DateTime(1970, 1, 2, soontime.hour, soontime.minute, soontime.second)
                  .difference(preTime)
              : soontime.difference(preTime);
          difference = soontime == imsak2
              ? soontime.difference(DateTime(1969, 12, 31, now.hour, now.minute, now.second))
              : soontime.difference(DateTime(1970, 1, 1, now.hour, now.minute, now.second));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PrayerTimesPageState.isTimeLoading && isEnabled == true
        ? Container()
        : Padding(
            padding: MainApp.currentHeight! < 700.0
                ? const EdgeInsets.fromLTRB(60, 0, 60, 0)
                : const EdgeInsets.fromLTRB(60, 5, 60, 5),
            child: Container(
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
                          color: Colors.black.withOpacity(0.3), // Gölge rengi ve opaklığı
                          spreadRadius: 5, // Gölgenin yayılma alanı
                          blurRadius: 10, // Gölgenin bulanıklığı
                          offset: Offset(0, 5), // Gölgenin yatay ve dikey kayması
                        ),
                      ],
                    ),
                    child: LinearProgressIndicator(
                      value: (mainDifference.inSeconds - difference.inSeconds) /
                          mainDifference.inSeconds,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: Theme.of(context).cardColor,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).cardTheme.color!),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          '$pray Kalan',
                          style: TextStyle(fontSize: MainApp.currentHeight! < 700.0 ? 16.0 : 17.0),
                        ),
                        imsak != null
                            ? Text(
                                '${(difference.inHours).toString().padLeft(2, '0')} : ${(difference.inMinutes % 60).toString().padLeft(2, '0')} : ${(difference.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    fontSize: MainApp.currentHeight! < 700.0 ? 16.0 : 17.0,
                                    fontWeight: FontWeight.bold),
                              )
                            : Text('0'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
