import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  
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
                    'Terms & Conditions',
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
                    
                    _buildSection(
                      '1. Acceptance of Terms',
                      'By accessing or using VoiceBubble ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '2. Description of Service',
                      'VoiceBubble is a voice-to-text AI-powered application that converts spoken words into written text and provides various text transformation options. The service uses third-party AI providers including OpenAI for speech recognition and text generation.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '3. User Accounts',
                      'You may be required to create an account to access certain features. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '4. User Content',
                      'You retain all rights to any content you submit, post, or display through the App. By submitting content, you grant us a worldwide, non-exclusive, royalty-free license to use, store, and process your content solely for the purpose of providing and improving the service.\n\nYou are solely responsible for your content and the consequences of posting or publishing it. You agree not to submit any content that is illegal, harmful, offensive, or violates any third-party rights.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '5. Acceptable Use',
                      'You agree not to:\n• Use the App for any illegal or unauthorized purpose\n• Attempt to gain unauthorized access to any portion of the App\n• Interfere with or disrupt the App or servers\n• Use the App to transmit any malware or harmful code\n• Violate any applicable laws or regulations\n• Impersonate any person or entity',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '6. Subscription and Payments',
                      'Certain features of the App may require a paid subscription. Subscription fees are billed in advance on a recurring basis. You authorize us to charge your payment method for all fees incurred.\n\nYou may cancel your subscription at any time. Cancellation will take effect at the end of the current billing period. No refunds will be provided for partial subscription periods.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '7. Intellectual Property',
                      'The App and its entire contents, features, and functionality are owned by VoiceBubble and are protected by copyright, trademark, and other intellectual property laws. You may not reproduce, distribute, modify, or create derivative works without our express written permission.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '8. Third-Party Services',
                      'The App may contain links to third-party services or rely on third-party APIs (such as OpenAI). We are not responsible for the content, privacy policies, or practices of any third-party services.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '9. Disclaimers',
                      'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR FREE OF VIRUSES OR OTHER HARMFUL COMPONENTS.\n\nThe AI-generated content is provided for informational purposes only and may not always be accurate or appropriate. You are responsible for reviewing and verifying all generated content before use.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '10. Limitation of Liability',
                      'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS OR REVENUES, WHETHER INCURRED DIRECTLY OR INDIRECTLY, OR ANY LOSS OF DATA, USE, OR OTHER INTANGIBLE LOSSES.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '11. Indemnification',
                      'You agree to indemnify and hold harmless VoiceBubble and its officers, directors, employees, and agents from any claims, damages, losses, liabilities, and expenses arising out of your use of the App or violation of these Terms.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '12. Termination',
                      'We reserve the right to suspend or terminate your access to the App at any time, with or without cause or notice. Upon termination, your right to use the App will immediately cease.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '13. Changes to Terms',
                      'We reserve the right to modify these Terms at any time. We will notify users of any material changes by posting the new Terms in the App. Your continued use of the App after changes constitutes acceptance of the modified Terms.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '14. Governing Law',
                      'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which VoiceBubble operates, without regard to its conflict of law provisions.',
                      textColor,
                      secondaryTextColor,
                    ),
                    
                    _buildSection(
                      '15. Contact Information',
                      'If you have any questions about these Terms, please contact us at:\n\nEmail: info@voice-bubble.com\nWebsite: www.voice-bubble.com',
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

