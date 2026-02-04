import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F7);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: textColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last updated: November 27, 2025',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'VoiceBubble ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      '1. Information We Collect',
                      'Personal Information:\n• Name and email address (if you create an account)\n• Payment information (processed by third-party payment providers)\n• Account preferences and settings\n\nVoice and Content Data:\n• Voice recordings (temporarily processed for transcription)\n• Transcribed text\n• Generated text content\n• Usage history and preferences\n\nDevice Information:\n• Device type and operating system\n• Unique device identifiers\n• App version and usage statistics\n• Crash reports and performance data',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '2. How We Use Your Information',
                      'We use the collected information to:\n• Provide and maintain the voice-to-text service\n• Process your voice recordings using AI technology\n• Improve and personalize your experience\n• Process transactions and send related information\n• Send you technical notices and support messages\n• Monitor and analyze usage patterns\n• Detect and prevent technical issues\n• Comply with legal obligations',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '3. Voice Data Processing',
                      'Your voice recordings are:\n• Sent to OpenAI Whisper API for speech-to-text conversion\n• Processed in real-time and not permanently stored by us\n• Deleted immediately after transcription\n• Never shared with third parties except for processing\n\nTranscribed text and generated content:\n• Stored locally on your device\n• Optionally backed up to our secure servers (if enabled)\n• Used to improve AI model performance (with your consent)\n• Can be deleted at any time from your device',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '4. Third-Party Services',
                      'We use the following third-party services:\n\nOpenAI:\n• Speech-to-text (Whisper API)\n• Text generation (GPT-4o-mini)\n• Subject to OpenAI\'s privacy policy\n\nAuthentication Providers:\n• Google Sign-In\n• Apple Sign-In\n• Subject to their respective privacy policies\n\nAnalytics:\n• Anonymous usage statistics\n• Crash reporting\n• Performance monitoring',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '5. Data Retention',
                      'Voice Recordings: Deleted immediately after transcription\n\nTranscribed Text: Stored until you delete it or delete your account\n\nAccount Information: Retained while your account is active and for 30 days after deletion\n\nUsage Data: Retained for up to 2 years for analytics purposes',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '6. Data Security',
                      'We implement appropriate technical and organizational security measures to protect your information:\n• Encryption in transit (TLS/SSL)\n• Encryption at rest for stored data\n• Regular security audits\n• Access controls and authentication\n• Secure data centers\n\nHowever, no method of transmission or storage is 100% secure. We cannot guarantee absolute security.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '7. Your Privacy Rights',
                      'You have the right to:\n• Access your personal data\n• Correct inaccurate data\n• Delete your data and account\n• Export your data\n• Opt-out of data collection for analytics\n• Withdraw consent for data processing\n• Object to certain processing activities\n\nTo exercise these rights, contact us at info@voice-bubble.com',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '8. Children\'s Privacy',
                      'VoiceBubble is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '9. International Data Transfers',
                      'Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place to protect your data in accordance with this Privacy Policy.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '10. Cookies and Tracking',
                      'We use local storage and similar technologies to:\n• Remember your preferences\n• Authenticate your account\n• Analyze app usage\n\nYou can manage these settings in your device settings.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '11. California Privacy Rights',
                      'California residents have additional rights under the CCPA:\n• Know what personal information is collected\n• Know if personal information is sold or disclosed\n• Say no to the sale of personal information\n• Access and delete personal information\n• Non-discrimination for exercising privacy rights\n\nWe do not sell your personal information.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '12. GDPR Compliance',
                      'For users in the European Economic Area:\n• Legal basis for processing: Consent and contract performance\n• Right to withdraw consent at any time\n• Right to lodge a complaint with supervisory authority\n• Data Protection Officer: dpo@voicebubble.app',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '13. Changes to Privacy Policy',
                      'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the App and updating the "Last updated" date. You are advised to review this Privacy Policy periodically.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '14. Contact Us',
                      'If you have questions about this Privacy Policy, please contact us:\n\nEmail: info@voice-bubble.com\nWebsite: www.voice-bubble.com\n\nData Protection Officer: info@voice-bubble.com',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(
    String title,
    String content,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

