import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Get user authentication state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      if (kDebugMode) {
        print('Attempting to sign in user: $email');
      }

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        // Update last login time
        await _updateLastLoginTime(result.user!.uid);
        
        if (kDebugMode) {
          print('User signed in successfully: ${result.user!.uid}');
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('General Auth Error: $e');
      }
      throw Exception('An unexpected error occurred during sign in');
    }
  }

  /// Sign up with email, password, and name
  Future<UserCredential?> signUpWithEmail(String email, String password, String name) async {
    try {
      if (kDebugMode) {
        print('Attempting to create user: $email');
      }

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(name);
        
        // Create user document in Firestore
        await _createUserDocument(result.user!, name);
        
        if (kDebugMode) {
          print('User created successfully: ${result.user!.uid}');
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('General Auth Error: $e');
      }
      throw Exception('An unexpected error occurred during sign up');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('Signing out user: ${_auth.currentUser?.uid}');
      }

      await _auth.signOut();
      
      if (kDebugMode) {
        print('User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      throw Exception('Failed to sign out');
    }
  }

  /// Get current user model
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      final DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      } else {
        // Create user document if it doesn't exist
        final UserModel newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          points: 0,
          savedRoutes: [],
          recentRoutes: [],
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        await _createUserDocument(firebaseUser, newUser.name);
        return newUser;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current user: $e');
      }
      return null;
    }
  }

  /// Reset password via email
  Future<void> resetPassword(String email) async {
    try {
      if (kDebugMode) {
        print('Sending password reset email to: $email');
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      
      if (kDebugMode) {
        print('Password reset email sent successfully');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending password reset email: $e');
      }
      throw Exception('Failed to send password reset email');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
        if (displayName != null) 'name': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('User profile updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      throw Exception('Failed to update user profile');
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Reload current user data
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user, String name) async {
    final UserModel userModel = UserModel(
    uid: user.uid,
    email: user.email ?? '',
    name: name,
    points: 0,
    savedRoutes: [],
    recentRoutes: [],
    createdAt: DateTime.now(),
    lastLoginAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toJson());
  }

  /// Update last login time
  Future<void> _updateLastLoginTime(String uid) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating last login time: $e');
      }
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password accounts are not enabled.';
        break;
      case 'weak-password':
        message = 'Password should be at least 6 characters long.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email address.';
        break;
      case 'invalid-credential':
        message = 'Invalid credentials. Please check your email and password.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your internet connection.';
        break;
      default:
        message = 'Authentication failed. Please try again.';
        break;
    }
    
    return Exception(message);
  }
}