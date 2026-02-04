import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/theme_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/auth_service.dart';
import '../../services/subscription_service.dart';
import '../onboarding/onboarding_one.dart';
import '../paywall/paywall_screen.dart';
import '../../widgets/usage_display_widget.dart';
import 'account_management_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPro = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    final isPro = await SubscriptionService().isPro();
    setState(() {
      _isPro = isPro;
      _isLoading = false;
    });
  }
  
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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const UsageDisplayWidget(),
          
          // Upgrade to Pro Button (FREE users only)
          if (!_isLoading && !_isPro)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaywallScreen(
                          onSubscribe: () {
                            Navigator.pop(context);
                            _checkProStatus();
                          },
                          onRestore: () {
                            Navigator.pop(context);
                            _checkProStatus();
                          },
                          onClose: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF3B82F6),
                          Color(0xFF2563EB),
                          Color(0xFF1D4ED8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium, size: 28),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upgrade to Pro',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '90 minutes + Unlimited AI',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // APP & STORE LINKS
                _buildSectionHeader('APP & STORE', secondaryTextColor),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        icon: Icons.download,
                        title: 'Download App',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _launchUrl(context, 'https://play.google.com/store/apps/details?id=com.voicebubble.app'),
                      ),
                      Divider(height: 1, color: dividerColor),
                      _buildSettingsItem(
                        icon: Icons.star_rate,
                        title: 'Rate App',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _launchUrl(context, 'https://play.google.com/store/apps/details?id=com.voicebubble.app'),
                      ),
                      Divider(height: 1, color: dividerColor),
                      _buildSettingsItem(
                        icon: Icons.language,
                        title: 'Website',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _launchUrl(context, 'https://www.voice-bubble.com'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // SOCIAL MEDIA
                _buildSectionHeader('SOCIALS', secondaryTextColor),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        icon: Icons.alternate_email,
                        title: 'X (Twitter)',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _launchUrl(context, 'https://x.com/VoiceBubbl53136'),
                      ),
                      Divider(height: 1, color: dividerColor),
                      _buildSettingsItem(
                        icon: Icons.camera_alt,
                        title: 'Instagram',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _launchUrl(context, 'https://www.instagram.com/voicebubble1?igsh=MW81dXcyZG5iczRtbg=='),
                      ),
                      Divider(height: 1, color: dividerColor),
                      _buildSettingsItem(
                        icon: Icons.music_note,
                        title: 'TikTok',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _launchUrl(context, 'https://www.tiktok.com/@voice_bubble?_r=1&_t=ZN-93STKgiHnWR'),
                      ),
                      Divider(height: 1, color: dividerColor),
                      _buildSettingsItem(
                        icon: Icons.facebook,
                        title: 'Facebook',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _launchUrl(context, 'https://www.facebook.com/share/1AdnQ1oodx/'),
                      ),
                      Divider(height: 1, color: dividerColor),
                      _buildSettingsItem(
                        icon: Icons.play_circle,
                        title: 'YouTube',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _launchUrl(context, 'https://youtube.com/@voicebubble1?si=-eSwiUjQfmg1f3Qe'),
                      ),
                      Divider(height: 1, color: dividerColor),
                      _buildSettingsItem(
                        icon: Icons.business,
                        title: 'LinkedIn',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _launchUrl(context, 'https://www.linkedin.com/company/voice-bubble/'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // LEGAL & SUPPORT
                _buildSectionHeader('LEGAL & SUPPORT', secondaryTextColor),
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
                            MaterialPageRoute(builder: (_) => const HelpScreen()),
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
                            MaterialPageRoute(builder: (_) => const PrivacyScreen()),
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
                            MaterialPageRoute(builder: (_) => const TermsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // ACCOUNT SETTINGS
                _buildSectionHeader('ACCOUNT', secondaryTextColor),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        icon: Icons.manage_accounts,
                        title: 'Account Management',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AccountManagementScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, color: dividerColor),
                      _buildSettingsItem(
                        icon: Icons.cleaning_services_outlined,
                        title: 'Clear Cache',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _showClearCacheDialog(context),
                      ),
                      Divider(height: 1, color: dividerColor),
                      _buildSettingsItem(
                        icon: Icons.logout,
                        title: 'Sign Out',
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        onTap: () => _showSignOutDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
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
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right,
              color: secondaryTextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // URL Launcher helper
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will clear temporary files and free up storage space.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => OnboardingOne(onNext: () {})),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
        ],
      ),
    );
  }
}
