# In-App Purchase & Subscription Setup Guide

This guide will walk you through setting up Apple App Store and Google Play Store subscriptions for VoiceBubble.

## Overview

The app now has a complete in-app purchase (IAP) system that supports:
- ✅ Apple App Store subscriptions (iOS)
- ✅ Google Play Store subscriptions (Android)
- ✅ Restore purchases functionality
- ✅ Backend receipt validation (basic setup included)
- ✅ Firestore integration for subscription status

## 📋 Prerequisites

Before you begin, make sure you have:
1. An Apple Developer account (for iOS)
2. A Google Play Console account (for Android)
3. Firebase project set up with Firestore enabled
4. Backend server deployed (for receipt validation)

---

## 🍎 Apple App Store Setup

### 1. Create Subscription Products in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Select your app
3. Go to **Features** > **In-App Purchases**
4. Click the **+** button to create a new subscription
5. Select **Auto-Renewable Subscription**

Create two subscriptions:
- **Monthly Subscription**
  - Reference Name: `VoiceBubble Monthly`
  - Product ID: `voicebubble_monthly` (must match the ID in `subscription_service.dart`)
  - Price: $5.99/month
  
- **Yearly Subscription**
  - Reference Name: `VoiceBubble Yearly`
  - Product ID: `voicebubble_yearly` (must match the ID in `subscription_service.dart`)
  - Price: $49.99/year

### 2. Set Up Subscription Group

1. Create a new subscription group (e.g., "VoiceBubble Premium")
2. Add both monthly and yearly subscriptions to this group
3. Set the yearly subscription at a higher level to show "upgrade" badge

### 3. Get Your Shared Secret

1. In App Store Connect, go to **My Apps** > [Your App] > **App Information**
2. Scroll to **App-Specific Shared Secret**
3. Click **Generate** if you don't have one
4. Copy the shared secret
5. Add it to your backend `.env` file:
   ```
   APPLE_SHARED_SECRET=your_shared_secret_here
   ```

### 4. Configure iOS Project

The iOS configuration is already done in the code, but make sure:
- Your app's Bundle ID matches the one in App Store Connect
- You've enabled In-App Purchase capability in Xcode

### 5. Test with Sandbox

1. In App Store Connect, go to **Users and Access** > **Sandbox Testers**
2. Create a sandbox tester account
3. On your iOS device, sign out of your real Apple ID
4. When testing, use the sandbox account to make test purchases

---

## 🤖 Google Play Store Setup

### 1. Create Subscription Products in Play Console

