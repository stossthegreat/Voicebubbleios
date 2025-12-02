import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/theme_provider.dart';
import 'providers/app_state_provider.dart';
import 'services/storage_service.dart';
import 'services/flutter_overlay_service.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_one.dart';
import 'screens/onboarding/onboarding_two.dart';
import 'screens/onboarding/onboarding_three_new.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/onboarding/permissions_screen.dart';
import 'screens/paywall/paywall_screen.dart';
import 'screens/main/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  await StorageService.initialize();
  
  // Initialize Flutter overlay service
  FlutterOverlayService.initialize();
  
  // Load environment variables (if .env file exists)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('No .env file found, using environment variables');
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const VoiceBubbleApp());
}

class VoiceBubbleApp extends StatelessWidget {
  const VoiceBubbleApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()..initialize()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'VoiceBubble',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});
  
  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _showOnboarding = true;
  
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }
  
  Future<void> _checkOnboardingStatus() async {
    final isComplete = await StorageService.isOnboardingComplete();
    
    setState(() {
      _showOnboarding = !isComplete;
      _isLoading = false;
    });
  }
  
  Future<void> _completeOnboarding() async {
    await StorageService.setOnboardingComplete();
    setState(() {
      _showOnboarding = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_showOnboarding) {
      return OnboardingFlow(onComplete: _completeOnboarding);
    }
    
    return const HomeScreen();
  }
}

class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingFlow({super.key, required this.onComplete});
  
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;
  bool _isSignedIn = false;
  
  void _nextStep() {
    if (_currentStep < 6) {
      setState(() {
        _currentStep++;
      });
    } else {
      widget.onComplete();
    }
  }
  
  void _skipSignIn() {
    setState(() {
      _isSignedIn = false;
      _currentStep = 5; // Skip to permissions
    });
  }
  
  void _handleSignIn() {
    setState(() {
      _isSignedIn = true;
      _currentStep = 5; // Go to permissions
    });
  }
  
  void _closePaywall() {
    widget.onComplete();
  }
  
  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return OnboardingOne(onNext: _nextStep);
      case 1:
        return OnboardingTwo(onNext: _nextStep);
      case 2:
        return OnboardingThreeNew(onNext: _nextStep); // Features + pricing
      case 3:
        return SignInScreen(
          onSignIn: _handleSignIn,
          onSkip: _skipSignIn,
        );
      case 4:
        return PermissionsScreen(onComplete: _nextStep);
      case 5:
        return PaywallScreen(
          onSubscribe: () {
            // TODO: Implement subscription
            widget.onComplete();
          },
          onRestore: () {
            // TODO: Implement restore
          },
          onClose: _closePaywall,
        );
      default:
        return const HomeScreen();
    }
  }
}
