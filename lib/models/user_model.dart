import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final int points;
  final List<String> savedRoutes;
  final List<String> recentRoutes;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.points,
    required this.savedRoutes,
    required this.recentRoutes,
    required this.createdAt,
    this.lastLoginAt,
  });

  // Add getter for id (alias for uid)
  String get id => uid;

  // Add copyWith method
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    int? points,
    List<String>? savedRoutes,
    List<String>? recentRoutes,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      points: points ?? this.points,
      savedRoutes: savedRoutes ?? this.savedRoutes,
      recentRoutes: recentRoutes ?? this.recentRoutes,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      points: json['points'] ?? 0,
      savedRoutes: List<String>.from(json['savedRoutes'] ?? []),
      recentRoutes: List<String>.from(json['recentRoutes'] ?? []),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDateTime(json['lastLoginAt']),
    );
  }

  // Helper method to safely parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    } else if (value is int) {
      // Handle milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'points': points,
      'savedRoutes': savedRoutes,
      'recentRoutes': recentRoutes,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
    };
  }
}
