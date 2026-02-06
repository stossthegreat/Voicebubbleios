# 🔥 Firebase Setup Guide for VoiceBubble

## ⚠️ CRITICAL: This is REQUIRED for authentication to work!

Without Firebase, users **CANNOT** sign in/sign up and you **CANNOT** track trial periods!

---

## 📋 Step-by-Step Setup (30 minutes)

### 1. Create Firebase Project (5 min)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. **Project name:** `VoiceBubble`
4. **Google Analytics:** Enable (recommended)
5. Click **"Create project"**

---

### 2. Add Android App (10 min)

1. In Firebase Console, click **"Add app"** → **Android**

2. **Android package name:**
   ```
   com.example.voicebubble
   ```

3. **App nickname (optional):** `VoiceBubble Android`

4. **Debug signing certificate SHA-1:**
   
   Run this command in your project:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   
   Look for **SHA1** under `Variant: debug`:
   ```
   SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
   ```
   
   Copy and paste it into Firebase Console.

5. Click **"Register app"**

6. **Download `google-services.json`**
   - Click the download button
   - Place it in: `/home/felix/voicebubble/android/app/google-services.json`

7. Firebase will show you build.gradle modifications - **ALREADY DONE!**
   
   Your project already has these in `android/build.gradle.kts` and `android/app/build.gradle.kts`

8. Click **"Next"** → **"Continue to console"**

---

### 3. Enable Authentication Methods (5 min)

1. In Firebase Console, go to **Build** → **Authentication**

2. Click **"Get started"**

3. Go to **"Sign-in method"** tab

4. Enable these providers:

   **Email/Password:**
   - Click on "Email/Password"
   - Toggle **"Enable"**
   - Click **"Save"**

   **Google:**
   - Click on "Google"
   - Toggle **"Enable"**
   - **Support email:** (select your email)
   - Click **"Save"**

---

### 4. Enable Firestore Database (5 min)

1. In Firebase Console, go to **Build** → **Firestore Database**

2. Click **"Create database"**

3. **Start in production mode** (recommended)

4. **Location:** Choose closest to your users (e.g., `us-central` or `europe-west`)

5. Click **"Enable"**

6. Go to **"Rules"** tab and update:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

7. Click **"Publish"**

---

### 5. Add Firebase to Your Project (5 min)

**Dependencies are ALREADY ADDED!** ✅

Your `pubspec.yaml` now has:
```yaml
firebase_core: ^3.8.1
firebase_auth: ^5.3.3
google_sign_in: ^6.2.1
cloud_firestore: ^5.5.2
```

**Just run:**
```bash
cd /home/felix/voicebubble
flutter pub get
```

---

### 6. Add google-services.json

**Critical file location:**
```
/home/felix/voicebubble/android/app/google-services.json
```

**File structure should be:**
```
android/
├── app/
│   ├── google-services.json  ← PUT IT HERE!
│   ├── build.gradle.kts
│   └── src/
├── build.gradle.kts
└── settings.gradle.kts
```

**⚠️ DO NOT commit this file to GitHub (it's in .gitignore)**

---

### 7. Test Authentication (2 min)

1. Run the app:
   ```bash
   flutter run
   ```

2. Go through onboarding to sign-in screen

3. Try **creating an account** with:
   - Name: Test User
   - Email: test@example.com
   - Password: test123

4. Check Firebase Console → Authentication → Users
   - You should see your test user!

5. Try **signing in** with the same credentials

---

## 🔍 Verify Setup

### ✅ Checklist

- [ ] Firebase project created: `VoiceBubble`
- [ ] Android app added with package: `com.example.voicebubble`
- [ ] SHA-1 certificate added to Firebase
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] Email/Password auth enabled in Firebase Console
- [ ] Google Sign-In enabled in Firebase Console
- [ ] Firestore Database created with rules
- [ ] `flutter pub get` run successfully
- [ ] Test user created successfully
- [ ] Can sign in with test credentials

---

## 📊 What Firebase Tracks for Trial

Your `AuthService` automatically stores in Firestore:

```javascript
/users/{userId}
  ├── uid: "abc123..."
  ├── email: "user@example.com"
  ├── fullName: "John Doe"
  ├── createdAt: Timestamp (2025-12-04 10:30:00)  ← THIS IS KEY!
  ├── lastSignIn: Timestamp
  ├── isPremium: false
  ├── trialStartDate: Timestamp
  └── speechToTextMinutesUsed: 0.0
```

**Trial Logic:**
- `createdAt` = when user signed up
- Trial = 1 day from `createdAt`
- After 1 day → show paywall
- Track usage in `speechToTextMinutesUsed` (max 90 min/month)

---

## 🎯 Trial Period Enforcement

**Already implemented in `AuthService`:**

```dart
// Check if user is in trial (1 day)
final isInTrial = await AuthService().isInTrialPeriod();

// Get remaining trial hours
final remainingHours = await AuthService().getRemainingTrialHours();

if (!isInTrial && !isPremium) {
  // Show paywall
  Navigator.push(...PaywallScreen());
}
```

**Use this before recording:**
```dart
Future<void> _startRecording() async {
  final authService = AuthService();
  final isInTrial = await authService.isInTrialPeriod();
  final isPremium = false; // TODO: Get from subscription service
  
  if (!isInTrial && !isPremium) {
    // Show paywall
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaywallScreen(...)),
    );
    return;
  }
  
  // Continue with recording...
}
```

---

## 🔐 Security Rules (Firestore)

**Current rules:**
```javascript
// Users can only access their own data
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

**This ensures:**
- Users must be authenticated
- Users can only read/write their own user document
- No cross-user data access

---

## 🚨 Common Issues & Solutions

### Issue 1: "No Firebase App"
**Error:** `[core/no-app] No Firebase App '[DEFAULT]' has been created`

**Solution:** Make sure `google-services.json` is in `android/app/`

---

### Issue 2: Google Sign-In Fails
**Error:** `PlatformException(sign_in_failed)`

**Solution:** 
1. Make sure SHA-1 is added to Firebase Console
2. Download fresh `google-services.json`
3. Rebuild app: `flutter clean && flutter build apk`

---

### Issue 3: "Auth domain not whitelisted"
**Error:** Auth domain not whitelisted

**Solution:**
1. Firebase Console → Authentication → Settings
2. Add your domain to authorized domains

---

### Issue 4: Can't create users
**Error:** `email-already-in-use` or no error but user not created

**Solution:**
1. Check Firebase Console → Authentication → Users
2. User might exist already
3. Check Firestore rules are correct

---

## 📞 Support

**Firebase Docs:** https://firebase.google.com/docs  
**Flutter Firebase:** https://firebase.flutter.dev/  
**Auth Setup:** https://firebase.google.com/docs/auth/android/start  

---

## 🎯 Next Steps After Setup

1. ✅ Complete Firebase setup (this guide)
2. Run `flutter pub get`
3. Test sign-up/sign-in flow
4. Verify user appears in Firebase Console
5. Check trial period tracking works
6. Add paywall enforcement (use `isInTrialPeriod()`)
7. Continue with Play Store submission!

---

**Firebase is THE KEY to tracking users and trials! Set it up NOW! ⚡**

