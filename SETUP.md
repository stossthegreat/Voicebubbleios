# VoiceBubble Setup Guide

Complete setup instructions for developers and deployment.

## Environment Setup

### 1. OpenAI API Key

#### For Local Development

Create `.env` file in project root:
```env
OPENAI_API_KEY=sk-your-actual-api-key-here
```

#### For Railway/Production Deployment

Set environment variable:
```bash
OPENAI_API_KEY=sk-your-actual-api-key-here
```

### 2. Initial Setup

```bash
# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Verify installation
flutter doctor

# Run app
flutter run
```

## Android Release Build Setup

### 1. Create Keystore

```bash
cd android/app

keytool -genkey -v -keystore voicebubble-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias voicebubble

# Answer the prompts:
# - Enter keystore password (remember this!)
# - Re-enter password
# - Enter your name
# - Enter your organizational unit
# - Enter your organization name
# - Enter your city
# - Enter your state
# - Enter your country code (e.g., US)
# - Type "yes" to confirm
# - Enter key password (can be same as keystore password)
```

### 2. Create key.properties

Create `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=voicebubble
storeFile=voicebubble-release.jks
```

⚠️ **IMPORTANT**: Add `key.properties` and `*.jks` to `.gitignore` (already done)

### 3. Build Release APK

```bash
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 4. Build App Bundle (for Google Play)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

## iOS Release Build Setup

### 1. Apple Developer Account

- Enroll in Apple Developer Program ($99/year)
- Create App ID: `com.example.voicebubble`
- Create provisioning profiles

### 2. Xcode Configuration

```bash
# Open project in Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select Runner project
# 2. Select Runner target
# 3. Go to "Signing & Capabilities"
# 4. Select your team
# 5. Xcode will automatically create provisioning profiles
```

### 3. Build for TestFlight

```bash
# Build archive
flutter build ios --release

# Open in Xcode for upload
open build/ios/archive/Runner.xcarchive

# Or use Xcode directly:
# Product > Archive > Distribute App > App Store Connect
```

## GitHub Actions Setup (CI/CD)

### For Android Signed Builds

Add these secrets in GitHub repository settings:

```bash
# 1. Encode keystore to base64
base64 -i android/app/voicebubble-release.jks | pbcopy

# 2. Add to GitHub Secrets:
KEYSTORE_BASE64=<paste base64 output>
KEYSTORE_PASSWORD=<your keystore password>
KEY_PASSWORD=<your key password>
KEY_ALIAS=voicebubble
```

### For iOS Signed Builds

```bash
# 1. Export certificate as .p12 from Keychain Access
# 2. Encode to base64
base64 -i Certificates.p12 | pbcopy

# 3. Export provisioning profile
# 4. Encode to base64
base64 -i profile.mobileprovision | pbcopy

# 5. Add to GitHub Secrets:
IOS_CERTIFICATE_P12_BASE64=<certificate base64>
IOS_CERTIFICATE_PASSWORD=<certificate password>
IOS_PROVISIONING_PROFILE_BASE64=<profile base64>
APPSTORE_ISSUER_ID=<from App Store Connect>
APPSTORE_API_KEY_ID=<from App Store Connect>
APPSTORE_API_PRIVATE_KEY=<from App Store Connect>
```

### Enable Workflows

Uncomment the signing steps in:
- `.github/workflows/android.yml`
- `.github/workflows/ios.yml`

## Google Sign-In Setup

### Android

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google Sign-In API
4. Create OAuth 2.0 credentials
5. Add SHA-1 fingerprint:

```bash
# Debug SHA-1
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android

# Release SHA-1
keytool -list -v -keystore android/app/voicebubble-release.jks \
  -alias voicebubble
```

6. Download `google-services.json`
7. Place in `android/app/google-services.json`

### iOS

1. In Google Cloud Console, add iOS app
2. Enter Bundle ID: `com.example.voicebubble`
3. Download `GoogleService-Info.plist`
4. Add to `ios/Runner/` in Xcode

## Apple Sign-In Setup

### iOS

1. In Xcode, select Runner target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "Sign in with Apple"

### Android

1. Follow Apple's documentation for Android setup
2. Configure service ID in Apple Developer portal

## Railway Deployment (Backend/API)

If you're deploying a backend service:

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Initialize project
railway init

# Set environment variables
railway variables set OPENAI_API_KEY=sk-your-key-here

# Deploy
railway up
```

## Testing

### Run All Tests

```bash
flutter test
```

### Run with Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Analyze Code

```bash
flutter analyze
```

### Format Code

```bash
flutter format .
```

## Troubleshooting

### Android Build Issues

**Gradle version conflict:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Overlay permission not working:**
- Check Android version >= 7.0
- Manually grant permission in Settings > Apps > VoiceBubble > Display over other apps

### iOS Build Issues

**CocoaPods issues:**
```bash
cd ios
pod repo update
pod install
cd ..
```

**Code signing issues:**
- Verify Apple Developer account is active
- Check provisioning profiles in Xcode
- Ensure Bundle ID matches

### API Issues

**OpenAI API errors:**
- Verify API key is correct
- Check API key has credits
- Ensure `.env` file is loaded (for local dev)
- Check environment variables (for production)

**Speech-to-text not working:**
- Grant microphone permission
- Check device has internet connection
- Verify OpenAI API key

## Performance Optimization

### Android

```bash
# Build with optimization
flutter build apk --release --split-per-abi

# Results in smaller APKs:
# - app-armeabi-v7a-release.apk
# - app-arm64-v8a-release.apk
# - app-x86_64-release.apk
```

### iOS

```bash
# Enable bitcode (if needed)
flutter build ios --release --bitcode
```

## Monitoring

### Crash Reporting

Consider integrating:
- Firebase Crashlytics
- Sentry
- AppCenter

### Analytics

Consider integrating:
- Google Analytics
- Mixpanel
- Amplitude

## Support

For issues during setup:
- Check [GitHub Issues](https://github.com/yourusername/voicebubble/issues)
- Read [Flutter Documentation](https://flutter.dev/docs)
- Contact: support@voicebubble.app

