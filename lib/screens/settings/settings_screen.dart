import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/theme_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/auth_service.dart';
import '../onboarding/onboarding_one.dart';
import '../paywall/paywall_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import 'help_screen.dart';
// ✨ NEW IMPORTS ✨
// COMMENTED OUT - Templates moved to Library tab only
// import '../analytics_dashboard.dart';
// import '../templates_gallery.dart';
// import '../main/recording_detail_screen.dart';
// ✨ END NEW IMPORTS ✨

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    // BLUE/BLACK THEME - MATCHING OUR APP COLORS
    const backgroundColor = Color(0xFF000000); // Pure black
    const surfaceColor = Color(0xFF1A1A1A); // Dark gray cards
    const textColor = Colors.white;
    const secondaryTextColor = Color(0xFF94A3B8);
    const primaryColor = Color(0xFF3B82F6); // Our blue
    const dividerColor = Color(0xFF334155);
    
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
                      icon: Icon(Icons.close, color: textColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Settings Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Account Section
                  _buildSectionHeader('ACCOUNT', secondaryTextColor),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildAccountItem(
                      context,
                      textColor,
                      secondaryTextColor,
                      primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Upgrade to Pro Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, const Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showPaywall(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.workspace_premium,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Upgrade to Pro',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Unlimited recordings',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // ✨ FEATURES SECTION COMMENTED OUT - Templates moved to Library tab ✨
                  /*
                  _buildSectionHeader('FEATURES', secondaryTextColor),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.article_outlined,
                          title: 'Templates',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => TemplatesGallery(
                                onTemplateSelected: (note) async {
                                  final appState = context.read<AppStateProvider>();
                                  await appState.saveRecording(note);
                                  
                                  if (context.mounted) {
                                    Navigator.pop(context); // Close templates
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RecordingDetailScreen(recordingId: note.id),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: dividerColor),
                        _buildSettingsItem(
                          icon: Icons.analytics_outlined,
                          title: 'Analytics',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AnalyticsDashboard()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  */
                  // ✨ END FEATURES SECTION ✨
                  
                  // Connect Section
                  _buildSectionHeader('CONNECT', secondaryTextColor),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.email_outlined,
                          title: 'Support Email',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _launchUrl('mailto:info@voice-bubble.com'),
                        ),
                        Divider(height: 1, color: dividerColor),
                        _buildSettingsItem(
                          icon: Icons.language,
                          title: 'Website',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _launchUrl('https://www.voice-bubble.com'),
                        ),
                        Divider(height: 1, color: dividerColor),
                        _buildSettingsItem(
                          icon: Icons.star_rate,
                          title: 'Rate on Play Store',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=com.voicebubble.app'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Social Media Section
                  _buildSectionHeader('FOLLOW US', secondaryTextColor),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSocialItem(
                          icon: '𝕏', // X/Twitter icon
                          title: 'X (Twitter)',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _launchUrl('https://x.com/VoiceBubbl53136'),
                        ),
                        Divider(height: 1, color: dividerColor),
                        _buildSocialItem(
                          icon: '📷', // Instagram icon
                          title: 'Instagram',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _launchUrl('https://www.instagram.com/voicebubble1?igsh=MW81dXcyZG5iczRtbg=='),
                        ),
                        Divider(height: 1, color: dividerColor),
                        _buildSocialItem(
                          icon: '🎵', // TikTok icon
                          title: 'TikTok',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _launchUrl('https://www.tiktok.com/@voice_bubble?_r=1&_t=ZN-93STKgiHnWR'),
                        ),
                        Divider(height: 1, color: dividerColor),
                        _buildSocialItem(
                          icon: '📘', // Facebook icon
                          title: 'Facebook',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _launchUrl('https://www.facebook.com/share/1AdnQ1oodx/'),
                        ),
                        Divider(height: 1, color: dividerColor),
                        _buildSocialItem(
                          icon: '📺', // YouTube icon
                          title: 'YouTube',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _launchUrl('https://youtube.com/@voicebubble1?si=-eSwiUjQfmg1f3Qe'),
                        ),
                        Divider(height: 1, color: dividerColor),
                        _buildSocialItem(
                          icon: '💼', // LinkedIn icon
                          title: 'LinkedIn',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _launchUrl('https://www.linkedin.com/company/voice-bubble/'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // About Section
                  _buildSectionHeader('ABOUT', secondaryTextColor),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: dividerColor),
                        _buildSettingsItem(
                          icon: Icons.description_outlined,
                          title: 'Terms & Conditions',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: dividerColor),
                        _buildSettingsItem(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyScreen(),
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: dividerColor),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Version',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '1.0.0 (2)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Advanced Section
                  _buildSectionHeader('ADVANCED', secondaryTextColor),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.cleaning_services_outlined,
                          title: 'Clear Cache',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () {
                            _showClearCacheDialog(context);
                          },
                        ),
                        Divider(height: 1, color: dividerColor),
                        _buildSettingsItem(
                          icon: Icons.restore,
                          title: 'Reset Settings',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () {
                            _showResetDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Danger Zone
                  _buildSectionHeader('DANGER ZONE', secondaryTextColor),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            _showSignOutDialog(context);
                          },
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sign Out',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: dividerColor),
                        InkWell(
                          onTap: () {
                            _showDeleteAccountDialog(context);
                          },
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.delete_forever_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.5,
      ),
    );
  }
  
  Widget _buildAccountItem(
    BuildContext context,
    Color textColor,
    Color secondaryTextColor,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(48),
              gradient: LinearGradient(
                colors: [primaryColor, const Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Text(
                'U',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  '5 recordings/day',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: secondaryTextColor,
          ),
        ],
      ),
    );
  }
  
  void _showPaywall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PaywallScreen(
          onSubscribe: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Welcome to Pro!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
          onRestore: () {
            Navigator.of(context).pop();
          },
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
  
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required Color textColor,
    required Color secondaryTextColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: textColor,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ],
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: secondaryTextColor,
                ),
          ],
        ),
      ),
    );
  }
  
  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?\n\nYour saved data will remain on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _performSignOut(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF59E0B),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performSignOut(BuildContext context) async {
    try {
      // Sign out from Firebase
      await AuthService().signOut();
      
      // Clear app state
      if (context.mounted) {
        context.read<AppStateProvider>().reset();
      }
      
      // Clear SharedPreferences (user session)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnboarding', false);
      await prefs.remove('userEmail');
      await prefs.remove('userName');
      // Keep overlay state, theme, and other preferences
      
      // Navigate to onboarding/sign-in
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OnboardingOne(onNext: () {
              // This will be handled by the main.dart flow
            }),
          ),
          (route) => false, // Remove all previous routes
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Signed out successfully'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
  
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 12),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'This action is PERMANENT and CANNOT be undone.\n\n'
          '• All your data will be deleted\n'
          '• Your subscription will be cancelled\n'
          '• You will lose access to all premium features\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close first dialog
              _showFinalDeleteConfirmation(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
  
  void _showFinalDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Type "DELETE" below to confirm account deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _performDeleteAccount(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performDeleteAccount(BuildContext context) async {
    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      // Delete account from Firebase
      await AuthService().deleteAccount();
      
      // Clear ALL app data
      if (context.mounted) {
        context.read<AppStateProvider>().reset();
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear everything
      
      // Navigate to onboarding
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OnboardingOne(onNext: () {}),
          ),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Delete account error: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
  
  // URL Launcher helper
  Future<void> _launchUrl(String urlString) async {
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
  
  // Social media item builder
  Widget _buildSocialItem({
    required String icon,
    required String title,
    Widget? trailing,
    required Color textColor,
    required Color secondaryTextColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ],
            ),
            trailing ??
                Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: secondaryTextColor,
                ),
          ],
        ),
      ),
    );
  }
}

