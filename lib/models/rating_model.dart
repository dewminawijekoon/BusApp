// lib/models/rating_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum RatingType {
  journey,
  bus,
  route,
  driver,
  busStop,
  app,
}

enum RatingCategory {
  punctuality,
  cleanliness,
  comfort,
  safety,
  crowding,
  driverBehavior,
  overallExperience,
}

class RatingCriteria {
  final RatingCategory category;
  final int rating; // 1-5 scale
  final String? comment;

  const RatingCriteria({
    required this.category,
    required this.rating,
    this.comment,
  });

  factory RatingCriteria.fromJson(Map<String, dynamic> json) {
    return RatingCriteria(
      category: RatingCategory.values.firstWhere(
        (category) => category.toString() == json['category'],
        orElse: () => RatingCategory.overallExperience,
      ),
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category.toString(),
      'rating': rating,
      'comment': comment,
    };
  }

  String get categoryText {
    switch (category) {
      case RatingCategory.punctuality:
        return 'Punctuality';
      case RatingCategory.cleanliness:
        return 'Cleanliness';
      case RatingCategory.comfort:
        return 'Comfort';
      case RatingCategory.safety:
        return 'Safety';
      case RatingCategory.crowding:
        return 'Crowding';
      case RatingCategory.driverBehavior:
        return 'Driver Behavior';
      case RatingCategory.overallExperience:
        return 'Overall Experience';
    }
  }

