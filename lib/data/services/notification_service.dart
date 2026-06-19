import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/show_model.dart';
import '../models/user_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    const androidChannel = AndroidNotificationChannel(
      'lionfm_main',
      'Lion FM Notifications',
      description: 'Live show alerts, news, and song requests',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _local.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lionfm_main',
          'Lion FM Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> scheduleShowReminder(ShowModel show) async {
    final reminderTime = show.startTime.subtract(const Duration(minutes: 10));
    if (reminderTime.isBefore(DateTime.now())) return;

    await showNotification(
      id: show.id.hashCode,
      title: '🎙 Starting soon on Lion FM',
      body: '${show.title} with ${show.hostName} starts in 10 minutes',
    );
  }

  static Future<void> updateTopicSubscriptions(UserModel user) async {
    // Topic subscriptions via FCM would go here.
    // Skipped since firebase_messaging is not initialized in this demo.
  }
}
