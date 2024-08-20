import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/location.dart';
import 'package:xml/xml.dart' as xml;
import 'package:http/http.dart' as http;
import 'package:hijri/hijri_calendar.dart';

class Times extends StatelessWidget {
  const Times({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vakitler'),
        actions: [
          IconButton.filledTonal(
              onPressed: () {},
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

// ignore: must_be_immutable
class TimesBody extends StatelessWidget {
  TimesBody({super.key});

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
                          child: Text(
                            '${DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now())}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        TimesCard(
                          child: Text(
                            '${HijriCalendar.now().hDay} ${HijriCalendar.now().longMonthName} ${HijriCalendar.now().hYear}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        TimesCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25.0),
                            child: Location(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TimesCard(
                    child: CityNameCard(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: TimesCard(
              child: Clock(),
            ),
          ),
          TimesCard(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Stack(
                children: [
                  PrayerTimesPage(),
                  Positioned(
                    bottom: 5,
                    left: 5,
                    child: FloatingActionButton(
                      child: Icon(Icons.menu),
                      shape: CircleBorder(),
                      onPressed: () {
                        Navigator.pushNamed(context, '/detailedTimes');
                      },
                    ),
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

class CityNameCard extends StatefulWidget {
  const CityNameCard({super.key});

  @override
  State<CityNameCard> createState() => _CityNameCardState();
}

class _CityNameCardState extends State<CityNameCard> {
  static String? cityName;
  static String? cityState;

  @override
  void initState() {
    super.initState();
    cityName = ChangeLocation.cityName;
    cityState = ChangeLocation.cityState;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$cityState',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(
          width: 100,
          child: Divider(
            height: 20,
          ),
        ),
        Text(
          '$cityName',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
      ],
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
  static String? cityID;

  static DateTime? imsak;
  static DateTime? sabah;
  static DateTime? gunes;
  static DateTime? ogle;
  static DateTime? ikindi;
  static DateTime? aksam;
  static DateTime? yatsi;
  static DateTime? israk;
  static DateTime? kerahat;
  static DateTime? asrisani;
  static DateTime? isfirar;
  static DateTime? istibak;
  static DateTime? isaisani;
  static DateTime? kible;
  static bool isTimeLoading = true;

  @override
  void initState() {
    super.initState();
    cityID = ChangeLocation.id;
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
    imsak = DateFormat('HH:mm').parse((selectedDayTimes?['imsak']).toString());
    sabah = DateFormat('HH:mm').parse((selectedDayTimes?['sabah']).toString());
    gunes = DateFormat('HH:mm').parse((selectedDayTimes?['güneş']).toString());
    ogle = DateFormat('HH:mm').parse((selectedDayTimes?['öğle']).toString());
    ikindi = DateFormat('HH:mm').parse((selectedDayTimes?['ikindi']).toString());
    aksam = DateFormat('HH:mm').parse((selectedDayTimes?['akşam']).toString());
    yatsi = DateFormat('HH:mm').parse((selectedDayTimes?['yatsı']).toString());

    israk = DateFormat('HH:mm').parse((selectedDayTimes?['işrak']).toString());
    kerahat = DateFormat('HH:mm').parse((selectedDayTimes?['kerahat']).toString());
    asrisani = DateFormat('HH:mm').parse((selectedDayTimes?['asrisani']).toString());
    isfirar = DateFormat('HH:mm').parse((selectedDayTimes?['isfirar']).toString());
    istibak = DateFormat('HH:mm').parse((selectedDayTimes?['iştibak']).toString());
    isaisani = DateFormat('HH:mm').parse((selectedDayTimes?['işaisani']).toString());
    try {
      kible = DateFormat('HH:mm').parse((selectedDayTimes?['kıble']).toString());
    } on Exception catch (e) {
      kible = null;
    }
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

  TextStyle style = TextStyle(fontSize: 19);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
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
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.imsak!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.sabah!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.gunes!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.israk!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.kerahat!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.ogle!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.ikindi!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.asrisani!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.isfirar!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.aksam!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.istibak!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.yatsi!)}',
                    style: style,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.isaisani!)}',
                    style: style,
                  ),
                  Text(
                    '${_PrayerTimesPageState.kible != null ? DateFormat('HH:mm').format(_PrayerTimesPageState.kible!) : '-'}',
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

  TextStyle timeStyle = TextStyle(fontSize: 20);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
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
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.imsak!)}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.sabah!)}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.gunes!)}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.ogle!)}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.ikindi!)}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.aksam!)}',
                    style: timeStyle,
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(_PrayerTimesPageState.yatsi!)}',
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

        if (_PrayerTimesPageState.isTimeLoading == false) {
          if (DateTime(now.year, now.month, now.day, _PrayerTimesPageState.imsak!.hour, _PrayerTimesPageState.imsak!.minute, 0).difference(now) >
              DateTime.now().difference(now)) {
            pray = 'İmsaka';
            soontime = _PrayerTimesPageState.imsak!;
          } else if (DateTime(now.year, now.month, now.day, _PrayerTimesPageState.sabah!.hour, _PrayerTimesPageState.sabah!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Sabaha';
            soontime = _PrayerTimesPageState.sabah!;
          } else if (DateTime(now.year, now.month, now.day, _PrayerTimesPageState.gunes!.hour,
                      _PrayerTimesPageState.gunes!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Güneşe';
            soontime = _PrayerTimesPageState.gunes!;
          } else if (DateTime(now.year, now.month, now.day, _PrayerTimesPageState.ogle!.hour, _PrayerTimesPageState.ogle!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Öğleye';
            soontime = _PrayerTimesPageState.ogle!;
          } else if (DateTime(now.year, now.month, now.day, _PrayerTimesPageState.ikindi!.hour,
                      _PrayerTimesPageState.ikindi!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'İkindiye';
            soontime = _PrayerTimesPageState.ikindi!;
          } else if (DateTime(now.year, now.month, now.day, _PrayerTimesPageState.aksam!.hour,
                      _PrayerTimesPageState.aksam!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Akşama';
            soontime = _PrayerTimesPageState.aksam!;
          } else if (DateTime(now.year, now.month, now.day, _PrayerTimesPageState.yatsi!.hour,
                      _PrayerTimesPageState.yatsi!.minute, 0)
                  .difference(now) >
              DateTime.now().difference(now)) {
            pray = 'Yatsıya';
            soontime = _PrayerTimesPageState.yatsi!;
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
      padding: const EdgeInsets.all(15.0),
      child: Card(
        color: Theme.of(context).cardColor,
        child: _PrayerTimesPageState.isTimeLoading
            ? Center(child: CircularProgressIndicator())
            : SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$pray Kalan: ',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        '${(difference!.inHours).toString().padLeft(2, '0')} : ${(difference!.inMinutes % 60).toString().padLeft(2, '0')} : ${(difference!.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
