import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Service for managing the Flutter overlay window
class FlutterOverlayService {
  static const MethodChannel _channel = MethodChannel('voicebubble/overlay');
  
  static void initialize() {
    debugPrint('🔧 Initializing FlutterOverlayService');
    
    // Listen for trigger from native side
    _channel.setMethodCallHandler((call) async {
      debugPrint('📞 Method call received from native: ${call.method}');
      
      if (call.method == 'triggerOverlay' || call.method == 'showOverlayWindow') {
        debugPrint('🎯 Trigger received! Showing overlay now...');
        await showOverlay();
        return true;
      }
      return null;
    });
    
    debugPrint('✅ FlutterOverlayService initialized and listening');
  }
  
  /// Show the Flutter overlay window
  static Future<bool> showOverlay() async {
    try {
      debugPrint('🎨 Showing Flutter overlay window...');
      
      final status = await FlutterOverlayWindow.isActive();
      if (status) {
        debugPrint('⚠️  Overlay already active, closing first');
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: "VoiceBubble",
        overlayContent: 'Voice to text overlay',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none,
        width: WindowSize.matchParent,
        height: WindowSize.matchParent,
      );
      
      debugPrint('✅ Flutter overlay window shown');
      return true;
    } catch (e) {
      debugPrint('❌ Error showing Flutter overlay: $e');
      return false;
    }
  }
  
  /// Close the Flutter overlay window
  static Future<bool> closeOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
      debugPrint('✅ Flutter overlay window closed');
      return true;
    } catch (e) {
      debugPrint('❌ Error closing Flutter overlay: $e');
      return false;
    }
  }
  
  /// Check if overlay is currently active
  static Future<bool> isActive() async {
    try {
      final status = await FlutterOverlayWindow.isActive();
      return status;
    } catch (e) {
      debugPrint('❌ Error checking overlay status: $e');
      return false;
    }
  }
  
  /// Send data to the overlay window
  static Future<void> sendToOverlay(Map<String, dynamic> data) async {
    try {
      await FlutterOverlayWindow.shareData(data);
      debugPrint('📤 Data sent to overlay: $data');
    } catch (e) {
      debugPrint('❌ Error sending data to overlay: $e');
    }
  }
}

