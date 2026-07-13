import 'package:flutter/material.dart';
import '../services/share_service.dart';

class ShareButton extends StatelessWidget {
  final String textToShare;

  const ShareButton({
    super.key,
    required this.textToShare,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF7C6AE8);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          ShareService.shareText(
            context,
            textToShare,
            subject: 'VoiceBubble - AI Rewritten Text',
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share, size: 20),
            SizedBox(width: 8),
            Text(
              'Share',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
