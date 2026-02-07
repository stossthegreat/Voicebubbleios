import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Service for managing the native Android overlay bubble
///
/// This service provides a Google Play compliant overlay implementation:
/// - Uses ONLY SYSTEM_ALERT_WINDOW permission
/// - Does NOT use Accessibility APIs
/// - Does NOT read content from other apps
/// - Does NOT automatically insert text
/// - Requires explicit user interaction for all actions
/// - Android-only: all methods return safe defaults on iOS
class NativeOverlayService {
  static const MethodChannel _channel = MethodChannel('voicebubble/overlay');

  /// Check if overlay permission is granted
  static Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? result = await _channel.invokeMethod('checkPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error checking overlay permission: $e');
      return false;
    }
  }

  /// Request overlay permission from the user
  /// Opens Android settings to grant SYSTEM_ALERT_WINDOW permission
  static Future<void> requestPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (e) {
      debugPrint('❌ Error requesting overlay permission: $e');
    }
  }

  /// Show the native overlay bubble
  /// Starts the OverlayService as a foreground service
  static Future<bool> showOverlay() async {
    if (!Platform.isAndroid) return false;
    try {
      debugPrint('🚀 Starting native overlay bubble service...');

      // First check if we have permission
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        debugPrint('❌ No overlay permission, cannot start service');
        return false;
      }

      final bool? result = await _channel.invokeMethod('showOverlay');
      if (result == true) {
        debugPrint('✅ Native overlay bubble service started successfully');
      } else {
        debugPrint('❌ Native overlay bubble service failed to start');
      }
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error showing overlay bubble: $e');
      return false;
    }
  }

  /// Hide the native overlay bubble
  /// Stops the OverlayService
  static Future<bool> hideOverlay() async {
    if (!Platform.isAndroid) return false;
    try {
      debugPrint('🛑 Stopping native overlay service...');
      final bool? result = await _channel.invokeMethod('hideOverlay');
      if (result == true) {
        debugPrint('✅ Native overlay service stopped successfully');
      }
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error hiding overlay: $e');
      return false;
    }
  }

  /// Check if overlay service is currently active
  static Future<bool> isActive() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? result = await _channel.invokeMethod('isActive');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error checking overlay status: $e');
      return false;
    }
  }
}
