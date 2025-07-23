// lib/models/alert_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType {
  busDelay,
  busArrival,
  routeChange,
  serviceDisruption,
  weatherAlert,
  maintenanceAlert,
  crowdingAlert,
  safetyAlert,
  promotionalAlert,
  systemAlert,
}

enum AlertPriority {
  low,
  medium,
  high,
  critical,
}

enum AlertCategory {
  realTime,
  scheduled,
  promotional,
  emergency,
  system,
}

class Alert {
  final String id;
  final String userId;
  final String title;
  final String message;
  final AlertType type;
  final AlertPriority priority;
  final AlertCategory category;
  final bool isRead;
  final bool isActive;
  final DateTime timestamp;
  final DateTime? expiresAt;
  final String? routeId;
  final String? busId;
  final String? stopId;
  final String? journeyId;
  final Map<String, dynamic>? actionData; // For clickable actions
  final String? imageUrl;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  const Alert({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = AlertPriority.medium,
    this.category = AlertCategory.realTime,
    this.isRead = false,
    this.isActive = true,
    required this.timestamp,
    this.expiresAt,
    this.routeId,
    this.busId,
    this.stopId,
    this.journeyId,
    this.actionData,
    this.imageUrl,
    this.tags,
    this.metadata,
  });

  factory Alert.fromJson(Map<String, dynamic> json, String documentId) {
    return Alert(
      id: documentId,
      userId: json['userId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: AlertType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => AlertType.systemAlert,
      ),
      priority: AlertPriority.values.firstWhere(
        (priority) => priority.toString() == json['priority'],
        orElse: () => AlertPriority.medium,
      ),
      category: AlertCategory.values.firstWhere(
        (category) => category.toString() == json['category'],
        orElse: () => AlertCategory.realTime,
      ),
      isRead: json['isRead'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] as Timestamp).toDate()
          : null,
      routeId: json['routeId'] as String?,
      busId: json['busId'] as String?,
      stopId: json['stopId'] as String?,
      journeyId: json['journeyId'] as String?,
      actionData: json['actionData'] as Map<String, dynamic>?,
      imageUrl: json['imageUrl'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString(),
      'priority': priority.toString(),
      'category': category.toString(),
      'isRead': isRead,
      'isActive': isActive,
      'timestamp': Timestamp.fromDate(timestamp),
      'expiresAt': expiresAt != null
          ? Timestamp.fromDate(expiresAt!)
          : null,
      'routeId': routeId,
      'busId': busId,
      'stopId': stopId,
      'journeyId': journeyId,
      'actionData': actionData,
      'imageUrl': imageUrl,
      'tags': tags,
      'metadata': metadata,
    };
  }

  Alert copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    AlertType? type,
    AlertPriority? priority,
    AlertCategory? category,
    bool? isRead,
    bool? isActive,
    DateTime? timestamp,
    DateTime? expiresAt,
    String? routeId,
    String? busId,
    String? stopId,
    String? journeyId,
    Map<String, dynamic>? actionData,
    String? imageUrl,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return Alert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      isActive: isActive ?? this.isActive,
      timestamp: timestamp ?? this.timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
      routeId: routeId ?? this.routeId,
      busId: busId ?? this.busId,
      stopId: stopId ?? this.stopId,
      journeyId: journeyId ?? this.journeyId,
      actionData: actionData ?? this.actionData,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get hasAction => actionData != null && actionData!.isNotEmpty;

  String get typeText {
    switch (type) {
      case AlertType.busDelay:
        return 'Bus Delay';
      case AlertType.busArrival:
        return 'Bus Arrival';
      case AlertType.routeChange:
        return 'Route Change';
      case AlertType.serviceDisruption:
        return 'Service Disruption';
      case AlertType.weatherAlert:
        return 'Weather Alert';
      case AlertType.maintenanceAlert:
        return 'Maintenance Alert';
      case AlertType.crowdingAlert:
        return 'Crowding Alert';
      case AlertType.safetyAlert:
        return 'Safety Alert';
      case AlertType.promotionalAlert:
        return 'Promotion';
      case AlertType.systemAlert:
        return 'System Alert';
    }
  }

  String get priorityText {
    switch (priority) {
      case AlertPriority.low:
        return 'Low';
      case AlertPriority.medium:
        return 'Medium';
      case AlertPriority.high:
        return 'High';
      case AlertPriority.critical:
        return 'Critical';
    }
  }

  String get categoryText {
    switch (category) {
      case AlertCategory.realTime:
        return 'Real-time';
      case AlertCategory.scheduled:
        return 'Scheduled';
      case AlertCategory.promotional:
        return 'Promotional';
      case AlertCategory.emergency:
        return 'Emergency';
      case AlertCategory.system:
        return 'System';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  bool hasTag(String tag) => tags?.contains(tag) ?? false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Alert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Alert(id: $id, type: $type, title: $title)';
}

// Helper class for creating specific alert types
class AlertFactory {
  static Alert busArrival({
    required String userId,
    required String busId,
    required String routeId,
    required String stopId,
    required int estimatedMinutes,
    String? journeyId,
  }) {
    return Alert(
      id: '',
      userId: userId,
      title: 'Bus Arriving Soon',
      message: 'Your bus will arrive in approximately $estimatedMinutes minutes',
      type: AlertType.busArrival,
      priority: AlertPriority.high,
      category: AlertCategory.realTime,
      timestamp: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: estimatedMinutes + 5)),
      routeId: routeId,
      busId: busId,
      stopId: stopId,
      journeyId: journeyId,
      actionData: {
        'action': 'track_bus',
        'busId': busId,
        'routeId': routeId,
      },
    );
  }

