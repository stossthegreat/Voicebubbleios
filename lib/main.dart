import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Imported solely so the AOT compiler keeps `overlayMain` (and its widget
// tree) reachable — flutter_overlay_window registers it via the manifest's
// io.flutter.overlay.window.overlayEntryPoint meta-data.
// ignore: unused_import
import 'overlay_main.dart';
import 'providers/app_state_provider.dart';
import 'providers/theme_provider.dart';
import 'services/subscription_service.dart';
import 'services/storage_service.dart';
import 'services/reminder_manager.dart';
import 'services/analytics_service.dart';
import 'services/share_handler_service.dart';
import 'screens/main/main_navigation.dart';
import 'screens/onboarding/permissions_screen.dart';
import 'screens/onboarding/feature_showcase_screen.dart';
import 'screens/import/import_content_screen.dart';
import 'services/retention_notification_service.dart';
import 'services/notification_service.dart';

void main() async {
  // Catch Flutter framework errors first thing so any later crash is logged.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('❌ Flutter error: ${details.exception}');
    debugPrint('❌ Stack: ${details.stack}');
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Top-level try/catch with on-screen fallback. Mirrors the working app
  // pattern: if anything in startup throws (e.g. Firebase, Hive, a plugin
  // platform channel), we still call runApp with a visible error screen
  // instead of letting iOS show a black screen and silently terminate.
  try {
    // Init Firebase WITHOUT explicit options — matches the working app
    // pattern. On iOS the SDK auto-discovers GoogleService-Info.plist from
    // the bundle; on Android google-services.json is processed at build
    // time. Passing options: here on top of native auto-init throws
    // "FirebaseApp [DEFAULT] already exists" on iOS.
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized');
    } catch (e, st) {
      debugPrint('⚠️ Firebase init failed (non-fatal): $e');
      debugPrint('$st');
    }

    try {
      AnalyticsService();
      debugPrint('✅ Analytics initialized');
    } catch (e) {
      debugPrint('⚠️ Analytics init failed (non-fatal): $e');
    }

    try {
      await StorageService.initialize();
      debugPrint('✅ Hive storage initialized');
    } catch (e) {
      debugPrint('⚠️ Hive init failed (non-fatal): $e');
    }

    try {
      await ReminderManager().initialize();
      debugPrint('✅ Reminder system initialized');
    } catch (e) {
      debugPrint('⚠️ Reminder init failed (non-fatal): $e');
    }

    try {
      await SubscriptionService().initialize();
      debugPrint('✅ Subscription service initialized');
    } catch (e) {
      debugPrint('⚠️ Subscription init failed (non-fatal): $e');
    }

    try {
      ShareHandlerService().initialize();
      debugPrint('✅ Share handler initialized');
    } catch (e) {
      debugPrint('⚠️ Share handler init failed (non-fatal): $e');
    }

    // Hide widget build errors from end users; log to console instead.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint('❌ Widget build error: ${details.exception}');
      return const SizedBox.shrink();
    };

    runApp(const MyApp());
  } catch (e, stack) {
    // Last-resort: at least show SOMETHING so the user (and we) can see
    // what blew up instead of an instant crash on launch.
    debugPrint('❌ APP INIT CRASHED: $e');
    debugPrint('$stack');
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ App init crashed',
                  style: TextStyle(
                    color: Color(0xFF7C6AE8),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  e.toString(),
                  style: const TextStyle(
                    color: Color(0xFFFF4444),
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  stack.toString().split('\n').take(20).join('\n'),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
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
    // Check for buffered content from cold start (arrived before we subscribed)
    final buffered = ShareHandlerService().consumeBufferedContent();
    if (buffered != null) {
      debugPrint('📥 Found buffered share content from cold start: ${buffered.type.name}');
      _pendingShareContent = buffered;
    }

    // Listen for future shares (warm start or late cold start delivery)
    ShareHandlerService().pendingShares.listen((content) {
      debugPrint('📥 Stream received shared content: ${content.type.name}');
      _pendingShareContent = content;

      // For warm start: navigate after a delay (no splash race)
      // For cold start: _navigateToImportIfPending() will handle it after splash
      Future.delayed(const Duration(milliseconds: 1500), () {
        // Only navigate if still pending (cold start handler may have consumed it)
        if (_pendingShareContent != null && _navigatorKey.currentState != null) {
          final pendingContent = _pendingShareContent!;
          _pendingShareContent = null;
          debugPrint('📥 Warm start: navigating to ImportContentScreen');
          _navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => ImportContentScreen(content: pendingContent),
            ),
          );
        }
      });
    });
  }

  /// Called after MainNavigation is loaded to handle any pending share from cold start
  void _navigateToImportIfPending() {
    final content = _pendingShareContent;
    if (content == null) return;

    _pendingShareContent = null;
    debugPrint('📥 Cold start: navigating to ImportContentScreen after splash');

    // Delay to ensure MainNavigation is fully built and mounted
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_navigatorKey.currentState != null) {
        _navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ImportContentScreen(content: content),
          ),
        );
      }
    });
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
        // Track open + cancel retention if subscribed (matches Android)
        try {
          await RetentionNotificationService().recordAppOpen();
          if (await SubscriptionService().isPro()) {
            final ns = NotificationService();
            for (final id in [900001, 900002, 900003, 900004, 900005, 900006, 900007]) {
              await ns.cancelReminder(id);
            }
          }
        } catch (_) {}

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
        // After MainNavigation is loaded, handle any pending share intent
        final myAppState = context.findAncestorStateOfType<_MyAppState>();
        myAppState?._navigateToImportIfPending();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingFlow(
              onComplete: (BuildContext navContext) async {
                debugPrint('✅ ONBOARDING COMPLETE - Navigating to HomeScreen');
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasCompletedOnboarding', true);

                // Schedule retention notifications once, for non-subscribers
                try {
                  if (!(await SubscriptionService().isPro())) {
                    await RetentionNotificationService().scheduleOnboardingRetention();
                  }
                } catch (_) {}
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
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
    if (_currentStep >= 2) {
      widget.onComplete(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return FeatureShowcaseScreen(onComplete: _nextStep);
      case 1:
        return PermissionsScreen(onComplete: _nextStep);
      case 2:
        return const MainNavigation();
      default:
        return const MainNavigation();
    }
  }
}
// Build trigger Wed Feb  4 04:01:23 GMT 2026