1. Go to [Google Play Console](https://play.google.com/console/)
2. Select your app
3. Go to **Monetize** > **Subscriptions**
4. Click **Create subscription**

Create two subscriptions:
- **Monthly Subscription**
  - Product ID: `voicebubble_monthly` (must match the ID in `subscription_service.dart`)
  - Base plan: Monthly billing period
  - Price: $5.99/month
  
- **Yearly Subscription**
  - Product ID: `voicebubble_yearly` (must match the ID in `subscription_service.dart`)
  - Base plan: Yearly billing period
  - Price: $49.99/year

### 2. Set Up Billing

1. Make sure you've set up a merchant account in Play Console
2. Complete the billing settings

### 3. Configure Android Project

Already configured! The billing permission is added in `AndroidManifest.xml`:
```xml
<uses-permission android:name="com.android.vending.BILLING"/>
```

### 4. Test with License Testers

1. In Play Console, go to **Setup** > **License testing**
2. Add test accounts (Gmail addresses)
3. These accounts can make test purchases without being charged

---

## 🔐 Backend Receipt Validation (Advanced)

For production, you should implement server-side receipt validation to prevent fraud.

### Apple Receipt Validation

The basic setup is already in `backend/routes/subscription.js`. To complete it:

1. Make sure your `APPLE_SHARED_SECRET` is set in your backend environment variables
2. The endpoint `/api/subscription/validate/apple` will validate receipts
3. For production, consider using the StoreKit 2 API for better reliability

### Google Play Receipt Validation

To implement Google Play validation:

1. **Set up a Service Account:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new service account
   - Download the JSON key file

2. **Enable Google Play Developer API:**
   - In Google Cloud Console, enable the Google Play Developer API
   - Link it to your Play Console account

3. **Install googleapis package:**
   ```bash
   cd backend
   npm install googleapis
   ```

4. **Update `backend/routes/subscription.js`:**
   ```javascript
   import { google } from 'googleapis';
   
   async function validateGooglePlayPurchase(packageName, productId, purchaseToken) {
     const auth = new google.auth.GoogleAuth({
       keyFile: './path/to/service-account-key.json',
       scopes: ['https://www.googleapis.com/auth/androidpublisher'],
     });
     
     const androidpublisher = google.androidpublisher({
       version: 'v3',
       auth: auth,
     });
     
     const result = await androidpublisher.purchases.subscriptions.get({
       packageName: packageName,
       subscriptionId: productId,
       token: purchaseToken,
     });
     
     return {
       valid: true,
       productId: productId,
       expiryTime: result.data.expiryTimeMillis,
       purchaseState: result.data.paymentState,
     };
   }
   ```

---

## 🔧 Update Product IDs (If Needed)

If you need to change the product IDs, update them in:

1. **Flutter (lib/services/subscription_service.dart):**
   ```dart
   static const String monthlyProductId = 'your_monthly_id';
   static const String yearlyProductId = 'your_yearly_id';
   ```

2. **App Store Connect:** Update the Product IDs for each subscription

3. **Google Play Console:** Update the Product IDs for each subscription

---

## 🧪 Testing Checklist

### Before Submitting to Stores:

- [ ] Test purchasing monthly subscription
- [ ] Test purchasing yearly subscription
- [ ] Test restore purchases functionality
- [ ] Test subscription expiry (use short duration in sandbox)
- [ ] Test free trial flow (if implemented)
- [ ] Test cancellation and resubscription
- [ ] Verify Firestore is updated with subscription status
- [ ] Test with both sandbox/test accounts
- [ ] Test on both iOS and Android (if supporting both)

### Sandbox Testing:

**iOS:**
- Sign out of your real Apple ID
- Install the app (development or TestFlight)
- When prompted, sign in with your sandbox tester account
- Purchases won't charge real money

**Android:**
- Add your test account in Play Console
- Install from internal testing track
- Purchases won't charge real money

---

## 📱 User Flow

1. User completes onboarding → Sign in screen → Paywall
2. On paywall:
   - "Continue with 1-Day Free Trial" → Skip to home screen (free trial)
   - "Subscribe Now" → Initiate real IAP purchase
   - "Restore Purchase" → Restore previous subscription
3. After successful purchase:
   - Receipt is validated (client-side basic check)
   - Subscription status is saved to Firestore
   - User gets premium access
   - AppStateProvider updates `isPremium` flag

---

## 🐛 Troubleshooting

### "Products not found"
- Make sure product IDs match exactly in code and stores
- Ensure subscriptions are approved and active in App Store Connect / Play Console
- Wait a few hours after creating products (they need to propagate)

### "Purchase failed"
- Check sandbox/test account is properly configured
- Verify billing permission is in AndroidManifest (Android)
- Verify IAP capability is enabled in Xcode (iOS)

### "Receipt validation error"
- Ensure APPLE_SHARED_SECRET is set correctly
- Check backend server is accessible
- For sandbox receipts, make sure you're using sandbox URL

### "Restore purchases not working"
- Make sure user is signed in with the same account
- On iOS, sandbox purchases from one account won't restore to another

---

## 📚 Resources

- [Apple In-App Purchase Documentation](https://developer.apple.com/in-app-purchase/)
- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
- [in_app_purchase Flutter Package](https://pub.dev/packages/in_app_purchase)
- [Firebase Firestore](https://firebase.google.com/docs/firestore)

---

## 🚀 Going Live

1. **iOS:**
   - Submit in-app purchases for review in App Store Connect
   - Wait for approval (usually 24-48 hours)
   - Submit app for review with IAP screenshots
   - Make sure subscription is live before app is released

2. **Android:**
   - Publish subscriptions in Play Console
   - Submit app for review
   - Subscriptions go live when app is published

3. **Backend:**
   - Deploy backend with subscription validation endpoints
   - Set APPLE_SHARED_SECRET environment variable
   - Monitor logs for any validation errors

---

**Need help?** Check the Firebase Console to see if subscription data is being saved correctly after purchases.

