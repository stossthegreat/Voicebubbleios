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
class NativeOverlayService {
  static const MethodChannel _channel = MethodChannel('voicebubble/overlay');
  
  /// Check if overlay permission is granted
  static Future<bool> checkPermission() async {
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
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (e) {
      debugPrint('❌ Error requesting overlay permission: $e');
    }
  }
  
  /// Show the native overlay bubble
  /// Starts the OverlayService as a foreground service
  static Future<bool> showOverlay() async {
    try {
      debugPrint('🚀 Starting native overlay service...');
      final bool? result = await _channel.invokeMethod('showOverlay');
      if (result == true) {
        debugPrint('✅ Native overlay service started successfully');
      } else {
        debugPrint('❌ Native overlay service failed to start');
      }
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error showing overlay: $e');
      return false;
    }
  }
  
  /// Hide the native overlay bubble
  /// Stops the OverlayService
  static Future<bool> hideOverlay() async {
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
    try {
      final bool? result = await _channel.invokeMethod('isActive');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Error checking overlay status: $e');
      return false;
    }
  }
}
