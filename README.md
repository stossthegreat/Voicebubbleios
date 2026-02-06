# VoiceBubble 🎤

Transform your voice into perfectly written text with AI-powered rewriting. VoiceBubble is a professional voice-to-text application with a floating Android overlay, multiple writing styles, and beautiful light/dark themes.

![Flutter](https://img.shields.io/badge/Flutter-3.24.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ✨ Features

### Core Functionality
- 🎙️ **Voice-to-Text**: Real-time speech recognition using OpenAI Whisper
- 🤖 **AI Rewriting**: Multiple writing styles powered by GPT-4o-mini
- 📱 **Android Overlay**: Floating bubble that works over any app (when keyboard is open)
- 💾 **Vault**: Save and manage your recordings
- 🌓 **Light/Dark Modes**: Beautiful themes with smooth transitions

### Writing Presets
40+ preset styles organized into categories:
- **General**: Magic, Slightly, Significantly
- **Text Editing**: Structured, Shorter, List
- **Content Creation**: X Post, LinkedIn, Instagram, Video Scripts, Newsletter
- **Journaling**: Journal Entry, Gratitude Journal
- **Emails**: Casual Email, Formal Email
- **Summary**: Short Summary, Detailed Summary, Meeting Takeaways
- **Writing Styles**: Business, Formal, Casual, Friendly, Clear & Concise
- **Holiday Greetings**: Funny, Warm, Simple & Professional

### Professional Features
- 🔐 **Authentication**: Google and Apple Sign-In placeholders
- 📄 **Legal Pages**: Complete Terms & Conditions, Privacy Policy
- ⚙️ **Settings**: Comprehensive settings with theme toggle, language selection
- 🆘 **Help & Support**: FAQ and support contact
- 🔔 **Permissions**: Proper microphone and overlay permissions handling

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart SDK 3.9.2 or higher
- Android Studio / Xcode (for mobile development)
- OpenAI API Key

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/voicebubble.git
cd voicebubble
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run code generation**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Setup environment variables**

Create a `.env` file in the root directory:
```env
OPENAI_API_KEY=your_openai_api_key_here
```

Or set environment variable (for Railway deployment):
```bash
export OPENAI_API_KEY=your_openai_api_key_here
```

5. **Run the app**
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Specific device
flutter devices
flutter run -d <device-id>
```

## 🔧 Configuration

### Android Setup

#### Overlay Permission
The floating overlay requires the `SYSTEM_ALERT_WINDOW` permission. This is automatically requested in the app.

#### Build Configuration
Located in `android/app/build.gradle.kts`:
- Application ID: `com.example.voicebubble`
- Min SDK: 24 (Android 7.0)
- Target SDK: 34 (Android 14)

#### Signing (for Release Builds)

1. Create a keystore:
```bash
keytool -genkey -v -keystore voicebubble-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias voicebubble
```

2. Create `android/key.properties`:
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=voicebubble
storeFile=voicebubble-release.jks
```

3. Build release APK:
```bash
flutter build apk --release
```

### iOS Setup

#### Permissions
Configured in `ios/Runner/Info.plist`:
- Microphone access: `NSMicrophoneUsageDescription`
- Speech recognition: `NSSpeechRecognitionUsageDescription`

#### Bundle Identifier
Update in Xcode: `com.example.voicebubble`

#### Build

```bash
# Debug
flutter build ios --debug

# Release (requires code signing)
flutter build ios --release
```

## 🎨 Project Structure

```
lib/
├── constants/          # App constants and preset definitions
├── models/            # Data models (Preset, ArchivedItem)
├── providers/         # State management (Theme, AppState)
├── screens/           # All app screens
│   ├── auth/         # Sign-in screen
│   ├── main/         # Home, Recording, Preset Selection, Result, Vault
│   ├── onboarding/   # Onboarding flow (3 screens + permissions)
│   └── settings/     # Settings, Terms, Privacy, Help
├── services/          # Business logic
│   ├── ai_service.dart      # OpenAI integration
│   ├── overlay_service.dart # Android overlay
│   └── storage_service.dart # Local storage
├── theme/            # App themes (light/dark)
├── widgets/          # Reusable widgets
├── main.dart         # App entry point
└── overlay_main.dart # Overlay entry point
```

## 🤖 AI Integration

### OpenAI Services

**Whisper API** - Speech-to-Text
- Model: `whisper-1`
- Language: English (configurable)
- Real-time transcription

**GPT-4o-mini** - Text Rewriting
- Model: `gpt-4o-mini`
- Context-aware prompts for each preset
- Temperature: 0.7
- Max tokens: 500

### Development Mode
When no API key is provided, the app uses mock responses for development/testing.

## 📱 Android Overlay

The floating overlay feature:
- Shows when keyboard is open
- Tap to expand
- Record voice directly from overlay
- Select preset and generate text
- Works over any app (WhatsApp, Gmail, etc.)

**Implementation**: Uses `flutter_overlay_window` package with custom UI in `lib/overlay_main.dart`

## 🔄 CI/CD

### GitHub Actions Workflows

**Android Build** (`.github/workflows/android.yml`)
- Builds debug and release APKs
- Runs tests and analysis
- Uploads artifacts
- Optional: Auto-release to GitHub

**iOS Build** (`.github/workflows/ios.yml`)
- Builds iOS app
- Runs tests and analysis
- Optional: Upload to TestFlight

### Setup GitHub Secrets (for signed builds)

Android:
- `KEYSTORE_BASE64`: Base64 encoded keystore file
- `KEYSTORE_PASSWORD`: Keystore password
- `KEY_PASSWORD`: Key password
- `KEY_ALIAS`: Key alias

iOS:
- `IOS_CERTIFICATE_P12_BASE64`: Base64 encoded certificate
- `IOS_CERTIFICATE_PASSWORD`: Certificate password
- `IOS_PROVISIONING_PROFILE_BASE64`: Base64 encoded provisioning profile
- `APPSTORE_ISSUER_ID`: App Store Connect issuer ID
- `APPSTORE_API_KEY_ID`: App Store Connect API key ID
- `APPSTORE_API_PRIVATE_KEY`: App Store Connect private key

## 🛠️ Building for Production

### Android APK

```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
# Archive for App Store
flutter build ios --release

# Then open in Xcode:
open ios/Runner.xcworkspace
# Archive and upload via Xcode
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## 📦 Dependencies

### Main Dependencies
- `provider`: State management
- `google_fonts`: Typography
- `hive`: Local storage
- `speech_to_text`: Voice recognition
- `dio`: HTTP client
- `flutter_overlay_window`: Android overlay
- `permission_handler`: Permissions
- `google_sign_in`: Google authentication
- `sign_in_with_apple`: Apple authentication

### Dev Dependencies
- `flutter_lints`: Code analysis
- `build_runner`: Code generation
- `hive_generator`: Hive adapters

## 🔐 Privacy & Security

- Voice recordings are processed in real-time and immediately deleted
- No voice data is permanently stored
- Transcribed text is stored locally on device
- Optional cloud backup (if enabled by user)
- Full Privacy Policy available in-app

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

- Email: support@voicebubble.app
- Website: www.voicebubble.app
- Privacy: privacy@voicebubble.app

## 🙏 Acknowledgments

- OpenAI for Whisper and GPT-4o-mini APIs
- Flutter team for the amazing framework
- All open-source contributors

---

**Made with ❤️ using Flutter**
