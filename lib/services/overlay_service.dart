import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  static bool _isOverlayActive = false;
  
  static bool get isOverlayActive => _isOverlayActive;
  
  /// Request overlay permission (Android only)
  static Future<bool> requestOverlayPermission() async {
    try {
      return await FlutterOverlayWindow.requestPermission() ?? false;
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
      return false;
    }
  }
  
  /// Check if overlay permission is granted
  static Future<bool> checkOverlayPermission() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted() ?? false;
    } catch (e) {
      debugPrint('Error checking overlay permission: $e');
      return false;
    }
  }
  
  /// Show the floating overlay bubble
  static Future<void> showOverlay() async {
    try {
      final hasPermission = await checkOverlayPermission();
      if (!hasPermission) {
        debugPrint('❌ Overlay permission not granted');
        return;
      }
      
      debugPrint('🚀 Starting overlay...');
      
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "VoiceBubble",
        overlayContent: 'Tap to record',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none,
        width: WindowSize.matchParent,
        height: WindowSize.matchParent,
      );
      
      _isOverlayActive = true;
      debugPrint('✅ Overlay shown successfully');
    } catch (e) {
      debugPrint('❌ Error showing overlay: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }
  
  /// Close the floating overlay
  static Future<void> closeOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
      _isOverlayActive = false;
    } catch (e) {
      debugPrint('Error closing overlay: $e');
    }
  }
  
  /// Share data with overlay
  static Future<void> shareToOverlay(Map<String, dynamic> data) async {
    try {
      await FlutterOverlayWindow.shareData(data);
    } catch (e) {
      debugPrint('Error sharing data to overlay: $e');
    }
  }
  
  /// Check if overlay is currently active
  static Future<bool> isActive() async {
    try {
      return await FlutterOverlayWindow.isActive() ?? false;
    } catch (e) {
      debugPrint('Error checking overlay status: $e');
      return false;
    }
  }
}

