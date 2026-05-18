import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  const CrashReportingService();

  static FirebaseCrashlytics? get _crashlytics {
    if (Firebase.apps.isEmpty) {
      return null;
    }

    return FirebaseCrashlytics.instance;
  }

  Future<void> recordError(Object error, StackTrace? stackTrace) async {
    try {
      final crashlytics = _crashlytics;
      if (crashlytics == null) {
        return;
      }

      await crashlytics.recordError(error, stackTrace, fatal: false);
    } catch (_) {
      // Crash reporting must never break the app.
    }
  }

  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    try {
      final crashlytics = _crashlytics;
      if (crashlytics == null) {
        FlutterError.presentError(details);
        return;
      }

      await crashlytics.recordFlutterFatalError(details);
    } catch (_) {
      FlutterError.presentError(details);
    }
  }

  Future<void> recordFatalError(Object error, StackTrace stackTrace) async {
    try {
      final crashlytics = _crashlytics;
      if (crashlytics == null) {
        return;
      }

      await crashlytics.recordError(error, stackTrace, fatal: true);
    } catch (_) {
      // Crash reporting must never break the app.
    }
  }

  Future<void> log(String message) async {
    try {
      final crashlytics = _crashlytics;
      if (crashlytics == null) {
        return;
      }

      await crashlytics.log(message);
    } catch (_) {
      // Crash reporting must never break the app.
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      final crashlytics = _crashlytics;
      if (crashlytics == null) {
        return;
      }

      await crashlytics.setUserIdentifier(userId);
    } catch (_) {
      // Crash reporting must never break the app.
    }
  }
}
