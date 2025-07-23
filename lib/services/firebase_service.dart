import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/bus_route_model.dart';
import '../models/bus_model.dart';
import '../models/bus_stop_model.dart';
import '../models/journey_model.dart';
import '../models/alert_model.dart';
import '../models/rating_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Stream controllers for real-time updates
  final StreamController<List<Bus>> _busLocationController = StreamController<List<Bus>>.broadcast();
  final StreamController<List<Alert>> _alertsController = StreamController<List<Alert>>.broadcast();

  // Current user cache
  UserModel? _currentUser;
  StreamSubscription? _userSubscription;
  StreamSubscription? _busLocationSubscription;
  StreamSubscription? _alertsSubscription;

  // Getters
  User? get currentFirebaseUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  
  // Streams
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<List<Bus>> get busLocationStream => _busLocationController.stream;
  Stream<List<Alert>> get alertsStream => _alertsController.stream;

  /// Initialize Firebase services
  Future<void> initialize() async {
    try {
      // Initialize Firebase Messaging
      await _initializeMessaging();
      
      // Initialize Crashlytics
      await _initializeCrashlytics();
      
      // Set up auth state listener
      _auth.authStateChanges().listen(_onAuthStateChanged);
      
      debugPrint('Firebase services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase services: $e');
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeMessaging() async {
    try {
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for notifications');
        
        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          await _updateFCMToken(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_updateFCMToken);
      }

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
    } catch (e) {
      debugPrint('Error initializing messaging: $e');
      await _crashlytics.recordError(e, null);
    }
  }

  /// Initialize Firebase Crashlytics
  Future<void> _initializeCrashlytics() async {
    try {
      // Enable crashlytics collection
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      
      // Set custom keys for better debugging
      await _crashlytics.setCustomKey('platform', Platform.operatingSystem);
      await _crashlytics.setCustomKey('app_version', '1.0.0'); // Get from package info
      
    } catch (e) {
      debugPrint('Error initializing crashlytics: $e');
    }
  }

  /// Initialize Firebase Cloud Messaging
  /// Handle authentication state changes
  Future<void> _onAuthStateChanged(User? user) async {
    try {
      if (user != null) {
        // User signed in - load user data
        await _loadCurrentUser();
        _startRealtimeListeners();
      } else {
        // User signed out - cleanup
        _currentUser = null;
        await _stopRealtimeListeners();
      }
    } catch (e) {
      debugPrint('Error handling auth state change: $e');
    }
  }

  /// Load current user data from Firestore
  Future<void> _loadCurrentUser() async {
    if (currentUserId == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromJson({
          'uid': doc.id,
          ...doc.data()!,
        });
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
      await _crashlytics.recordError(e, null);
    }
  }

  // AUTHENTICATION METHODS

  /// Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return _currentUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Create account with email and password
  Future<UserModel?> createUserWithEmail({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user profile in Firestore
        final userModel = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          points: 0,
          savedRoutes: [],
          recentRoutes: [],
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toJson());

        // Send email verification
        await credential.user!.sendEmailVerification();

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Account creation failed: ${e.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _analytics.logEvent(name: 'logout');
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      await _crashlytics.recordError(e, null);
      throw _handleAuthException(e);
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // USER DATA METHODS

  /// Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .update(user.toJson());

      _currentUser = user;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Add points to user account
  Future<void> addUserPoints(int points, String reason) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(currentUserId!);
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final currentPoints = userDoc.data()?['points'] ?? 0;
          transaction.update(userRef, {
            'points': currentPoints + points,
            'lastPointsUpdate': FieldValue.serverTimestamp(),
          });

          // Add points history entry
          final historyRef = _firestore
              .collection('users')
              .doc(currentUserId!)
              .collection('pointsHistory')
              .doc();

          transaction.set(historyRef, {
            'points': points,
            'reason': reason,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      });

      await _analytics.logEvent(
        name: 'points_earned',
        parameters: {'points': points, 'reason': reason},
      );
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to add points: ${e.toString()}');
    }
  }

  // BUS ROUTE METHODS

  /// Get all bus routes
  Future<List<BusRoute>> getBusRoutes() async {
    try {
      final snapshot = await _firestore.collection('busRoutes').get();
      return snapshot.docs
          .map((doc) => BusRoute.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to get bus routes: ${e.toString()}');
    }
  }

  /// Get bus stops
  Future<List<BusStop>> getBusStops() async {
    try {
      final snapshot = await _firestore.collection('busStops').get();
      return snapshot.docs
          .map((doc) => BusStop.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to get bus stops: ${e.toString()}');
    }
  }

  /// Save user route
  Future<void> saveUserRoute(String userId, BusRoute route) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedRoutes')
          .doc(route.id)
          .set(route.toJson());
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to save route: ${e.toString()}');
    }
  }

  /// Get user's saved routes
  Future<List<BusRoute>> getUserSavedRoutes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedRoutes')
          .get();

      return snapshot.docs
          .map((doc) => BusRoute.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to get saved routes: ${e.toString()}');
    }
  }

  /// Remove user route
  Future<void> removeUserRoute(String userId, String routeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedRoutes')
          .doc(routeId)
          .delete();
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to remove route: ${e.toString()}');
    }
  }

  // BUS TRACKING METHODS

  /// Update bus location
  Future<void> updateBusLocation(String busId, GeoPoint location, {
    int? crowdLevel,
    BusStatus? status,
  }) async {
    try {
      final updateData = {
        'location': location,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (crowdLevel != null) {
        updateData['crowdLevel'] = crowdLevel;
      }

      if (status != null) {
        updateData['status'] = status.toString();
      }

      await _firestore
          .collection('buses')
          .doc(busId)
          .update(updateData);

      // Award points to user for contribution
      if (currentUserId != null) {
        await addUserPoints(5, 'Bus location update');
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to update bus location: ${e.toString()}');
    }
  }

  /// Get bus location
  Future<Bus?> getBusLocation(String busId) async {
    try {
      final doc = await _firestore.collection('buses').doc(busId).get();
      
      if (doc.exists) {
        return Bus.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to get bus location: ${e.toString()}');
    }
  }

  /// Start real-time bus location tracking
  void startBusLocationTracking(List<String> busIds) {
    _busLocationSubscription?.cancel();
    
    if (busIds.isEmpty) return;

    _busLocationSubscription = _firestore
        .collection('buses')
        .where(FieldPath.documentId, whereIn: busIds)
        .snapshots()
        .listen(
          (snapshot) {
            final buses = snapshot.docs
                .map((doc) => Bus.fromJson(doc.data(), doc.id))
                .toList();
            
            _busLocationController.add(buses);
          },
          onError: (error) {
            debugPrint('Error in bus location stream: $error');
            _crashlytics.recordError(error, null);
          },
        );
  }

  // JOURNEY METHODS

  /// Save user journey
  Future<void> saveUserJourney(Journey journey) async {
    try {
      await _firestore
          .collection('users')
          .doc(journey.userId)
          .collection('journeys')
          .doc(journey.id)
          .set(journey.toJson());
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to save journey: ${e.toString()}');
    }
  }

  /// Get user journeys
  Future<List<Journey>> getUserJourneys(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('journeys')
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Journey.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to get user journeys: ${e.toString()}');
    }
  }

  // ALERT METHODS

  /// Create alert for user
  Future<void> createAlert(Alert alert) async {
    try {
      await _firestore
          .collection('alerts')
          .doc(alert.id)
          .set(alert.toJson());
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to create alert: ${e.toString()}');
    }
  }

  /// Start real-time alerts listening
  void _startRealtimeListeners() {
    if (currentUserId == null) return;

    // Listen to user alerts
    _alertsSubscription?.cancel();
    _alertsSubscription = _firestore
        .collection('alerts')
        .where('userId', isEqualTo: currentUserId!)
        .where('isRead', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final alerts = snapshot.docs
                .map((doc) => Alert.fromJson(doc.data(), doc.id))
                .toList();
            
            _alertsController.add(alerts);
          },
          onError: (error) {
            debugPrint('Error in alerts stream: $error');
            _crashlytics.recordError(error, null);
          },
        );
  }

  /// Stop all real-time listeners
  Future<void> _stopRealtimeListeners() async {
    await _userSubscription?.cancel();
    await _busLocationSubscription?.cancel();
    await _alertsSubscription?.cancel();
    _userSubscription = null;
    _busLocationSubscription = null;
    _alertsSubscription = null;
  }

  // RATING METHODS

  /// Submit route rating
  Future<void> submitRating(Rating rating) async {
    try {
      await _firestore
          .collection('ratings')
          .doc(rating.id)
          .set(rating.toJson());

      // Award points for rating
      if (currentUserId != null) {
        await addUserPoints(10, 'Route rating');
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
      throw Exception('Failed to submit rating: ${e.toString()}');
    }
  }

  // ANALYTICS AND LOGGING

  /// Log custom event
  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters?.cast<String, Object>(),
      );
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  /// Set user properties for analytics
  Future<void> setUserProperties(Map<String, String> properties) async {
    try {
      for (final entry in properties.entries) {
        await _analytics.setUserProperty(
          name: entry.key,
          value: entry.value,
        );
      }
    } catch (e) {
      debugPrint('Error setting user properties: $e');
    }
  }

  // MESSAGING METHODS

  /// Update FCM token in user document
  Future<void> _updateFCMToken(String token) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .update({
            'fcmTokens': FieldValue.arrayUnion([token]),
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      await _crashlytics.recordError(e, null);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    
    // Create local alert for display
    if (message.data.isNotEmpty) {
      final alert = Alert(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUserId ?? '',
        title: message.notification?.title ?? 'Notification',
        message: message.notification?.body ?? '',
        type: AlertType.systemAlert,
        timestamp: DateTime.now(),
        isRead: false,
        priority: AlertPriority.medium,
        metadata: message.data,
      );

      // Add to alerts stream
      final currentAlerts = _alertsController.hasListener 
          ? <Alert>[] 
          : <Alert>[];
      currentAlerts.insert(0, alert);
      _alertsController.add(currentAlerts);
    }
  }

  /// Handle authentication exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  /// Dispose resources
  void dispose() {
    _busLocationController.close();
    _alertsController.close();
    _stopRealtimeListeners();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Received background message: ${message.messageId}');
  
  // Handle background message processing here
  // This could include updating local notifications, 
  // updating app badge, etc.
}