import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:share_plus/share_plus.dart';

/// Central, iOS-safe wrapper around share_plus.
///
/// Fixes the "Share button does nothing" bug on iOS:
///   * When share is triggered from a popup menu / bottom sheet, iOS refuses
///     to present the share sheet while the previous route is still being
///     dismissed. We defer to the next frame so the dismissal finishes first.
///   * `sharePositionOrigin` is required on iPad — without it the app throws.
///     We derive it from the triggering widget's render box.
///   * Calls were previously fire-and-forget; any failure was invisible.
///     We await and show a SnackBar so problems surface instead of silently
///     doing nothing.
class ShareService {
  ShareService._();

  /// Share plain [text] using the native share sheet.
  ///
  /// [context] should be the context of the widget that triggered the share
  /// (used to anchor the iPad popover and to show error feedback).
  static Future<void> shareText(
    BuildContext context,
    String text, {
    String? subject,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _showMessage(context, 'Nothing to share yet.');
      return;
    }

    // Capture the anchor rect BEFORE any async gap while the widget is alive.
    final origin = _sharePositionOrigin(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    // Defer to the next frame so a dismissing menu/sheet doesn't block the
    // share sheet from presenting on iOS.
    await SchedulerBinding.instance.endOfFrame;

    try {
      await Share.share(
        trimmed,
        subject: subject,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('❌ Share failed: $e');
      messenger?.showSnackBar(
        const SnackBar(content: Text('Couldn\'t open the share sheet.')),
      );
    }
  }

  /// Rect of the triggering widget in global coordinates. Required by iPad to
  /// anchor the share popover; ignored on iPhone/Android.
  static Rect? _sharePositionOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