  static Alert busDelay({
    required String userId,
    required String busId,
    required String routeId,
    required int delayMinutes,
    required String reason,
    String? journeyId,
  }) {
    return Alert(
      id: '',
      userId: userId,
      title: 'Bus Delayed',
      message: 'Your bus is delayed by $delayMinutes minutes. Reason: $reason',
      type: AlertType.busDelay,
      priority: AlertPriority.medium,
      category: AlertCategory.realTime,
      timestamp: DateTime.now(),
      routeId: routeId,
      busId: busId,
      journeyId: journeyId,
      actionData: {
        'action': 'find_alternative',
        'routeId': routeId,
      },
    );
  }

  static Alert serviceDisruption({
    required String userId,
    required String routeId,
    required String reason,
    required DateTime startsAt,
    required DateTime endsAt,
  }) {
    return Alert(
      id: '',
      userId: userId,
      title: 'Service Disruption',
      message: 'Service disruption on your route: $reason',
      type: AlertType.serviceDisruption,
      priority: AlertPriority.high,
      category: AlertCategory.scheduled,
      timestamp: DateTime.now(),
      expiresAt: endsAt,
      routeId: routeId,
      metadata: {
        'startsAt': startsAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
        'reason': reason,
      },
      actionData: {
        'action': 'find_alternative',
        'routeId': routeId,
      },
    );
  }

  static Alert crowdingAlert({
    required String userId,
    required String busId,
    required String routeId,
    required String crowdLevel,
    String? journeyId,
  }) {
    return Alert(
      id: '',
      userId: userId,
      title: 'High Crowd Level',
      message: 'The bus you\'re tracking has $crowdLevel crowd levels',
      type: AlertType.crowdingAlert,
      priority: AlertPriority.low,
      category: AlertCategory.realTime,
      timestamp: DateTime.now(),
      routeId: routeId,
      busId: busId,
      journeyId: journeyId,
      actionData: {
        'action': 'find_alternative',
        'routeId': routeId,
      },
    );
  }

  static Alert weatherAlert({
    required String userId,
    required String weatherCondition,
    required String impact,
    required List<String> affectedRoutes,
  }) {
    return Alert(
      id: '',
      userId: userId,
      title: 'Weather Alert',
      message: '$weatherCondition expected. $impact',
      type: AlertType.weatherAlert,
      priority: AlertPriority.medium,
      category: AlertCategory.scheduled,
      timestamp: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(hours: 12)),
      metadata: {
        'weatherCondition': weatherCondition,
        'affectedRoutes': affectedRoutes,
        'impact': impact,
      },
      tags: ['weather', ...affectedRoutes],
    );
  }
}

// Extension for alert list operations
extension AlertListExtensions on List<Alert> {
  List<Alert> filterUnread() {
    return where((alert) => !alert.isRead).toList();
  }

  List<Alert> filterByType(AlertType type) {
    return where((alert) => alert.type == type).toList();
  }

  List<Alert> filterByPriority(AlertPriority priority) {
    return where((alert) => alert.priority == priority).toList();
  }

  List<Alert> filterByCategory(AlertCategory category) {
    return where((alert) => alert.category == category).toList();
  }

  List<Alert> filterActive() {
    return where((alert) => alert.isActive && !alert.isExpired).toList();
  }

  List<Alert> filterByRoute(String routeId) {
    return where((alert) => alert.routeId == routeId).toList();
  }

  List<Alert> filterByJourney(String journeyId) {
    return where((alert) => alert.journeyId == journeyId).toList();
  }

  List<Alert> sortByPriority({bool highFirst = true}) {
    final sorted = [...this];
    sorted.sort((a, b) {
      final priorityOrder = {
        AlertPriority.critical: 4,
        AlertPriority.high: 3,
        AlertPriority.medium: 2,
        AlertPriority.low: 1,
      };
      final aValue = priorityOrder[a.priority] ?? 0;
      final bValue = priorityOrder[b.priority] ?? 0;
      return highFirst ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
    });
    return sorted;
  }

  List<Alert> sortByDate({bool newestFirst = true}) {
    final sorted = [...this];
    sorted.sort((a, b) => newestFirst
        ? b.timestamp.compareTo(a.timestamp)
        : a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  int get unreadCount => where((alert) => !alert.isRead).length;
  
  List<Alert> get critical => 
    where((alert) => alert.priority == AlertPriority.critical).toList();
  
  List<Alert> get realTime => 
    where((alert) => alert.category == AlertCategory.realTime).toList();
}