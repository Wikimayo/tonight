import 'package:flutter/services.dart';

class HapticService {
  const HapticService._();

  static Future<void> lightImpact() {
    return HapticFeedback.lightImpact();
  }

  static Future<void> mediumImpact() {
    return HapticFeedback.mediumImpact();
  }

  static Future<void> heavyImpact() {
    return HapticFeedback.heavyImpact();
  }

  static Future<void> selectionClick() {
    return HapticFeedback.selectionClick();
  }

  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }
}
