// lib/models/bus_stop_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

enum StopType {
  regular,
  terminal,
  interchange,
  express,
}

enum StopAmenity {
  shelter,
  seating,
  lighting,
  accessibility,
  ticketMachine,
  parking,
  restroom,
  wifi,
}

class BusStop {
  final String id;
  final String name;
  final String? description;
  final GeoPoint location;
  final String address;
  final List<String> routeIds;
  final StopType type;
  final List<StopAmenity> amenities;
  final bool isActive;
  final String? zoneId;
  final Map<String, String>? alternateNames; // Different language names
  final double? platformNumber;
  final String? landmark;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const BusStop({
    required this.id,
    required this.name,
    this.description,
    required this.location,
    required this.address,
    this.routeIds = const [],
    this.type = StopType.regular,
    this.amenities = const [],
    this.isActive = true,
    this.zoneId,
    this.alternateNames,
    this.platformNumber,
    this.landmark,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory BusStop.fromJson(Map<String, dynamic> json, String documentId) {
    return BusStop(
      id: documentId,
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['location'] as GeoPoint,
      address: json['address'] as String,
      routeIds: List<String>.from(json['routeIds'] as List? ?? []),
      type: StopType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => StopType.regular,
      ),
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((amenity) => StopAmenity.values.firstWhere(
                    (a) => a.toString() == amenity,
                    orElse: () => StopAmenity.shelter,
                  ))
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      zoneId: json['zoneId'] as String?,
      alternateNames: json['alternateNames'] != null
          ? Map<String, String>.from(json['alternateNames'] as Map)
          : null,
      platformNumber: (json['platformNumber'] as num?)?.toDouble(),
      landmark: json['landmark'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'address': address,
      'routeIds': routeIds,
      'type': type.toString(),
      'amenities': amenities.map((amenity) => amenity.toString()).toList(),
      'isActive': isActive,
      'zoneId': zoneId,
      'alternateNames': alternateNames,
      'platformNumber': platformNumber,
      'landmark': landmark,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  BusStop copyWith({
    String? id,
    String? name,
    String? description,
    GeoPoint? location,
    String? address,
    List<String>? routeIds,
    StopType? type,
    List<StopAmenity>? amenities,
    bool? isActive,
    String? zoneId,
    Map<String, String>? alternateNames,
    double? platformNumber,
    String? landmark,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return BusStop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      routeIds: routeIds ?? this.routeIds,
      type: type ?? this.type,
      amenities: amenities ?? this.amenities,
      isActive: isActive ?? this.isActive,
      zoneId: zoneId ?? this.zoneId,
      alternateNames: alternateNames ?? this.alternateNames,
      platformNumber: platformNumber ?? this.platformNumber,
      landmark: landmark ?? this.landmark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  double get latitude => location.latitude;
  double get longitude => location.longitude;

  String get typeText {
    switch (type) {
      case StopType.regular:
        return 'Regular Stop';
      case StopType.terminal:
        return 'Terminal';
      case StopType.interchange:
        return 'Interchange';
      case StopType.express:
        return 'Express Stop';
    }
  }

  bool hasAmenity(StopAmenity amenity) => amenities.contains(amenity);

  List<String> get amenityTexts {
    return amenities.map((amenity) {
      switch (amenity) {
        case StopAmenity.shelter:
          return 'Shelter';
        case StopAmenity.seating:
          return 'Seating';
        case StopAmenity.lighting:
          return 'Lighting';
        case StopAmenity.accessibility:
          return 'Wheelchair Access';
        case StopAmenity.ticketMachine:
          return 'Ticket Machine';
        case StopAmenity.parking:
          return 'Parking';
        case StopAmenity.restroom:
          return 'Restroom';
        case StopAmenity.wifi:
          return 'WiFi';
      }
    }).toList();
  }

  String get displayName {
    if (landmark != null && landmark!.isNotEmpty) {
      return '$name (near $landmark)';
    }
    return name;
  }

  // Calculate distance to another point in kilometers
  double distanceTo(double lat, double lng) {
    const double earthRadius = 6371.0;
    double dLat = _toRadians(lat - latitude);
    double dLng = _toRadians(lng - longitude);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
        math.cos(_toRadians(lat)) *
        math.sin(dLng / 2) *
        math.sin(dLng / 2);
        
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusStop && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BusStop(id: $id, name: $name, routes: ${routeIds.length})';
}

// Helper class for stop with additional context
class BusStopWithDistance {
  final BusStop stop;
  final double distance;
  final Duration? walkingTime;

  const BusStopWithDistance({
    required this.stop,
    required this.distance,
    this.walkingTime,
  });

  String get distanceText {
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  String get walkingTimeText {
    if (walkingTime == null) return '';
    final minutes = walkingTime!.inMinutes;
    if (minutes < 1) return '< 1 min walk';
    return '$minutes min walk';
  }
}

// Extension for list operations
extension BusStopListExtensions on List<BusStop> {
  List<BusStop> filterByRoute(String routeId) {
    return where((stop) => stop.routeIds.contains(routeId)).toList();
  }

  List<BusStop> filterByZone(String zoneId) {
    return where((stop) => stop.zoneId == zoneId).toList();
  }

  List<BusStop> filterByAmenity(StopAmenity amenity) {
    return where((stop) => stop.hasAmenity(amenity)).toList();
  }

  List<BusStop> filterActive() {
    return where((stop) => stop.isActive).toList();
  }
}
// Import statement needed at top of fileat top of file
