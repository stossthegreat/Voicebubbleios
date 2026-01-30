// ============================================================
//        APP CONFIGURATION
// ============================================================

class AppConfig {
  static const String baseUrl = 'https://your-backend.com/api';
  static const String version = '1.0.0';
  static const bool isProduction = false;
  
  // API Endpoints
  static const String textTransformEndpoint = '$baseUrl/text-transform';
  
  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration speechTimeout = Duration(minutes: 5);
}