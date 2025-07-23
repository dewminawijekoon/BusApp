import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  static final AuthProvider _instance = AuthProvider._internal();
  factory AuthProvider() => _instance;
  AuthProvider._internal() {
    _init();
  }

  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Initialize auth state listener
  void _init() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  /// Handle authentication state changes
  void _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
    } else {
      _status = AuthStatus.loading;
      _currentUser = await _authService.getCurrentUser();
      _status = AuthStatus.authenticated;
    }
    _clearError();
    notifyListeners();
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    return _executeAuth(() async {
      final result = await _authService.signInWithEmail(email, password);
      return result != null;
    });
  }

  /// Sign up with email, password, and name
  Future<bool> signUp(String email, String password, String name) async {
    return _executeAuth(() async {
      final result = await _authService.signUpWithEmail(email, password, name);
      return result != null;
    });
  }

  /// Sign out current user
  Future<bool> signOut() async {
    return _executeAuth(() async {
      await _authService.signOut();
      return true;
    });
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    return _executeAuth(() async {
      await _authService.resetPassword(email);
      return true;
    });
  }

  /// Update user profile information
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    return _executeAuth(() async {
      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      // Refresh current user data
      _currentUser = await _authService.getCurrentUser();
      return true;
    });
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    if (_status != AuthStatus.authenticated) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authService.reloadUser();
      _currentUser = await _authService.getCurrentUser();
      
      _clearError();
    } catch (e) {
      _setError('Failed to refresh user data: ${e.toString()}');
      if (kDebugMode) {
        print('Error refreshing user: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Execute authentication operation with common error handling
  Future<bool> _executeAuth(Future<bool> Function() operation) async {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      final success = await operation();
      
      if (success) {
        _clearError();
      }
      
      return success;
    } catch (e) {
      _setError(e.toString());
      if (kDebugMode) {
        print('Auth operation error: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message manually (for UI)
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Check if user has completed profile setup
  bool hasCompleteProfile() {
    return _currentUser != null &&
           _currentUser!.name.isNotEmpty &&
           _currentUser!.email.isNotEmpty;
  }

  /// Get user display name or email
  String getUserDisplayName() {
    if (_currentUser == null) return '';
    
    if (_currentUser!.name.isNotEmpty) {
      return _currentUser!.name;
    }
    
    return _currentUser!.email;
  }

  /// Check if this is user's first login
  bool isFirstLogin() {
    if (_currentUser == null) return false;
    
    final createdAt = _currentUser!.createdAt;
    final lastLoginAt = _currentUser!.lastLoginAt;
    
    // If lastLoginAt is within 1 minute of createdAt, consider it first login
    return lastLoginAt!.difference(createdAt).inMinutes <= 1;
  }

  /// Get user points
  int getUserPoints() {
    return _currentUser?.points ?? 0;
  }

  /// Get user total journeys
  //int getTotalJourneys() {
  //  return _currentUser?.totalJourneys ?? 0;
  //}

  /// Reset authentication state (useful for testing)
  void reset() {
    _status = AuthStatus.unknown;
    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up resources if needed
    super.dispose();
  }
}