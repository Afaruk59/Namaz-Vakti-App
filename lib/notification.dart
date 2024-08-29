import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/timesPage/times.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> onDidReceiveNotification(NotificationResponse notificationResponse) async {
    print("Notification receive");
  }

  static Future<void> init() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings("@mipmap/ic_launcher");
    const DarwinInitializationSettings iOSInitializationSettings = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iOSInitializationSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotification,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminder Channel',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  static Future<void> showPersistentNotification(int id) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id', // Kanal ID'si
      'your channel name', // Kanal Adı
      importance: Importance.min,
      priority: Priority.min,
      ongoing: true, // Kalıcı yapma    k için
      autoCancel: false, // Kullanıcı tarafından kapatılamaz
      icon: null,
      largeIcon: null,
      showWhen: false,
      playSound: false,
      styleInformation: BigTextStyleInformation(
        'İmsak - ${DateFormat('HH:mm').format(imsak!)}\n'
        'Sabah - ${DateFormat('HH:mm').format(sabah!)}\n'
        'Güneş - ${DateFormat('HH:mm').format(gunes!)}\n'
        'Öğle   - ${DateFormat('HH:mm').format(ogle!)}\n'
        'İkindi -  ${DateFormat('HH:mm').format(ikindi!)}\n'
        'Akşam -${DateFormat('HH:mm').format(aksam!)}\n'
        'Yatsı   -  ${DateFormat('HH:mm').format(yatsi!)}',
      ),
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id, // Bildirim ID'si
      '$city', // Başlık
      '${DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now())} Namaz Vakitleri',
      platformChannelSpecifics,
      payload: 'persistent_notification', // Bildirim verisi
    );
  }
}
