// lib/models/journey_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum JourneyStatus {
  planned,
  started,
  boarding,
  onBoard,
  transferred,
  completed,
  cancelled,
}

enum JourneyType {
  direct,
  transfer,
  walking,
}

class JourneyStep {
  final String id;
  final JourneyType type;
  final String? routeId;
  final String? busId;
  final String? startStopId;
  final String? endStopId;
  final DateTime? scheduledDeparture;
  final DateTime? actualDeparture;
  final DateTime? scheduledArrival;
  final DateTime? actualArrival;
  final Duration? estimatedDuration;
  final Duration? actualDuration;
  final double? distance; // in kilometers
  final double? fare;
  final String? instructions;
  final Map<String, dynamic>? metadata;

  const JourneyStep({
    required this.id,
    required this.type,
    this.routeId,
    this.busId,
    this.startStopId,
    this.endStopId,
    this.scheduledDeparture,
    this.actualDeparture,
    this.scheduledArrival,
    this.actualArrival,
    this.estimatedDuration,
    this.actualDuration,
    this.distance,
    this.fare,
    this.instructions,
    this.metadata,
  });

  factory JourneyStep.fromJson(Map<String, dynamic> json) {
    return JourneyStep(
      id: json['id'] as String,
      type: JourneyType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => JourneyType.direct,
      ),
      routeId: json['routeId'] as String?,
      busId: json['busId'] as String?,
      startStopId: json['startStopId'] as String?,
      endStopId: json['endStopId'] as String?,
      scheduledDeparture: json['scheduledDeparture'] != null
          ? (json['scheduledDeparture'] as Timestamp).toDate()
          : null,
      actualDeparture: json['actualDeparture'] != null
          ? (json['actualDeparture'] as Timestamp).toDate()
          : null,
      scheduledArrival: json['scheduledArrival'] != null
          ? (json['scheduledArrival'] as Timestamp).toDate()
          : null,
      actualArrival: json['actualArrival'] != null
          ? (json['actualArrival'] as Timestamp).toDate()
          : null,
      estimatedDuration: json['estimatedDurationMinutes'] != null
          ? Duration(minutes: json['estimatedDurationMinutes'] as int)
          : null,
      actualDuration: json['actualDurationMinutes'] != null
          ? Duration(minutes: json['actualDurationMinutes'] as int)
          : null,
      distance: (json['distance'] as num?)?.toDouble(),
      fare: (json['fare'] as num?)?.toDouble(),
      instructions: json['instructions'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'routeId': routeId,
      'busId': busId,
      'startStopId': startStopId,
      'endStopId': endStopId,
      'scheduledDeparture': scheduledDeparture != null
          ? Timestamp.fromDate(scheduledDeparture!)
          : null,
      'actualDeparture': actualDeparture != null
          ? Timestamp.fromDate(actualDeparture!)
          : null,
      'scheduledArrival': scheduledArrival != null
          ? Timestamp.fromDate(scheduledArrival!)
          : null,
      'actualArrival': actualArrival != null
          ? Timestamp.fromDate(actualArrival!)
          : null,
      'estimatedDurationMinutes': estimatedDuration?.inMinutes,
      'actualDurationMinutes': actualDuration?.inMinutes,
      'distance': distance,
      'fare': fare,
      'instructions': instructions,
      'metadata': metadata,
    };
  }

