// lib/models/bus_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum BusStatus {
  active,
  inactive,
  maintenance,
  outOfService,
}

enum CrowdLevel {
  empty,
  low,
  medium,
  high,
  full,
}

class BusLocation {
  final double latitude;
  final double longitude;
  final double bearing;
  final DateTime timestamp;

  const BusLocation({
    required this.latitude,
    required this.longitude,
    required this.bearing,
    required this.timestamp,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    return BusLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'bearing': bearing,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  GeoPoint get geoPoint => GeoPoint(latitude, longitude);

  BusLocation copyWith({
    double? latitude,
    double? longitude,
    double? bearing,
    DateTime? timestamp,
  }) {
    return BusLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bearing: bearing ?? this.bearing,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class Bus {
  final String id;
  final String routeId;
  final String plateNumber;
  final String driverName;
  final BusLocation? currentLocation;
  final int capacity;
  final int currentCrowd;
  final CrowdLevel crowdLevel;
  final BusStatus status;
  final double speed; // km/h
  final String? nextStopId;
  final DateTime? estimatedArrival;
  final DateTime lastUpdated;
  final Map<String, dynamic>? metadata;

  const Bus({
    required this.id,
    required this.routeId,
    required this.plateNumber,
    required this.driverName,
    this.currentLocation,
    required this.capacity,
    this.currentCrowd = 0,
    this.crowdLevel = CrowdLevel.empty,
    this.status = BusStatus.active,
    this.speed = 0.0,
    this.nextStopId,
    this.estimatedArrival,
    required this.lastUpdated,
    this.metadata,
  });

  factory Bus.fromJson(Map<String, dynamic> json, String documentId) {
    return Bus(
      id: documentId,
      routeId: json['routeId'] as String,
      plateNumber: json['plateNumber'] as String,
      driverName: json['driverName'] as String,
      currentLocation: json['currentLocation'] != null
          ? BusLocation.fromJson(json['currentLocation'] as Map<String, dynamic>)
          : null,
      capacity: json['capacity'] as int,
      currentCrowd: json['currentCrowd'] as int? ?? 0,
      crowdLevel: CrowdLevel.values.firstWhere(
        (level) => level.toString() == json['crowdLevel'],
        orElse: () => CrowdLevel.empty,
      ),
      status: BusStatus.values.firstWhere(
        (status) => status.toString() == json['status'],
        orElse: () => BusStatus.active,
      ),
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      nextStopId: json['nextStopId'] as String?,
      estimatedArrival: json['estimatedArrival'] != null
          ? (json['estimatedArrival'] as Timestamp).toDate()
          : null,
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'plateNumber': plateNumber,
      'driverName': driverName,
      'currentLocation': currentLocation?.toJson(),
      'capacity': capacity,
      'currentCrowd': currentCrowd,
      'crowdLevel': crowdLevel.toString(),
      'status': status.toString(),
      'speed': speed,
      'nextStopId': nextStopId,
      'estimatedArrival': estimatedArrival != null
          ? Timestamp.fromDate(estimatedArrival!)
          : null,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'metadata': metadata,
    };
  }

  Bus copyWith({
    String? id,
    String? routeId,
    String? plateNumber,
    String? driverName,
    BusLocation? currentLocation,
    int? capacity,
    int? currentCrowd,
    CrowdLevel? crowdLevel,
    BusStatus? status,
    double? speed,
    String? nextStopId,
    DateTime? estimatedArrival,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return Bus(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      plateNumber: plateNumber ?? this.plateNumber,
      driverName: driverName ?? this.driverName,
      currentLocation: currentLocation ?? this.currentLocation,
      capacity: capacity ?? this.capacity,
      currentCrowd: currentCrowd ?? this.currentCrowd,
      crowdLevel: crowdLevel ?? this.crowdLevel,
      status: status ?? this.status,
      speed: speed ?? this.speed,
      nextStopId: nextStopId ?? this.nextStopId,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isActive => status == BusStatus.active;
  bool get isTracking => currentLocation != null && isActive;
  double get crowdPercentage => capacity > 0 ? (currentCrowd / capacity) : 0.0;
  
  String get crowdLevelText {
    switch (crowdLevel) {
      case CrowdLevel.empty:
        return 'Empty';
      case CrowdLevel.low:
        return 'Low';
      case CrowdLevel.medium:
        return 'Medium';
      case CrowdLevel.high:
        return 'High';
      case CrowdLevel.full:
        return 'Full';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bus && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Bus(id: $id, plateNumber: $plateNumber, route: $routeId)';
}