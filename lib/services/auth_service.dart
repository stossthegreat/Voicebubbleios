import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;
import 'analytics_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ✅ FIX: Add serverClientId for Android Google Sign-In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: '343007612090-8t1vprl8l7tm5i8ekg0vag305sjho8m5.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get user creation date (for trial tracking)
  Future<DateTime?> getUserCreationDate() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['createdAt'] != null) {
          return (data['createdAt'] as Timestamp).toDate();
        }
      }
      // Fallback to Firebase Auth creation time
      return user.metadata.creationTime;
    } catch (e) {
      debugPrint('Error getting user creation date: $e');
      return user.metadata.creationTime;
    }
  }

  // Check if user is in trial period (1 day)
  Future<bool> isInTrialPeriod() async {
    final creationDate = await getUserCreationDate();
    if (creationDate == null) return false;

    final now = DateTime.now();
    final difference = now.difference(creationDate);
    return difference.inDays < 1; // 1-day trial
  }

  // Get remaining trial hours
  Future<int> getRemainingTrialHours() async {
    final creationDate = await getUserCreationDate();
    if (creationDate == null) return 0;

    final trialEnd = creationDate.add(const Duration(days: 1));
    final now = DateTime.now();
    
    if (now.isAfter(trialEnd)) return 0;
    
    final remaining = trialEnd.difference(now);
    return remaining.inHours;
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Create user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);

      // Create user document in Firestore
      await _createUserDocument(
        uid: userCredential.user!.uid,
        email: email,
        fullName: fullName,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign up error: $e');
      throw Exception('Failed to sign up. Please try again.');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Track user for analytics
      AnalyticsService().setUserId(userCredential.user?.uid);
      AnalyticsService().setUserProperty(name: 'sign_in_method', value: 'email');

      // Ensure user document exists
      await _ensureUserDocument(userCredential.user!);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw Exception('Failed to sign in. Please try again.');
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Starting Google Sign-In flow...');
      
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('⚪ User cancelled Google Sign-In');
        return null;
      }

      debugPrint('🟢 Google user obtained: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      debugPrint('🟢 Google auth tokens obtained');
      debugPrint('  - Access token: ${googleAuth.accessToken?.substring(0, 20)}...');
      debugPrint('  - ID token: ${googleAuth.idToken?.substring(0, 20)}...');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🟢 Firebase credential created, attempting sign-in...');

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Track user for analytics
      AnalyticsService().setUserId(userCredential.user?.uid);
      AnalyticsService().setUserProperty(name: 'sign_in_method', value: 'google');

      debugPrint('🟢 Firebase sign-in successful: ${userCredential.user?.email}');

      // Create/update user document (don't wait, do it in background)
      _createUserDocument(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email!,
        fullName: userCredential.user!.displayName ?? 'User',
      ).catchError((e) {
        debugPrint('⚠️ User document creation failed (non-critical): $e');
      });

      debugPrint('🟢 Sign-in complete, returning user credential');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('🔴 Firebase Auth Exception:');
      debugPrint('  - Code: ${e.code}');
      debugPrint('  - Message: ${e.message}');
      debugPrint('  - Plugin: ${e.plugin}');
      throw Exception('Firebase Error (${e.code}): ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('🔴 Unexpected error in Google Sign-In:');
      debugPrint('  - Error: $e');
      debugPrint('  - Type: ${e.runtimeType}');
      debugPrint('  - Stack trace: $stackTrace');
      throw Exception('Sign-in failed: $e');
    }
  }

  // Sign in with Apple (iOS only)
  Future<UserCredential?> signInWithApple() async {
    try {
      debugPrint('🍎 Starting Apple Sign-In flow...');

      // Request Apple credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint('🍎 Apple credential obtained');

      // Create OAuth credential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      debugPrint('🍎 OAuth credential created, signing in to Firebase...');

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Track for analytics
      AnalyticsService().setUserId(userCredential.user?.uid);
      AnalyticsService().setUserProperty(name: 'sign_in_method', value: 'apple');

      debugPrint('🍎 Firebase sign-in successful: ${userCredential.user?.email}');

      // Get display name from Apple (only provided on first sign-in)
      String? fullName;
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        fullName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
      }

      // Create/update user document
      _createUserDocument(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email ?? appleCredential.email ?? 'unknown@apple.com',
        fullName: fullName ?? userCredential.user!.displayName ?? 'User',
      ).catchError((e) {
        debugPrint('⚠️ User document creation failed (non-critical): $e');
      });

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('🍎 Apple Sign-In Authorization Error: ${e.code} - ${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) {
        return null; // User cancelled
      }
      throw Exception('Apple Sign-In failed: ${e.message}');
    } on FirebaseAuthException catch (e) {
      debugPrint('🍎 Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception('Firebase Error: ${e.message}');
    } catch (e) {
      debugPrint('🍎 Unexpected error: $e');
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear user from analytics
      AnalyticsService().setUserId(null);

      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user signed in');

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user from Firebase Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      debugPrint('Delete account error: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        throw Exception('Please sign in again before deleting your account.');
      }
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Delete account error: $e');
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String fullName,
  }) async {
    try {
      debugPrint('📝 Creating/updating user document for: $email');
      final userDoc = _firestore.collection('users').doc(uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        debugPrint('📝 Creating NEW user document');
        // Create new user document
        await userDoc.set({
          'uid': uid,
          'email': email,
          'fullName': fullName,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
          'isPremium': false,
          'trialStartDate': FieldValue.serverTimestamp(),
          'speechToTextMinutesUsed': 0.0,
        });
        debugPrint('✅ User document created successfully');
      } else {
        debugPrint('📝 Updating existing user document');
        // Update last sign in
        await userDoc.update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ User document updated successfully');
      }
    } catch (e) {
      debugPrint('⚠️ Error creating user document: $e');
      debugPrint('⚠️ This is non-critical - user is still authenticated');
      // Don't throw - user is still authenticated
    }
  }

  // Ensure user document exists
  Future<void> _ensureUserDocument(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await _createUserDocument(
          uid: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? 'User',
        );
      } else {
        // Update last sign in
        await userDoc.update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error ensuring user document: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Reset password error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Reset password error: $e');
      throw Exception('Failed to send reset email. Please try again.');
    }
  }
}
