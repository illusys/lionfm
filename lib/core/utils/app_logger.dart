import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void warning(String message, Object error, [StackTrace? stackTrace]) {
    debugPrint('[LionFM][warning] $message: $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }

  static void info(String message) => debugPrint('[LionFM][info] $message');
}
