import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  static bool _isOverlayActive = false;
  static bool get isOverlayActive => _isOverlayActive;

  static Future<bool> requestOverlayPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterOverlayWindow.requestPermission() ?? false;
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
      return false;
    }
  }

  static Future<bool> checkOverlayPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterOverlayWindow.isPermissionGranted() ?? false;
    } catch (e) {
      debugPrint('Error checking overlay permission: $e');
      return false;
    }
  }

  static Future<void> showOverlay() async {
    if (!Platform.isAndroid) return;
    try {
      final hasPermission = await checkOverlayPermission();
      if (!hasPermission) return;
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true, overlayTitle: "VoiceBubble", overlayContent: 'Tap to record',
        flag: OverlayFlag.defaultFlag, visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none, width: WindowSize.matchParent, height: WindowSize.matchParent,
      );
      _isOverlayActive = true;
    } catch (e) { debugPrint('Error showing overlay: $e'); }
  }

  static Future<void> closeOverlay() async {
    if (!Platform.isAndroid) return;
    try { await FlutterOverlayWindow.closeOverlay(); _isOverlayActive = false; }
    catch (e) { debugPrint('Error closing overlay: $e'); }
  }

  static Future<void> shareToOverlay(Map<String, dynamic> data) async {
    if (!Platform.isAndroid) return;
    try { await FlutterOverlayWindow.shareData(data); }
    catch (e) { debugPrint('Error sharing data to overlay: $e'); }
  }

  static Future<bool> isActive() async {
    if (!Platform.isAndroid) return false;
    try { return await FlutterOverlayWindow.isActive() ?? false; }
    catch (e) { debugPrint('Error checking overlay status: $e'); return false; }
  }
}
