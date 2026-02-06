# VoiceBubble Deployment Checklist

Use this checklist before deploying to production or releasing to app stores.

## Pre-Deployment

### Code Quality
- [ ] All tests pass: `flutter test`
- [ ] Code analysis clean: `flutter analyze`
- [ ] Code formatted: `flutter format .`
- [ ] No debug print statements in production code
- [ ] All TODO comments addressed or documented

### Configuration
- [ ] OpenAI API key configured (environment variable or .env)
- [ ] App name correct: "VoiceBubble"
- [ ] Bundle ID set: `com.example.voicebubble`
- [ ] Version number updated in `pubspec.yaml`
- [ ] Build numbers incremented

### Android
- [ ] Application ID: `com.example.voicebubble`
- [ ] minSdk: 24 (Android 7.0)
- [ ] targetSdk: 34 (Android 14)
- [ ] Permissions declared in AndroidManifest.xml
- [ ] Keystore created and secured
- [ ] `key.properties` created (for signed builds)
- [ ] ProGuard rules configured
- [ ] App icons updated
- [ ] Overlay service configured

### iOS
- [ ] Bundle identifier: `com.example.voicebubble`
- [ ] Deployment target: iOS 12.0+
- [ ] Info.plist permissions configured
- [ ] Code signing certificates installed
- [ ] Provisioning profiles configured
- [ ] App icons updated
- [ ] Sign in with Apple capability added

## Testing

### Functional Testing
- [ ] Onboarding flow works
- [ ] Voice recording works
- [ ] Speech-to-text transcription accurate
- [ ] AI rewriting generates correct results
- [ ] All presets work correctly
- [ ] Vault saves and displays items
- [ ] Settings changes persist
- [ ] Theme switching works
- [ ] Android overlay appears and functions
- [ ] Permissions requested correctly
- [ ] Copy to clipboard works
- [ ] Sign-in screen displays (placeholders)

### Device Testing
- [ ] Tested on Android phone
- [ ] Tested on Android tablet
- [ ] Tested on iOS iPhone
- [ ] Tested on iOS iPad
- [ ] Tested on different screen sizes
- [ ] Tested on different OS versions

### Performance
- [ ] App starts quickly (< 3 seconds)
- [ ] No memory leaks
- [ ] Smooth animations
- [ ] No frame drops during recording
- [ ] API calls timeout appropriately
- [ ] Offline handling graceful

## Security & Privacy

### Data Protection
- [ ] API keys not hardcoded
- [ ] Sensitive data not logged
- [ ] HTTPS used for all network calls
- [ ] Voice data deleted after processing
- [ ] Local storage encrypted (if needed)

### Permissions
- [ ] Microphone permission with clear description
- [ ] Overlay permission with clear description (Android)
- [ ] Minimal permissions requested
- [ ] Permission rationales user-friendly

### Legal
- [ ] Terms & Conditions complete
- [ ] Privacy Policy complete and accurate
- [ ] Data collection disclosed
- [ ] Third-party services listed (OpenAI)
- [ ] GDPR compliance (if applicable)
- [ ] CCPA compliance (if applicable)

## Build & Release

### Android Release
- [ ] Build release APK: `flutter build apk --release`
- [ ] Build App Bundle: `flutter build appbundle --release`
- [ ] APK signed with release keystore
- [ ] Test release build on device
- [ ] Screenshots prepared (at least 2)
- [ ] Feature graphic created
- [ ] Store listing text ready
- [ ] Privacy policy URL accessible

### iOS Release
- [ ] Build archive: `flutter build ios --release`
- [ ] Archive in Xcode successful
- [ ] Export IPA for distribution
- [ ] Test TestFlight build
- [ ] Screenshots prepared (all required sizes)
- [ ] App preview video (optional)
- [ ] Store listing text ready
- [ ] Privacy policy URL accessible

### App Store Listing

#### Google Play Store
- [ ] App title (30 characters max)
- [ ] Short description (80 characters)
- [ ] Full description (4000 characters)
- [ ] Screenshots (2-8 images)
- [ ] Feature graphic (1024 x 500)
- [ ] App icon (512 x 512)
- [ ] Content rating completed
- [ ] Privacy policy URL added
- [ ] Support email provided

#### Apple App Store
- [ ] App name
- [ ] Subtitle (30 characters)
- [ ] Promotional text (170 characters)
- [ ] Description
- [ ] Keywords (100 characters)
- [ ] Screenshots (all required sizes)
- [ ] App preview (optional)
- [ ] Support URL
- [ ] Privacy policy URL
- [ ] App category selected

## Post-Release

### Monitoring
- [ ] Crash reporting setup
- [ ] Analytics configured
- [ ] User feedback channel established
- [ ] App store reviews monitored
- [ ] Performance metrics tracked

### Support
- [ ] Support email monitored
- [ ] FAQ updated based on feedback
- [ ] Known issues documented
- [ ] Update plan established

### Documentation
- [ ] README updated
- [ ] CHANGELOG updated
- [ ] API documentation current
- [ ] User guides available (if needed)

## Rollback Plan

If issues arise post-release:

1. **Immediate Issues**
   - Pull app from stores if critical bug
   - Post announcement on support channels
   - Prepare hotfix

2. **Minor Issues**
   - Document in known issues
   - Plan for next update
   - Communicate timeline to users

3. **Hotfix Process**
   - Fix critical bug
   - Test thoroughly
   - Increment version
   - Submit expedited review

## Notes

- Keep keystore and certificates backed up securely
- Maintain version history and release notes
- Document any custom configurations
- Save all store assets for future updates
- Keep track of which API keys are used in production

---

**Ready to Deploy?** Only check all boxes when you're confident the app is production-ready!

