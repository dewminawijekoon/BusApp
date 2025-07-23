import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/bus_route_model.dart';

enum UserLoadingState {
  idle,
  loading,
  updating,
  error,
}

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  UserModel? _currentUser;
  List<BusRoute> _savedRoutes = [];
  List<PointTransaction> _pointsHistory = [];
  List<Reward> _availableRewards = [];
  UserLoadingState _loadingState = UserLoadingState.idle;
  String? _errorMessage;
  bool _isInitialized = false;

  // Constructor to listen to auth state changes
  UserProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is signed in, initialize their data
        initialize();
      } else {
        // User is signed out, clear data
        _clearUserData();
      }
    });
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  List<BusRoute> get savedRoutes => List.unmodifiable(_savedRoutes);
  List<PointTransaction> get pointsHistory => List.unmodifiable(_pointsHistory);
  List<Reward> get availableRewards => List.unmodifiable(_availableRewards);
  UserLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get hasUser => _currentUser != null;
  int get totalPoints => _currentUser?.points ?? 0;

  // Initialize user provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoadingState(UserLoadingState.loading);
    
    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await loadUserProfile(firebaseUser.uid);
        await _loadUserData();
      }
      _isInitialized = true;
      _setLoadingState(UserLoadingState.idle);
    } catch (e) {
      _setError('Failed to initialize user data: ${e.toString()}');
      debugPrint('UserProvider initialization error: $e');
    }
  }

  // Load user profile from Firestore
  Future<void> loadUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        _currentUser = UserModel.fromJson({
          'uid': userId,
          ...userDoc.data()!,
        });
        notifyListeners();
      } else {
        // Create new user profile if doesn't exist
        await createUserProfile(userId);
      }
    } catch (e) {
      _setError('Failed to load user profile: ${e.toString()}');
      throw e;
    }
  }

  // Create new user profile
  Future<void> createUserProfile(String userId, {
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final User? firebaseUser = _auth.currentUser;
      
      final newUser = UserModel(
        uid: userId,
        name: name ?? firebaseUser?.displayName ?? 'User',
        email: email ?? firebaseUser?.email ?? '',
        points: 0,
        savedRoutes: [],
        recentRoutes: [],
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(userId).set(newUser.toJson());
      _currentUser = newUser;
      
      // Award welcome points
      await addPoints(100, 'Welcome bonus');
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to create user profile: ${e.toString()}');
      throw e;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    if (_currentUser == null) return;

    _setLoadingState(UserLoadingState.updating);
    
    try {
      await _firestore.collection('users').doc(updatedUser.uid).update(
        updatedUser.toJson()..remove('uid'),
      );
      
      _currentUser = updatedUser;
      _setLoadingState(UserLoadingState.idle);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
    }
  }

  // Update specific profile fields
  Future<void> updateProfileField(String field, dynamic value) async {
    if (_currentUser == null) return;

    try {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        field: value,
      });

      // Update local user model
      switch (field) {
        case 'name':
          _currentUser = _currentUser!.copyWith(name: value as String);
          break;
        case 'email':
          _currentUser = _currentUser!.copyWith(email: value as String);
          break;
        // Remove unsupported fields for now
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to update $field: ${e.toString()}');
    }
  }

  // Load all user-related data
  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    await Future.wait([
      loadSavedRoutes(),
      loadPointsHistory(),
      loadAvailableRewards(),
    ]);
  }

  // Saved Routes Management
  Future<void> loadSavedRoutes() async {
    if (_currentUser == null) return;

    try {
      final savedRoutesQuery = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('savedRoutes')
          .orderBy('savedAt', descending: true)
          .get();

      _savedRoutes = savedRoutesQuery.docs
          .map((doc) => BusRoute.fromJson(doc.data(), doc.id))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load saved routes: $e');
    }
  }

  // Save a new route
  Future<void> saveRoute(BusRoute route) async {
    if (_currentUser == null) return;

    try {
      // Check if route already saved
      final existingRoute = _savedRoutes.firstWhere(
        (savedRoute) => savedRoute.id == route.id,
        orElse: () => BusRoute(
          id: '',
          routeName: '',
          routeNumber: '',
          stops: [],
          baseFare: 0.0,
          estimatedDuration: Duration.zero,
          operatorId: '',
          createdAt: DateTime.now(),
        ),
      );

      if (existingRoute.id.isNotEmpty) {
        _setError('Route already saved');
        return;
      }

      final routeData = route.toJson()
        ..['savedAt'] = DateTime.now().toIso8601String();

      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('savedRoutes')
          .doc(route.id)
          .set(routeData);

      _savedRoutes.insert(0, route);
      
      // Award points for saving route
      await addPoints(10, 'Saved route');
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to save route: ${e.toString()}');
    }
  }

  // Delete saved route
  Future<void> deleteSavedRoute(String routeId) async {
    if (_currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('savedRoutes')
          .doc(routeId)
          .delete();

      _savedRoutes.removeWhere((route) => route.id == routeId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete saved route: ${e.toString()}');
    }
  }

  // Points System
  Future<void> loadPointsHistory() async {
    if (_currentUser == null) return;

    try {
      final pointsQuery = await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('pointsHistory')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _pointsHistory = pointsQuery.docs
          .map((doc) => PointTransaction.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load points history: $e');
    }
  }

  // Add points to user account
  Future<void> addPoints(int points, String reason) async {
    if (_currentUser == null || points <= 0) return;

    try {
      final batch = _firestore.batch();
      
      // Create points transaction
      final transactionRef = _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('pointsHistory')
          .doc();

      final transaction = PointTransaction(
        id: transactionRef.id,
        points: points,
        reason: reason,
        timestamp: DateTime.now(),
        type: PointTransactionType.earned,
      );

      batch.set(transactionRef, transaction.toJson());

      // Update user total points
      final newTotalPoints = _currentUser!.points + points;

      batch.update(_firestore.collection('users').doc(_currentUser!.uid), {
        'points': newTotalPoints,
      });

      await batch.commit();

      // Update local state
      _currentUser = _currentUser!.copyWith(
        points: newTotalPoints,
      );
      
      _pointsHistory.insert(0, transaction);
      notifyListeners();

      // Level system removed for now
    } catch (e) {
      _setError('Failed to add points: ${e.toString()}');
    }
  }

  // Spend points
  Future<bool> spendPoints(int points, String reason) async {
    if (_currentUser == null || points <= 0 || _currentUser!.points < points) {
      return false;
    }

    try {
      final batch = _firestore.batch();
      
      // Create points transaction
      final transactionRef = _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('pointsHistory')
          .doc();

      final transaction = PointTransaction(
        id: transactionRef.id,
        points: -points,
        reason: reason,
        timestamp: DateTime.now(),
        type: PointTransactionType.spent,
      );

      batch.set(transactionRef, transaction.toJson());

      // Update user total points
      final newTotalPoints = _currentUser!.points - points;
      batch.update(_firestore.collection('users').doc(_currentUser!.uid), {
        'points': newTotalPoints,
      });

      await batch.commit();

      // Update local state
      _currentUser = _currentUser!.copyWith(points: newTotalPoints);
      _pointsHistory.insert(0, transaction);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to spend points: ${e.toString()}');
      return false;
    }
  }

  // Rewards System
  Future<void> loadAvailableRewards() async {
    try {
      final rewardsQuery = await _firestore
          .collection('rewards')
          .where('isActive', isEqualTo: true)
          .orderBy('pointsCost')
          .get();

      _availableRewards = rewardsQuery.docs
          .map((doc) => Reward.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load rewards: $e');
    }
  }

  // Claim a reward
  Future<bool> claimReward(String rewardId) async {
    if (_currentUser == null) return false;

    final reward = _availableRewards.firstWhere(
      (r) => r.id == rewardId,
      orElse: () => Reward(
        id: '',
        title: '',
        description: '',
        pointsCost: 0,
        isActive: false,
      ),
    );

    if (reward.id.isEmpty || _currentUser!.points < reward.pointsCost) {
      return false;
    }

    final success = await spendPoints(reward.pointsCost, 'Claimed: ${reward.title}');
    
    if (success) {
      // Record reward claim
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('claimedRewards')
          .add({
            'rewardId': rewardId,
            'claimedAt': DateTime.now().toIso8601String(),
            'pointsSpent': reward.pointsCost,
          });
    }

    return success;
  }

  // Journey completion tracking
  Future<void> completeJourney(String journeyId, {
    int? rating,
    String? feedback,
  }) async {
    if (_currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('journeys')
          .doc(journeyId)
          .update({
            'completedAt': DateTime.now().toIso8601String(),
            'rating': rating,
            'feedback': feedback,
            'status': 'completed',
          });

      // Award completion points
      await addPoints(25, 'Journey completed');
      
      // Bonus points for rating
      if (rating != null) {
        await addPoints(5, 'Journey rated');
      }
    } catch (e) {
      debugPrint('Failed to complete journey: $e');
    }
  }

  // Utility methods
  void _setLoadingState(UserLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _loadingState = UserLoadingState.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _loadingState = UserLoadingState.idle;
    notifyListeners();
  }

  // Clear all user data (for logout)
  void clearUserData() {
    _currentUser = null;
    _savedRoutes.clear();
    _pointsHistory.clear();
    _availableRewards.clear();
    _loadingState = UserLoadingState.idle;
    _errorMessage = null;
    _isInitialized = false;
    notifyListeners();
  }

  // Private helper to clear user data (called from auth state listener)
  void _clearUserData() {
    clearUserData();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Supporting models for user provider
class PointTransaction {
  final String id;
  final int points;
  final String reason;
  final DateTime timestamp;
  final PointTransactionType type;

  PointTransaction({
    required this.id,
    required this.points,
    required this.reason,
    required this.timestamp,
    required this.type,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'] ?? '',
      points: json['points'] ?? 0,
      reason: json['reason'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      type: PointTransactionType.values.firstWhere(
        (e) => e.toString() == 'PointTransactionType.${json['type']}',
        orElse: () => PointTransactionType.earned,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
    };
  }
}

enum PointTransactionType {
  earned,
  spent,
  bonus,
  penalty,
}

class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final bool isActive;
  final String? imageUrl;
  final DateTime? expiryDate;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.isActive,
    this.imageUrl,
    this.expiryDate,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      pointsCost: json['pointsCost'] ?? 0,
      isActive: json['isActive'] ?? false,
      imageUrl: json['imageUrl'],
      expiryDate: json['expiryDate'] != null 
          ? DateTime.tryParse(json['expiryDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }
}