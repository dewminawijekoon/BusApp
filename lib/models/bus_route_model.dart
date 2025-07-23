import 'package:cloud_firestore/cloud_firestore.dart';

enum RouteType {
  regular,
  express,
  intercity,
  shuttle,
  nightService,
}

enum RouteStatus {
  active,
  inactive,
  suspended,
  maintenance,
}

class RouteStop {
  final String stopId;
  final String stopName;
  final GeoPoint location;
  final int sequenceNumber;
  final Duration? estimatedTravelTime;
  final double? fareFromStart;
  final bool isMainStop;

  const RouteStop({
    required this.stopId,
    required this.stopName,
    required this.location,
    required this.sequenceNumber,
    this.estimatedTravelTime,
    this.fareFromStart,
    this.isMainStop = false,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      stopId: json['stopId'] ?? '',
      stopName: json['stopName'] ?? '',
      location: json['location'] as GeoPoint,
      sequenceNumber: json['sequenceNumber'] ?? 0,
      estimatedTravelTime: json['estimatedTravelTime'] != null
          ? Duration(minutes: json['estimatedTravelTime'] as int)
          : null,
      fareFromStart: json['fareFromStart']?.toDouble(),
      isMainStop: json['isMainStop'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stopId': stopId,
      'stopName': stopName,
      'location': location,
      'sequenceNumber': sequenceNumber,
      'estimatedTravelTime': estimatedTravelTime?.inMinutes,
      'fareFromStart': fareFromStart,
      'isMainStop': isMainStop,
    };
  }

  RouteStop copyWith({
    String? stopId,
    String? stopName,
    GeoPoint? location,
    int? sequenceNumber,
    Duration? estimatedTravelTime,
    double? fareFromStart,
    bool? isMainStop,
  }) {
    return RouteStop(
      stopId: stopId ?? this.stopId,
      stopName: stopName ?? this.stopName,
      location: location ?? this.location,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      estimatedTravelTime: estimatedTravelTime ?? this.estimatedTravelTime,
      fareFromStart: fareFromStart ?? this.fareFromStart,
      isMainStop: isMainStop ?? this.isMainStop,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteStop &&
        other.stopId == stopId &&
        other.stopName == stopName &&
        other.location == location &&
        other.sequenceNumber == sequenceNumber &&
        other.estimatedTravelTime == estimatedTravelTime &&
        other.fareFromStart == fareFromStart &&
        other.isMainStop == isMainStop;
  }

  @override
  int get hashCode {
    return stopId.hashCode ^
        stopName.hashCode ^
        location.hashCode ^
        sequenceNumber.hashCode ^
        estimatedTravelTime.hashCode ^
        fareFromStart.hashCode ^
        isMainStop.hashCode;
  }
}

class ScheduleEntry {
  final String id;
  final TimeOfDay departureTime;
  final TimeOfDay? arrivalTime;
  final List<int> operatingDays; // 1-7 for Monday-Sunday
  final String? busId;
  final bool isActive;

  const ScheduleEntry({
    required this.id,
    required this.departureTime,
    this.arrivalTime,
    required this.operatingDays,
    this.busId,
    this.isActive = true,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id'] ?? '',
      departureTime: TimeOfDay(
        hour: json['departureTime']['hour'] ?? 0,
        minute: json['departureTime']['minute'] ?? 0,
      ),
      arrivalTime: json['arrivalTime'] != null
          ? TimeOfDay(
              hour: json['arrivalTime']['hour'] ?? 0,
              minute: json['arrivalTime']['minute'] ?? 0,
            )
          : null,
      operatingDays: List<int>.from(json['operatingDays'] ?? []),
      busId: json['busId'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departureTime': {
        'hour': departureTime.hour,
        'minute': departureTime.minute,
      },
      'arrivalTime': arrivalTime != null
          ? {
              'hour': arrivalTime!.hour,
              'minute': arrivalTime!.minute,
            }
          : null,
      'operatingDays': operatingDays,
      'busId': busId,
      'isActive': isActive,
    };
  }

  ScheduleEntry copyWith({
    String? id,
    TimeOfDay? departureTime,
    TimeOfDay? arrivalTime,
    List<int>? operatingDays,
    String? busId,
    bool? isActive,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      operatingDays: operatingDays ?? this.operatingDays,
      busId: busId ?? this.busId,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods
  bool isOperatingToday() {
    final today = DateTime.now().weekday;
    return operatingDays.contains(today);
  }

  String get operatingDaysText {
    if (operatingDays.length == 7) return 'Daily';
    if (operatingDays.length == 5 && 
        operatingDays.every((day) => day <= 5)) return 'Weekdays';
    if (operatingDays.length == 2 && 
        operatingDays.contains(6) && operatingDays.contains(7)) return 'Weekends';

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return operatingDays.map((day) => dayNames[day - 1]).join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleEntry &&
        other.id == id &&
        other.departureTime == departureTime &&
        other.arrivalTime == arrivalTime &&
        other.operatingDays.toString() == operatingDays.toString() &&
        other.busId == busId &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        departureTime.hashCode ^
        arrivalTime.hashCode ^
        operatingDays.hashCode ^
        busId.hashCode ^
        isActive.hashCode;
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.now() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  String format24Hour() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String format12Hour() {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  int get totalMinutes => hour * 60 + minute;

  bool isAfter(TimeOfDay other) {
    return totalMinutes > other.totalMinutes;
  }

  bool isBefore(TimeOfDay other) {
    return totalMinutes < other.totalMinutes;
  }

  Duration difference(TimeOfDay other) {
    final diff = totalMinutes - other.totalMinutes;
    return Duration(minutes: diff.abs());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDay && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;

  @override
  String toString() => format24Hour();
}

class BusRoute {
  final String id;
  final String routeName;
  final String routeNumber;
  final String description;
  final RouteType type;
  final RouteStatus status;
  final List<RouteStop> stops;
  final List<ScheduleEntry> schedule;
  final double baseFare;
  final double? distanceFareRate;
  final Duration estimatedDuration;
  final String operatorId;
  final String? operatorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final List<String>? tags;
  final double? averageRating;
  final int? totalRatings;

  const BusRoute({
    required this.id,
    required this.routeName,
    required this.routeNumber,
    this.description = '',
    this.type = RouteType.regular,
    this.status = RouteStatus.active,
    required this.stops,
    this.schedule = const [],
    required this.baseFare,
    this.distanceFareRate,
    required this.estimatedDuration,
    required this.operatorId,
    this.operatorName,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.tags,
    this.averageRating,
    this.totalRatings,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json, String id) {
    RouteType type = RouteType.regular;
    try {
      type = RouteType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      );
    } catch (e) {
      type = RouteType.regular;
    }

    RouteStatus status = RouteStatus.active;
    try {
      status = RouteStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      );
    } catch (e) {
      status = RouteStatus.active;
    }

    return BusRoute(
      id: json['id'] ?? '',
      routeName: json['routeName'] ?? '',
      routeNumber: json['routeNumber'] ?? '',
      description: json['description'] ?? '',
      type: type,
      status: status,
      stops: (json['stops'] as List<dynamic>?)
              ?.map((stop) => RouteStop.fromJson(stop as Map<String, dynamic>))
              .toList() ??
          [],
      schedule: (json['schedule'] as List<dynamic>?)
              ?.map((entry) => ScheduleEntry.fromJson(entry as Map<String, dynamic>))
              .toList() ??
          [],
      baseFare: (json['baseFare'] ?? 0.0).toDouble(),
      distanceFareRate: json['distanceFareRate']?.toDouble(),
      estimatedDuration: Duration(minutes: json['estimatedDuration'] ?? 0),
      operatorId: json['operatorId'] ?? '',
      operatorName: json['operatorName'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      averageRating: json['averageRating']?.toDouble(),
      totalRatings: json['totalRatings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeName': routeName,
      'routeNumber': routeNumber,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'stops': stops.map((stop) => stop.toJson()).toList(),
      'schedule': schedule.map((entry) => entry.toJson()).toList(),
      'baseFare': baseFare,
      'distanceFareRate': distanceFareRate,
      'estimatedDuration': estimatedDuration.inMinutes,
      'operatorId': operatorId,
      'operatorName': operatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'metadata': metadata,
      'tags': tags,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
    };
  }

  BusRoute copyWith({
    String? id,
    String? routeName,
    String? routeNumber,
    String? description,
    RouteType? type,
    RouteStatus? status,
    List<RouteStop>? stops,
    List<ScheduleEntry>? schedule,
    double? baseFare,
    double? distanceFareRate,
    Duration? estimatedDuration,
    String? operatorId,
    String? operatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    double? averageRating,
    int? totalRatings,
  }) {
    return BusRoute(
      id: id ?? this.id,
      routeName: routeName ?? this.routeName,
      routeNumber: routeNumber ?? this.routeNumber,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      stops: stops ?? this.stops,
      schedule: schedule ?? this.schedule,
      baseFare: baseFare ?? this.baseFare,
      distanceFareRate: distanceFareRate ?? this.distanceFareRate,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      operatorId: operatorId ?? this.operatorId,
      operatorName: operatorName ?? this.operatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
    );
  }

  // Helper methods
  RouteStop? get startStop => stops.isNotEmpty ? stops.first : null;
  RouteStop? get endStop => stops.isNotEmpty ? stops.last : null;

  List<RouteStop> get mainStops => stops.where((stop) => stop.isMainStop).toList();

  bool get isActive => status == RouteStatus.active;

  String get routeDisplayName => '$routeNumber - $routeName';

  double calculateFare(RouteStop fromStop, RouteStop toStop) {
    if (distanceFareRate == null) return baseFare;
    
    final fromIndex = stops.indexOf(fromStop);
    final toIndex = stops.indexOf(toStop);
    
    if (fromIndex == -1 || toIndex == -1) return baseFare;
    
    final distance = (toIndex - fromIndex).abs();
    return baseFare + (distance * distanceFareRate!);
  }

  Duration? estimatedTravelTime(RouteStop fromStop, RouteStop toStop) {
    final fromIndex = stops.indexOf(fromStop);
    final toIndex = stops.indexOf(toStop);
    
    if (fromIndex == -1 || toIndex == -1) return null;
    
    final fromTime = fromStop.estimatedTravelTime ?? Duration.zero;
    final toTime = toStop.estimatedTravelTime ?? Duration.zero;
    
    return Duration(minutes: (toTime.inMinutes - fromTime.inMinutes).abs());
  }

  List<ScheduleEntry> getTodaySchedule() {
    final today = DateTime.now().weekday;
    return schedule
        .where((entry) => entry.operatingDays.contains(today) && entry.isActive)
        .toList();
  }

  ScheduleEntry? getNextDeparture() {
    final todaySchedule = getTodaySchedule();
    final now = TimeOfDay.now();
    
    final upcoming = todaySchedule
        .where((entry) => entry.departureTime.isAfter(now))
        .toList();
    
    if (upcoming.isEmpty) return null;
    
    upcoming.sort((a, b) => a.departureTime.totalMinutes.compareTo(b.departureTime.totalMinutes));
    return upcoming.first;
  }

  bool containsStop(String stopId) {
    return stops.any((stop) => stop.stopId == stopId);
  }

  int? getStopSequence(String stopId) {
    final stop = stops.firstWhere(
      (stop) => stop.stopId == stopId,
      orElse: () => const RouteStop(
        stopId: '',
        stopName: '',
        location: GeoPoint(0, 0),
        sequenceNumber: -1,
      ),
    );
    return stop.sequenceNumber != -1 ? stop.sequenceNumber : null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusRoute &&
        other.id == id &&
        other.routeName == routeName &&
        other.routeNumber == routeNumber &&
        other.status == status &&
        other.operatorId == operatorId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        routeName.hashCode ^
        routeNumber.hashCode ^
        status.hashCode ^
        operatorId.hashCode;
  }

  @override
  String toString() {
    return 'BusRoute(id: $id, routeName: $routeName, routeNumber: $routeNumber, stops: ${stops.length})';
  }
}