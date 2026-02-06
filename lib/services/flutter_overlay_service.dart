import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class FlutterOverlayService {
  static const MethodChannel _channel = MethodChannel('voicebubble/overlay');

  static void initialize() {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'triggerOverlay' || call.method == 'showOverlayWindow') {
        await showOverlay();
        return true;
      }
      return null;
    });
  }

  static Future<bool> showOverlay() async {
    if (!Platform.isAndroid) return false;
    try {
      final status = await FlutterOverlayWindow.isActive();
      if (status) { await FlutterOverlayWindow.closeOverlay(); await Future.delayed(const Duration(milliseconds: 200)); }
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false, overlayTitle: "VoiceBubble", overlayContent: 'Voice to text overlay',
        flag: OverlayFlag.defaultFlag, visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none, width: WindowSize.matchParent, height: WindowSize.matchParent,
      );
      return true;
    } catch (e) { debugPrint('Error showing Flutter overlay: $e'); return false; }
  }

  static Future<bool> closeOverlay() async {
    if (!Platform.isAndroid) return false;
    try { await FlutterOverlayWindow.closeOverlay(); return true; }
    catch (e) { debugPrint('Error closing Flutter overlay: $e'); return false; }
  }

  static Future<bool> isActive() async {
    if (!Platform.isAndroid) return false;
    try { return await FlutterOverlayWindow.isActive(); }
    catch (e) { debugPrint('Error checking overlay status: $e'); return false; }
  }

  static Future<void> sendToOverlay(Map<String, dynamic> data) async {
    if (!Platform.isAndroid) return;
    try { await FlutterOverlayWindow.shareData(data); }
    catch (e) { debugPrint('Error sending data to overlay: $e'); }
  }
}
