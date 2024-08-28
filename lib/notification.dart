import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:namaz_vakti_app/times.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      category: AndroidNotificationCategory.service,
      styleInformation: BigTextStyleInformation(
        ' ᴵᵐˢᵃᵏ  ˢᵃᵇᵃʰ   ᴳᵘⁿᵉˢ    ᴼᵍˡᵉ    ᴵᵏⁱⁿᵈⁱ   ᴬᵏˢᵃᵐ   ʸᵃᵗˢⁱ\n'
        '${DateFormat('HH:mm').format(imsak!)}|${DateFormat('HH:mm').format(sabah!)}|${DateFormat('HH:mm').format(gunes!)}|${DateFormat('HH:mm').format(ogle!)}|${DateFormat('HH:mm').format(ikindi!)}|${DateFormat('HH:mm').format(aksam!)}|${DateFormat('HH:mm').format(yatsi!)}',
      ),
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id, // Bildirim ID'si
      '$city', // Başlık
      'Namaz Vakitleri',
      platformChannelSpecifics,
      payload: 'persistent_notification', // Bildirim verisi
    );
  }
}

class ChangeNotification with ChangeNotifier {
  bool isOpen = false;

  void openNot() async {
    if (isOpen == true) {
      NotificationService.showPersistentNotification(0);
    } else {
      await NotificationService.flutterLocalNotificationsPlugin.cancel(0);
    }
  }

  void toggleNot() {
    isOpen = !isOpen;
    saveNottoSharedPref(isOpen);
    notifyListeners();
  }

  static late SharedPreferences _notification;

  Future<void> createSharedPrefObject() async {
    _notification = await SharedPreferences.getInstance();
  }

  void loadNotFromSharedPref() {
    isOpen = _notification.getBool('notification') ?? false;
    print('loaded persistent: $isOpen');
  }

  void saveNottoSharedPref(bool value) {
    _notification.setBool('notification', value);
    print('saved persistent: $isOpen');
  }
}