  RatingCriteria copyWith({
    RatingCategory? category,
    int? rating,
    String? comment,
  }) {
    return RatingCriteria(
      category: category ?? this.category,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RatingCriteria &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          rating == other.rating &&
          comment == other.comment;

  @override
  int get hashCode => category.hashCode ^ rating.hashCode ^ comment.hashCode;

  @override
  String toString() =>
      'RatingCriteria(category: $category, rating: $rating, comment: $comment)';
}

class Rating {
  final String id;
  final String userId;
  final RatingType type;
  final int overallRating; // 1-5 scale
  final String? comment;
  final List<RatingCriteria> criteria;
  final DateTime timestamp;
  
  // Context-specific fields
  final String? busId;
  final String? routeId;
  final String? journeyId;
  final String? driverId;
  final String? busStopId;
  
  // Additional metadata
  final bool isAnonymous;
  final List<String>? tags;
  final List<String>? images; // URLs to uploaded images
  final Map<String, dynamic>? metadata;
  
  // Moderation fields
  final bool isApproved;
  final bool isFlagged;
  final DateTime? approvedAt;
  final String? moderatorId;

  const Rating({
    required this.id,
    required this.userId,
    required this.type,
    required this.overallRating,
    this.comment,
    this.criteria = const [],
    required this.timestamp,
    this.busId,
    this.routeId,
    this.journeyId,
    this.driverId,
    this.busStopId,
    this.isAnonymous = false,
    this.tags,
    this.images,
    this.metadata,
    this.isApproved = true,
    this.isFlagged = false,
    this.approvedAt,
    this.moderatorId,
  });

  factory Rating.fromJson(Map<String, dynamic> json, String documentId) {
    return Rating(
      id: documentId,
      userId: json['userId'] as String,
      type: RatingType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => RatingType.journey,
      ),
      overallRating: json['overallRating'] as int,
      comment: json['comment'] as String?,
      criteria: (json['criteria'] as List<dynamic>?)
              ?.map((criterium) => RatingCriteria.fromJson(criterium as Map<String, dynamic>))
              .toList() ??
          [],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      busId: json['busId'] as String?,
      routeId: json['routeId'] as String?,
      journeyId: json['journeyId'] as String?,
      driverId: json['driverId'] as String?,
      busStopId: json['busStopId'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isApproved: json['isApproved'] as bool? ?? true,
      isFlagged: json['isFlagged'] as bool? ?? false,
      approvedAt: json['approvedAt'] != null
          ? (json['approvedAt'] as Timestamp).toDate()
          : null,
      moderatorId: json['moderatorId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.toString(),
      'overallRating': overallRating,
      'comment': comment,
      'criteria': criteria.map((criterium) => criterium.toJson()).toList(),
      'timestamp': Timestamp.fromDate(timestamp),
      'busId': busId,
      'routeId': routeId,
      'journeyId': journeyId,
      'driverId': driverId,
      'busStopId': busStopId,
      'isAnonymous': isAnonymous,
      'tags': tags,
      'images': images,
      'metadata': metadata,
      'isApproved': isApproved,
      'isFlagged': isFlagged,
      'approvedAt': approvedAt != null
          ? Timestamp.fromDate(approvedAt!)
          : null,
      'moderatorId': moderatorId,
    };
  }

  Rating copyWith({
    String? id,
    String? userId,
    RatingType? type,
    int? overallRating,
    String? comment,
    List<RatingCriteria>? criteria,
    DateTime? timestamp,
    String? busId,
    String? routeId,
    String? journeyId,
    String? driverId,
    String? busStopId,
    bool? isAnonymous,
    List<String>? tags,
    List<String>? images,
    Map<String, dynamic>? metadata,
    bool? isApproved,
    bool? isFlagged,
    DateTime? approvedAt,
    String? moderatorId,
  }) {
    return Rating(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      overallRating: overallRating ?? this.overallRating,
      comment: comment ?? this.comment,
      criteria: criteria ?? this.criteria,
      timestamp: timestamp ?? this.timestamp,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      journeyId: journeyId ?? this.journeyId,
      driverId: driverId ?? this.driverId,
      busStopId: busStopId ?? this.busStopId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      metadata: metadata ?? this.metadata,
      isApproved: isApproved ?? this.isApproved,
      isFlagged: isFlagged ?? this.isFlagged,
      approvedAt: approvedAt ?? this.approvedAt,
      moderatorId: moderatorId ?? this.moderatorId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rating &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          type == other.type &&
          overallRating == other.overallRating &&
          comment == other.comment &&
          criteria == other.criteria &&
          timestamp == other.timestamp &&
          busId == other.busId &&
          routeId == other.routeId &&
          journeyId == other.journeyId &&
          driverId == other.driverId &&
          busStopId == other.busStopId &&
          isAnonymous == other.isAnonymous &&
          tags == other.tags &&
          images == other.images &&
          metadata == other.metadata &&
          isApproved == other.isApproved &&
          isFlagged == other.isFlagged &&
          approvedAt == other.approvedAt &&
          moderatorId == other.moderatorId;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      type.hashCode ^
      overallRating.hashCode ^
      comment.hashCode ^
      criteria.hashCode ^
      timestamp.hashCode ^
      busId.hashCode ^
      routeId.hashCode ^
      journeyId.hashCode ^
      driverId.hashCode ^
      busStopId.hashCode ^
      isAnonymous.hashCode ^
      tags.hashCode ^
      images.hashCode ^
      metadata.hashCode ^
      isApproved.hashCode ^
      isFlagged.hashCode ^
      approvedAt.hashCode ^
      moderatorId.hashCode;

  @override
  String toString() {
    return 'Rating('
        'id: $id, '
        'userId: $userId, '
        'type: $type, '
        'overallRating: $overallRating, '
        'comment: $comment, '
        'criteria: $criteria, '
        'timestamp: $timestamp, '
        'busId: $busId, '
        'routeId: $routeId, '
        'journeyId: $journeyId, '
        'driverId: $driverId, '
        'busStopId: $busStopId, '
        'isAnonymous: $isAnonymous, '
        'tags: $tags, '
        'images: $images, '
        'metadata: $metadata, '
        'isApproved: $isApproved, '
        'isFlagged: $isFlagged, '
        'approvedAt: $approvedAt, '
        'moderatorId: $moderatorId'
        ')';
  }

  // Utility methods
  double get averageCriteriaRating {
    if (criteria.isEmpty) return overallRating.toDouble();
    return criteria.map((c) => c.rating).reduce((a, b) => a + b) / criteria.length;
  }

  bool get hasImages => images != null && images!.isNotEmpty;

  bool get hasTags => tags != null && tags!.isNotEmpty;

  bool get hasMetadata => metadata != null && metadata!.isNotEmpty;

  bool get isPendingApproval => !isApproved && !isFlagged;

  String get typeText {
    switch (type) {
      case RatingType.journey:
        return 'Journey';
      case RatingType.bus:
        return 'Bus';
      case RatingType.route:
        return 'Route';
      case RatingType.driver:
        return 'Driver';
      case RatingType.busStop:
        return 'Bus Stop';
      case RatingType.app:
        return 'App';
    }
  }
}