# 🚀 VoiceBubble Launch Guide

## 📋 Quick Reference

### 🔑 Keystore & SHA Fingerprints

**Keystore Location:**
```
android/app/keystore/voicebubble-release.jks
```

**Keystore Credentials:**
```
Store Password: voicebubble2024
Key Password: voicebubble2024
Key Alias: voicebubble
Validity: 10,000 days (27+ years)
```

**SHA-1 Fingerprint (for Firebase):**
```
C4:AC:8A:A6:F2:12:E6:1F:9B:8F:B2:0F:EC:3C:18:1E:7B:D0:A1:E3
```

**SHA-256 Fingerprint (for Firebase):**
```
49:6E:31:8D:C8:23:4B:77:68:79:62:BF:3C:3C:82:46:73:DB:BE:2E:B8:39:95:D0:5A:B7:1F:B4:42:06:99:7F
```

---

## 🔥 Firebase Setup Checklist

### Step 1: Add SHA Keys to Firebase Console
1. Go to **Firebase Console** → Your Project → Project Settings
2. Under "Your apps" → Android app
3. Click "Add fingerprint"
4. Add **SHA-1**: `C4:AC:8A:A6:F2:12:E6:1F:9B:8F:B2:0F:EC:3C:18:1E:7B:D0:A1:E3`
5. Add **SHA-256**: `49:6E:31:8D:C8:23:4B:77:68:79:62:BF:3C:3C:82:46:73:DB:BE:2E:B8:39:95:D0:5A:B7:1F:B4:42:06:99:7F`

### Step 2: Download google-services.json
1. After adding SHA keys, download the updated `google-services.json`
2. Place it in: `android/app/google-services.json`
3. **Replace** the existing file if one exists

### Step 3: Enable Authentication Methods
1. Go to Firebase Console → Authentication → Sign-in method
2. Enable **Google** sign-in provider
3. Configure OAuth consent screen if needed

---

## 🏗️ Building the App

### Debug Build (Development)
```bash
flutter build apk --debug
```

### Release Build (Production - for Play Store)
```bash
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

### Release APK (for manual distribution)
```bash
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

---

## ✅ Pre-Launch Checklist

### Firebase Configuration
- [ ] SHA-1 and SHA-256 added to Firebase Console
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] Google Sign-In enabled in Firebase Authentication
- [ ] OAuth consent screen configured

### App Configuration
- [ ] App version updated in `android/app/build.gradle.kts` (versionCode & versionName)
- [ ] App icon finalized
- [ ] App name verified in `AndroidManifest.xml`
- [ ] Backend URL confirmed: `https://voicebubble-production.up.railway.app`

### Backend (Railway)
- [ ] Backend deployed and healthy
- [ ] `OPENAI_API_KEY` environment variable set
- [ ] Redis database added and connected
- [ ] Health check passing: `/health`

### Testing
- [ ] Sign-in flow tested (Google)
- [ ] Voice recording working
- [ ] AI presets working
- [ ] Floating bubble functional
- [ ] Boot persistence tested (bubble auto-starts after reboot)

---

## 📱 App Store Submission

### Google Play Store

**1. Build Release Bundle:**
```bash
flutter build appbundle --release
```

**2. Upload to Play Console:**
- Go to Google Play Console → Your App → Production → Create new release
- Upload `app-release.aab`
- Fill in release notes
- Submit for review

**3. Required Assets:**
- App icon: 512x512 PNG
- Feature graphic: 1024x500 PNG
- Screenshots: At least 2 (phone), ideally 4-8
- Privacy policy URL (if collecting user data)

**4. App Details:**
- **Category:** Productivity / Tools
- **Content rating:** Everyone
- **Pricing:** Free (with in-app purchases: $4.99)

---

## 🔐 Security Notes

### Keystore Backup
⚠️ **CRITICAL:** Back up your keystore file!

**Backup locations:**
1. Secure cloud storage (Google Drive, Dropbox - encrypted)
2. External hard drive
3. Password manager (as secure note)

**If you lose the keystore, you CANNOT update the app on Play Store!**

### Credentials to Save
```
Keystore file: android/app/keystore/voicebubble-release.jks
Store password: voicebubble2024
Key password: voicebubble2024
Key alias: voicebubble
```

---

## 🌐 Backend Configuration

### Railway Environment Variables
```
OPENAI_API_KEY=sk-proj-...
REDIS_URL=redis://default:...
PORT=8080
NODE_ENV=production
```

### Backend URLs
- **Production:** https://voicebubble-production.up.railway.app
- **Health Check:** https://voicebubble-production.up.railway.app/health
- **Transcribe:** POST /api/transcribe
- **Rewrite:** POST /api/rewrite/batch

---

## 📊 App Features Summary

### Core Features
- ✅ Voice-to-text (Whisper API)
- ✅ AI text rewriting (GPT-4 mini)
- ✅ 30+ AI presets (professional, casual, poetry, etc.)
- ✅ Floating bubble overlay (works over any app)
- ✅ 30+ languages support
- ✅ Boot persistence (bubble auto-starts)
- ✅ Black & blue minimal design

### Onboarding Flow
1. Welcome screen
2. Bubble demo
3. Features + pricing (90 min STT for $4.99)
4. **Mandatory sign-in** (Google)
5. Permissions (microphone, display over apps)
6. Paywall (optional skip)

---

## 🐛 Troubleshooting

### Build Issues
```bash
# Clean build
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ..
flutter build apk --release
```

### Firebase Sign-In Not Working
1. Verify SHA-1 and SHA-256 are in Firebase Console
2. Re-download `google-services.json`
3. Rebuild the app
4. Check Firebase Authentication is enabled

### Keystore Issues
```bash
# Verify keystore
keytool -list -v -keystore android/app/keystore/voicebubble-release.jks -alias voicebubble -storepass voicebubble2024
```

---

## 📞 Support

- Backend: Railway dashboard
- Firebase: Firebase Console
- OpenAI: OpenAI Platform
- App crashes: Play Console → Vitals

---

**Last Updated:** December 2024  
**App Version:** 1.0.0  
**Package:** com.example.voicebubble


