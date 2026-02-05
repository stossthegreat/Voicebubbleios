import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onSignIn;
  const SignInScreen({super.key, required this.onSignIn});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final AuthService _authService = AuthService();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
        );
      } else {
        await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      widget.onSignIn();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('🔵 UI: Starting Google Sign-In...');
      final res = await _authService.signInWithGoogle();
      debugPrint('🔵 UI: Sign-In result: ${res != null ? "Success" : "Cancelled"}');

      if (res != null) {
        debugPrint('🟢 UI: Calling onSignIn callback');
        widget.onSignIn();
      } else {
        debugPrint('⚪ UI: User cancelled sign-in');
        // User cancelled - don't show error
      }
    } catch (e) {
      debugPrint('🔴 UI: Sign-In error: $e');
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        debugPrint('🔵 UI: Setting loading to false');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        String displayName = 'User';
        if (credential.givenName != null) {
          displayName = '${credential.givenName} ${credential.familyName ?? ''}'.trim();
        } else if (userCredential.user!.email != null) {
          displayName = userCredential.user!.email!.split('@').first;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': userCredential.user!.email ?? credential.email ?? '',
          'fullName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) widget.onSignIn();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple Sign-In failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: child,
                      ),
                    );
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 60, 32, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 32),
                          _buildTitle(),
                          const SizedBox(height: 40),
                          if (_isLoading) const CircularProgressIndicator(color: Color(0xFF3B82F6))
                          else ...[
                            if (_isSignUp) ...[
                              _buildTextField(_nameController, 'Full Name', Icons.person),
                              const SizedBox(height: 16),
                            ],
                            _buildTextField(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildTextField(
                              _passwordController,
                              'Password',
                              Icons.lock,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildButton(_handleEmailAuth, _isSignUp ? 'Sign Up' : 'Sign In'),
                            const SizedBox(height: 20),
                            _buildDivider(),
                            const SizedBox(height: 20),
                            _buildGoogleButton(),
                            _buildAppleButton(),
                            const SizedBox(height: 24),
                            _buildToggleText(),
                            const SizedBox(height: 32),
                            _buildTerms(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
        boxShadow: [BoxShadow(color: Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 40, offset: Offset(0, 20))],
      ),
      child: const Icon(Icons.mic, size: 50, color: Colors.white),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(_isSignUp ? 'Create Account' : 'Welcome Back',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8),
        Text(_isSignUp ? 'Sign up to get started' : 'Sign in to continue',
            style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildTextField(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboardType, bool obscureText = false, Widget? suffixIcon}) {
    return TextFormField(
      controller: c,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (v) => v!.isEmpty ? "Enter $label" : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Color(0xFF3B82F6)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildButton(VoidCallback onTap, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: TextStyle(color: Colors.white60)),
        ),
        Expanded(child: Divider(color: Colors.white12)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _handleGoogleSignIn,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.g_mobiledata_rounded, size: 28, color: _isLoading ? Colors.white38 : Colors.white),
              const SizedBox(width: 10),
              Text(
                'Continue with Google',
                style: TextStyle(
                  color: _isLoading ? Colors.white38 : Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppleButton() {
    if (!Platform.isIOS) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleAppleSignIn,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple, size: 28, color: _isLoading ? Colors.black38 : Colors.black),
                const SizedBox(width: 10),
                Text(
                  'Continue with Apple',
                  style: TextStyle(
                    color: _isLoading ? Colors.black38 : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleText() {
    return GestureDetector(
      onTap: () => setState(() => _isSignUp = !_isSignUp),
      child: Text.rich(
        TextSpan(
          text: _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
          style: TextStyle(color: Colors.white70),
          children: [
            TextSpan(text: _isSignUp ? 'Sign In' : 'Sign Up', style: TextStyle(color: Color(0xFF3B82F6)))
          ],
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(color: Colors.white60, fontSize: 12),
        children: [
          const TextSpan(text: "By continuing, you agree to our "),
          TextSpan(
            text: "Terms",
            style: const TextStyle(color: Color(0xFF3B82F6)),
            recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse('https://voicebubble.app/terms')),
          ),
          const TextSpan(text: " and "),
          TextSpan(
            text: "Privacy Policy",
            style: const TextStyle(color: Color(0xFF3B82F6)),
            recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse('https://voicebubble.app/privacy')),
          ),
        ],
      ),
    );
  }
}
