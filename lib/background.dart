import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel notificationChannel = AndroidNotificationChannel(
  'coding is life',
  'coding is life service',
  description: 'Description',
  importance: Importance.low,
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
      autoStart: true,
      notificationChannelId: 'coding is life',
      initialNotificationTitle: 'Title',
      initialNotificationContent: 'Content',
      foregroundServiceNotificationId: 90,
    ),
  );
  service.startService();
}

@pragma('vm:enry-point')
void onStart(ServiceInstance service) {
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

  Timer.periodic(
    Duration(seconds: 1),
    (timer) {
      flutterLocalNotificationsPlugin.show(
        90,
        'Time',
        '${DateTime.now()}',
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'coding is life',
            'coding is life service',
            ongoing: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    },
  );
}
