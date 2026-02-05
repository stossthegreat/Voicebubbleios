import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/app_state_provider.dart';
import 'providers/theme_provider.dart';
import 'services/subscription_service.dart';
import 'services/storage_service.dart';
import 'services/reminder_manager.dart';
import 'services/analytics_service.dart';
import 'services/share_handler_service.dart';
import 'screens/main/main_navigation.dart';
import 'screens/onboarding/onboarding_one.dart';
import 'screens/onboarding/onboarding_two.dart';
import 'screens/onboarding/onboarding_three_new.dart';
import 'screens/onboarding/permissions_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/paywall/paywall_screen.dart';
import 'screens/import/import_content_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase - REQUIRED for App Store
  await Firebase.initializeApp();
  debugPrint('✅ Firebase initialized successfully');
  
  // Initialize Firebase Analytics
  final analytics = AnalyticsService();
  debugPrint('✅ Firebase Analytics initialized successfully');
  
  // Initialize Hive storage - CRITICAL FOR SAVING!
  await StorageService.initialize();
  debugPrint('✅ Hive storage initialized successfully');
  
  // Initialize reminder system
  await ReminderManager().initialize();
  debugPrint('✅ Reminder system initialized');
  
  // Initialize In-App Purchase system
  await SubscriptionService().initialize();
  debugPrint('✅ Subscription service initialized');

  // Initialize share handler for receiving shared files from other apps
  ShareHandlerService().initialize();
  debugPrint('✅ Share handler initialized');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  SharedContent? _pendingShareContent;

  @override
  void initState() {
    super.initState();
    _setupShareListener();
  }

  void _setupShareListener() {
    ShareHandlerService().pendingShares.listen((content) {
      debugPrint('📥 Received shared content: ${content.type.name}');

      // Always store as pending
      _pendingShareContent = content;

      // For warm start (app already past splash screen), navigate directly
      // Use 600ms delay to let any in-progress navigation settle
      Future.delayed(const Duration(milliseconds: 600), () {
        // If still pending (cold start handler didn't consume it), navigate now
        if (_pendingShareContent != null && _navigatorKey.currentState != null) {
          final pendingContent = _pendingShareContent!;
          _pendingShareContent = null;
          _navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => ImportContentScreen(content: pendingContent),
            ),
          );
        }
      });
    });
  }

  /// Called after MainNavigation is fully loaded to handle any pending share
  void navigateToImportIfPending() {
    final content = _pendingShareContent;
    if (content != null) {
      _pendingShareContent = null;
      debugPrint('📥 Navigating to ImportContentScreen for pending share');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_navigatorKey.currentState != null) {
          _navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => ImportContentScreen(content: content),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = AppStateProvider();
            // Initialize in the background, don't block UI
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'VoiceBubble',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark, // Always dark mode
              primaryColor: const Color(0xFF3B82F6), // Blue
              scaffoldBackgroundColor: const Color(0xFF000000),
              useMaterial3: true,
            ),
            navigatorObservers: [
              AnalyticsService().observer, // Track screen views
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    await Future.delayed(const Duration(seconds: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    
    if (mounted) {
      if (hasCompletedOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
        // Handle any pending share intent AFTER MainNavigation is loaded
        final appState = context.findAncestorStateOfType<_MyAppState>();
        appState?.navigateToImportIfPending();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingFlow(
              onComplete: (BuildContext navContext) async {
                debugPrint('✅ ONBOARDING COMPLETE - Navigating to HomeScreen');
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasCompletedOnboarding', true);
                debugPrint('✅ Saved hasCompletedOnboarding = true');
                
                // Use pushAndRemoveUntil to clear the entire navigation stack
                debugPrint('✅ Clearing navigation stack and going to MainNavigation...');
                Navigator.of(navContext).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainNavigation()),
                  (Route<dynamic> route) => false, // Remove all previous routes
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.mic,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'VoiceBubble',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingFlow extends StatefulWidget {
  final void Function(BuildContext) onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
    } else {
      widget.onComplete(context);
    }
  }

  void _handleSignIn() {
    _nextStep(); // Go to permissions after sign-in
  }

  void _closePaywall() {
    debugPrint('🎯 PAYWALL CLOSED - Starting free trial, navigating to HomeScreen');
    widget.onComplete(context);
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return OnboardingOne(onNext: _nextStep);
      case 1:
        return OnboardingTwo(onNext: _nextStep);
      case 2:
        return OnboardingThreeNew(onNext: _nextStep);
      case 3:
        return SignInScreen(onSignIn: _handleSignIn);
      case 4:
        return PermissionsScreen(onComplete: _nextStep);
      case 5:
        return PaywallScreen(
          onSubscribe: () {
            // TODO: Implement subscription
            widget.onComplete(context);
          },
          onRestore: () {
            // TODO: Implement restore
          },
          onClose: _closePaywall,
        );
      default:
        return const MainNavigation();
    }
  }
}
// Build trigger Wed Feb  4 04:01:23 GMT 2026
