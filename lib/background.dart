import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xml/xml.dart' as xml;
import 'package:http/http.dart' as http;

DateTime? imsak;
DateTime? sabah;
DateTime? gunes;
DateTime? ogle;
DateTime? ikindi;
DateTime? aksam;
DateTime? yatsi;

List<Map<String, String>> prayerTimes = [];
Map<String, String>? selectedDayTimes;
DateTime? selectedDate;
String? cName;

String? imsakString;
String? sabahString;
String? gunesString;
String? ogleString;
String? ikindiString;
String? aksamString;
String? yatsiString;

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel notificationChannel = AndroidNotificationChannel(
  'coding is life',
  'coding is life service',
  description: 'Description',
  importance: Importance.min,
  showBadge: false,
  enableLights: false,
  enableVibration: false,
);
Future<void> initService() async {
  var service = FlutterBackgroundService();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(notificationChannel);
  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStartOnBoot: true,
      autoStart: false,
      notificationChannelId: 'coding is life',
      initialNotificationTitle: 'Title',
      initialNotificationContent: 'Content',
      foregroundServiceNotificationId: 90,
    ),
  );
}

@pragma('vm:enry-point')
void onStart(ServiceInstance service) async {
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  DartPluginRegistrant.ensureInitialized();

  service.on('setAsForeground').listen((event) {
    print('foreground');
  });
  service.on('setAsBackground').listen((event) {
    print('background');
  });
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  if (sharedPreferences.getBool('notification') == false) {
    service.stopSelf();
  }

  await showPersistent();
  Timer.periodic(
    Duration(minutes: 1),
    (timer) async {
      await showPersistent();
    },
  );
}

Future<void> showPersistent() async {
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  if (sharedPreferences.getBool('notification') == true) {
    await loadPrayerTimes(DateTime.now());
    flutterLocalNotificationsPlugin.show(
      90,
      '$cName',
      '${DateFormat('dd/MM/yyyy').format(DateTime.now())} Namaz Vakitleri',
      NotificationDetails(
        android: AndroidNotificationDetails(
          subText: '${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
          'coding is life',
          'coding is life service',
          ongoing: true,
          icon: '@mipmap/ic_launcher',
          channelShowBadge: false,
          showWhen: false,
          enableVibration: false,
          enableLights: false,
          importance: Importance.low,
          playSound: false,
          styleInformation: BigTextStyleInformation(
              'İmsak - $imsakString\nSabah - $sabahString\nGüneş - $gunesString\nÖğle - $ogleString\nİkindi - $ikindiString\nAkşam - $aksamString\nYatsı - $yatsiString'),
        ),
      ),
    );
  }
}

Future<void> requestNotificationPermission() async {
  PermissionStatus status = await Permission.notification.request();
  if (status.isGranted) {
    print("Bildirim izni verildi.");
  } else if (status.isDenied || status.isPermanentlyDenied) {
    print("Bildirim izni reddedildi.");
  }
}

void selectDate(DateTime time) {
  final DateTime picked = time;

  selectedDate = picked;
  final formattedDate = DateFormat('d/M').format(picked);
  selectedDayTimes = prayerTimes.firstWhere(
    (pt) => '${pt['day']}/${pt['month']}' == formattedDate,
    orElse: () => {},
  );
}

Future<void> loadPrayerTimes(DateTime time) async {
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  cName = sharedPreferences.getString('name');
  String url =
      'https://www.namazvakti.com/XML.php?cityID=${sharedPreferences.getString('location')}'; // Çevrimiçi XML dosyasının URL'si
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
    imsakString = DateFormat('HH:mm').format(imsak ?? DateTime.now());
    sabahString = DateFormat('HH:mm').format(sabah ?? DateTime.now());
    gunesString = DateFormat('HH:mm').format(gunes ?? DateTime.now());
    ogleString = DateFormat('HH:mm').format(ogle ?? DateTime.now());
    ikindiString = DateFormat('HH:mm').format(ikindi ?? DateTime.now());
    aksamString = DateFormat('HH:mm').format(aksam ?? DateTime.now());
    yatsiString = DateFormat('HH:mm').format(yatsi ?? DateTime.now());
  }
}
