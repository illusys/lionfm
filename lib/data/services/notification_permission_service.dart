import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationPermissionService {
  NotificationPermissionService._();

  static Future<void> requestContextualPermission() async {
    if (kIsWeb) return;
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}