  JourneyStep copyWith({
    String? id,
    JourneyType? type,
    String? routeId,
    String? busId,
    String? startStopId,
    String? endStopId,
    DateTime? scheduledDeparture,
    DateTime? actualDeparture,
    DateTime? scheduledArrival,
    DateTime? actualArrival,
    Duration? estimatedDuration,
    Duration? actualDuration,
    double? distance,
    double? fare,
    String? instructions,
    Map<String, dynamic>? metadata,
  }) {
    return JourneyStep(
      id: id ?? this.id,
      type: type ?? this.type,
      routeId: routeId ?? this.routeId,
      busId: busId ?? this.busId,
      startStopId: startStopId ?? this.startStopId,
      endStopId: endStopId ?? this.endStopId,
      scheduledDeparture: scheduledDeparture ?? this.scheduledDeparture,
      actualDeparture: actualDeparture ?? this.actualDeparture,
      scheduledArrival: scheduledArrival ?? this.scheduledArrival,
      actualArrival: actualArrival ?? this.actualArrival,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      distance: distance ?? this.distance,
      fare: fare ?? this.fare,
      instructions: instructions ?? this.instructions,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyStep &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          routeId == other.routeId &&
          busId == other.busId &&
          startStopId == other.startStopId &&
          endStopId == other.endStopId &&
          scheduledDeparture == other.scheduledDeparture &&
          actualDeparture == other.actualDeparture &&
          scheduledArrival == other.scheduledArrival &&
          actualArrival == other.actualArrival &&
          estimatedDuration == other.estimatedDuration &&
          actualDuration == other.actualDuration &&
          distance == other.distance &&
          fare == other.fare &&
          instructions == other.instructions;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      routeId.hashCode ^
      busId.hashCode ^
      startStopId.hashCode ^
      endStopId.hashCode ^
      scheduledDeparture.hashCode ^
      actualDeparture.hashCode ^
      scheduledArrival.hashCode ^
      actualArrival.hashCode ^
      estimatedDuration.hashCode ^
      actualDuration.hashCode ^
      distance.hashCode ^
      fare.hashCode ^
      instructions.hashCode;

  @override
  String toString() => 'JourneyStep(id: $id, type: $type, routeId: $routeId)';

  // Utility getters
  bool get isCompleted => actualArrival != null;
  bool get isStarted => actualDeparture != null;
  bool get isWalking => type == JourneyType.walking;
  bool get isTransit => type == JourneyType.direct || type == JourneyType.transfer;
  
  Duration? get delay {
    if (scheduledDeparture == null || actualDeparture == null) return null;
    final difference = actualDeparture!.difference(scheduledDeparture!);
    return difference.isNegative ? Duration.zero : difference;
  }

  String get typeText {
    switch (type) {
      case JourneyType.direct:
        return 'Direct Bus';
      case JourneyType.transfer:
        return 'Transfer';
      case JourneyType.walking:
        return 'Walking';
    }
  }
}

class Journey {
  final String id;
  final String userId;
  final String? startStopId;
  final String? endStopId;
  final String? startAddress;
  final String? endAddress;
  final GeoPoint? startLocation;
  final GeoPoint? endLocation;
  final DateTime createdAt;
  final DateTime? scheduledDeparture;
  final DateTime? actualDeparture;
  final DateTime? scheduledArrival;
  final DateTime? actualArrival;
  final JourneyStatus status;
  final List<JourneyStep> steps;
  final Duration? totalEstimatedDuration;
  final Duration? totalActualDuration;
  final double? totalDistance;
  final double? totalFare;
  final String? notes;
  final int? rating;
  final String? feedback;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? metadata;

  const Journey({
    required this.id,
    required this.userId,
    this.startStopId,
    this.endStopId,
    this.startAddress,
    this.endAddress,
    this.startLocation,
    this.endLocation,
    required this.createdAt,
    this.scheduledDeparture,
    this.actualDeparture,
    this.scheduledArrival,
    this.actualArrival,
    this.status = JourneyStatus.planned,
    this.steps = const [],
    this.totalEstimatedDuration,
    this.totalActualDuration,
    this.totalDistance,
    this.totalFare,
    this.notes,
    this.rating,
    this.feedback,
    this.preferences,
    this.metadata,
  });

  factory Journey.fromJson(Map<String, dynamic> json, String documentId) {
    return Journey(
      id: documentId,
      userId: json['userId'] as String,
      startStopId: json['startStopId'] as String?,
      endStopId: json['endStopId'] as String?,
      startAddress: json['startAddress'] as String?,
      endAddress: json['endAddress'] as String?,
      startLocation: json['startLocation'] as GeoPoint?,
      endLocation: json['endLocation'] as GeoPoint?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      scheduledDeparture: json['scheduledDeparture'] != null
          ? (json['scheduledDeparture'] as Timestamp).toDate()
          : null,
      actualDeparture: json['actualDeparture'] != null
          ? (json['actualDeparture'] as Timestamp).toDate()
          : null,
      scheduledArrival: json['scheduledArrival'] != null
          ? (json['scheduledArrival'] as Timestamp).toDate()
          : null,
      actualArrival: json['actualArrival'] != null
          ? (json['actualArrival'] as Timestamp).toDate()
          : null,
      status: JourneyStatus.values.firstWhere(
        (status) => status.toString() == json['status'],
        orElse: () => JourneyStatus.planned,
      ),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((step) => JourneyStep.fromJson(step as Map<String, dynamic>))
              .toList() ??
          [],
      totalEstimatedDuration: json['totalEstimatedDurationMinutes'] != null
          ? Duration(minutes: json['totalEstimatedDurationMinutes'] as int)
          : null,
      totalActualDuration: json['totalActualDurationMinutes'] != null
          ? Duration(minutes: json['totalActualDurationMinutes'] as int)
          : null,
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
      totalFare: (json['totalFare'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      rating: json['rating'] as int?,
      feedback: json['feedback'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'startStopId': startStopId,
      'endStopId': endStopId,
      'startAddress': startAddress,
      'endAddress': endAddress,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledDeparture': scheduledDeparture != null
          ? Timestamp.fromDate(scheduledDeparture!)
          : null,
      'actualDeparture': actualDeparture != null
          ? Timestamp.fromDate(actualDeparture!)
          : null,
      'scheduledArrival': scheduledArrival != null
          ? Timestamp.fromDate(scheduledArrival!)
          : null,
      'actualArrival': actualArrival != null
          ? Timestamp.fromDate(actualArrival!)
          : null,
      'status': status.toString(),
      'steps': steps.map((step) => step.toJson()).toList(),
      'totalEstimatedDurationMinutes': totalEstimatedDuration?.inMinutes,
      'totalActualDurationMinutes': totalActualDuration?.inMinutes,
      'totalDistance': totalDistance,
      'totalFare': totalFare,
      'notes': notes,
      'rating': rating,
      'feedback': feedback,
      'preferences': preferences,
      'metadata': metadata,
    };
  }

  Journey copyWith({
    String? id,
    String? userId,
    String? startStopId,
    String? endStopId,
    String? startAddress,
    String? endAddress,
    GeoPoint? startLocation,
    GeoPoint? endLocation,
    DateTime? createdAt,
    DateTime? scheduledDeparture,
    DateTime? actualDeparture,
    DateTime? scheduledArrival,
    DateTime? actualArrival,
    JourneyStatus? status,
    List<JourneyStep>? steps,
    Duration? totalEstimatedDuration,
    Duration? totalActualDuration,
    double? totalDistance,
    double? totalFare,
    String? notes,
    int? rating,
    String? feedback,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
  }) {
    return Journey(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startStopId: startStopId ?? this.startStopId,
      endStopId: endStopId ?? this.endStopId,
      startAddress: startAddress ?? this.startAddress,
      endAddress: endAddress ?? this.endAddress,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      createdAt: createdAt ?? this.createdAt,
      scheduledDeparture: scheduledDeparture ?? this.scheduledDeparture,
      actualDeparture: actualDeparture ?? this.actualDeparture,
      scheduledArrival: scheduledArrival ?? this.scheduledArrival,
      actualArrival: actualArrival ?? this.actualArrival,
      status: status ?? this.status,
      steps: steps ?? this.steps,
      totalEstimatedDuration: totalEstimatedDuration ?? this.totalEstimatedDuration,
      totalActualDuration: totalActualDuration ?? this.totalActualDuration,
      totalDistance: totalDistance ?? this.totalDistance,
      totalFare: totalFare ?? this.totalFare,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Journey && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Journey(id: $id, status: $status, steps: ${steps.length})';

  // Helper methods
  bool get isCompleted => status == JourneyStatus.completed;
  bool get isActive => status == JourneyStatus.started || status == JourneyStatus.boarding || status == JourneyStatus.onBoard;
  bool get isCancelled => status == JourneyStatus.cancelled;
  bool get hasRating => rating != null && rating! > 0;
  
  String get statusText {
    switch (status) {
      case JourneyStatus.planned:
        return 'Planned';
      case JourneyStatus.started:
        return 'Started';
      case JourneyStatus.boarding:
        return 'Boarding';
      case JourneyStatus.onBoard:
        return 'On Board';
      case JourneyStatus.transferred:
        return 'Transferred';
      case JourneyStatus.completed:
        return 'Completed';
      case JourneyStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get transferCount => steps.where((step) => step.type == JourneyType.transfer).length;
  int get walkingStepsCount => steps.where((step) => step.type == JourneyType.walking).length;
  
  List<JourneyStep> get transitSteps => steps.where((step) => step.isTransit).toList();
  List<JourneyStep> get walkingSteps => steps.where((step) => step.isWalking).toList();
  
  JourneyStep? get currentStep {
    if (!isActive) return null;
    return steps.firstWhere(
      (step) => !step.isCompleted,
      orElse: () => steps.isNotEmpty ? steps.last : (throw StateError('No steps available')),
    );
  }

  JourneyStep? get nextStep {
    final current = currentStep;
    if (current == null) return null;
    
    final currentIndex = steps.indexOf(current);
    if (currentIndex == -1 || currentIndex >= steps.length - 1) return null;
    
    return steps[currentIndex + 1];
  }

  double get progress {
    if (steps.isEmpty) return 0.0;
    final completedSteps = steps.where((step) => step.isCompleted).length;
    return completedSteps / steps.length;
  }

  Duration? get remainingDuration {
    if (totalEstimatedDuration == null || actualDeparture == null) return null;
    
    final elapsed = DateTime.now().difference(actualDeparture!);
    final remaining = totalEstimatedDuration! - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration? get totalDelay {
    if (scheduledArrival == null || actualArrival == null) return null;
    final difference = actualArrival!.difference(scheduledArrival!);
    return difference.isNegative ? Duration.zero : difference;
  }

  String get summaryText {
    final buffer = StringBuffer();
    
    if (startAddress != null && endAddress != null) {
      buffer.write('$startAddress → $endAddress');
    } else if (startStopId != null && endStopId != null) {
      buffer.write('$startStopId → $endStopId');
    }
    
    if (totalEstimatedDuration != null) {
      buffer.write(' • ${_formatDuration(totalEstimatedDuration!)}');
    }
    
    if (transferCount > 0) {
      buffer.write(' • $transferCount transfer${transferCount > 1 ? 's' : ''}');
    }
    
    if (totalFare != null) {
      buffer.write(' • \$${totalFare!.toStringAsFixed(2)}');
    }
    
    return buffer.toString();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

// Helper class for journey planning
class JourneyPlan {
  final Journey journey;
  final List<String> routeIds;
  final List<String> busStopIds;
  final DateTime createdAt;
  final bool isFavorite;
  final int useCount;

  const JourneyPlan({
    required this.journey,
    required this.routeIds,
    required this.busStopIds,
    required this.createdAt,
    this.isFavorite = false,
    this.useCount = 0,
  });

  factory JourneyPlan.fromJson(Map<String, dynamic> json, String documentId) {
    return JourneyPlan(
      journey: Journey.fromJson(json['journey'] as Map<String, dynamic>, documentId),
      routeIds: List<String>.from(json['routeIds'] as List),
      busStopIds: List<String>.from(json['busStopIds'] as List),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      useCount: json['useCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journey': journey.toJson(),
      'routeIds': routeIds,
      'busStopIds': busStopIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isFavorite': isFavorite,
      'useCount': useCount,
    };
  }

  JourneyPlan copyWith({
    Journey? journey,
    List<String>? routeIds,
    List<String>? busStopIds,
    DateTime? createdAt,
    bool? isFavorite,
    int? useCount,
  }) {
    return JourneyPlan(
      journey: journey ?? this.journey,
      routeIds: routeIds ?? this.routeIds,
      busStopIds: busStopIds ?? this.busStopIds,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      useCount: useCount ?? this.useCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyPlan &&
          runtimeType == other.runtimeType &&
          journey == other.journey &&
          createdAt == other.createdAt;

  @override
  int get hashCode => journey.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'JourneyPlan(journeyId: ${journey.id}, isFavorite: $isFavorite)';
}

// Extension for journey list operations
extension JourneyListExtensions on List<Journey> {
  List<Journey> filterByStatus(JourneyStatus status) {
    return where((journey) => journey.status == status).toList();
  }

  List<Journey> filterByUser(String userId) {
    return where((journey) => journey.userId == userId).toList();
  }

  List<Journey> filterByDateRange(DateTime start, DateTime end) {
    return where((journey) => 
      journey.createdAt.isAfter(start) && journey.createdAt.isBefore(end)
    ).toList();
  }

  List<Journey> filterCompleted() {
    return where((journey) => journey.isCompleted).toList();
  }

  List<Journey> filterActive() {
    return where((journey) => journey.isActive).toList();
  }

  List<Journey> filterCancelled() {
    return where((journey) => journey.isCancelled).toList();
  }

  List<Journey> filterWithRating() {
    return where((journey) => journey.hasRating).toList();
  }

  List<Journey> sortByDate({bool descending = true}) {
    final sorted = [...this];
    sorted.sort((a, b) => descending 
      ? b.createdAt.compareTo(a.createdAt)
      : a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  List<Journey> sortByRating({bool descending = true}) {
    final sorted = [...this];
    sorted.sort((a, b) {
      final aRating = a.rating ?? 0;
      final bRating = b.rating ?? 0;
      return descending ? bRating.compareTo(aRating) : aRating.compareTo(bRating);
    });
    return sorted;
  }

  double get averageRating {
    final withRating = filterWithRating();
    if (withRating.isEmpty) return 0.0;
    final total = withRating.map((j) => j.rating!).reduce((a, b) => a + b);
    return total / withRating.length;
  }

  Duration get totalTravelTime {
    final durations = where((j) => j.totalActualDuration != null)
        .map((j) => j.totalActualDuration!)
        .toList();
    
    if (durations.isEmpty) return Duration.zero;
    
    int totalMinutes = durations.map((d) => d.inMinutes).reduce((a, b) => a + b);
    return Duration(minutes: totalMinutes);
  }

  double get totalDistance {
    return where((j) => j.totalDistance != null)
        .map((j) => j.totalDistance!)
        .fold(0.0, (sum, distance) => sum + distance);
  }

  double get totalFare {
    return where((j) => j.totalFare != null)
        .map((j) => j.totalFare!)
        .fold(0.0, (sum, fare) => sum + fare);
  }
}