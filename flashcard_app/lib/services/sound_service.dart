import 'package:flutter/services.dart';

/// Provides haptic + (on iOS) system-click feedback on card flip.
/// No native audio plugin required — zero Gradle dependency issues.
class SoundService {
  static Future<void> playFlip() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
