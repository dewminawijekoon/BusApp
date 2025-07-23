import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_route_model.dart';
import '../models/bus_stop_model.dart';
import '../models/bus_model.dart';
import 'maps_service.dart';

enum RoutePreferenceType {
  shortest,
  fastest,
  leastTransfers,
  mostComfortable,
  cheapest
}

class RoutePreference {
  final RoutePreferenceType type;
  final bool avoidCrowdedBuses;
  final bool preferAirConditioned;
  final int maxWalkingDistance; // in meters
  final int maxTransfers;

  RoutePreference({
    this.type = RoutePreferenceType.fastest,
    this.avoidCrowdedBuses = false,
    this.preferAirConditioned = false,
    this.maxWalkingDistance = 500,
    this.maxTransfers = 2,
  });
}

class OptimalRoute {
  final List<RouteSegment> segments;
  final Duration totalDuration;
  final double totalDistance;
  final double totalFare;
  final int transferCount;
  final DateTime estimatedArrival;
  final double confidenceScore;

  OptimalRoute({
    required this.segments,
    required this.totalDuration,
    required this.totalDistance,
    required this.totalFare,
    required this.transferCount,
    required this.estimatedArrival,
    required this.confidenceScore,
  });
}

class RouteSegment {
  final BusRoute? busRoute;
  final BusStop startStop;
  final BusStop endStop;
  final Duration duration;
  final double distance;
  final double fare;
  final String type; // 'bus', 'walk', 'wait'
  final String? instructions;

  RouteSegment({
    this.busRoute,
    required this.startStop,
    required this.endStop,
    required this.duration,
    required this.distance,
    required this.fare,
    required this.type,
    this.instructions,
  });
}

class ETACalculation {
  final DateTime estimatedArrival;
  final Duration remainingTime;
  final double confidence;
  final String busId;
  final BusStop destination;
  final List<BusStop> remainingStops;

  ETACalculation({
    required this.estimatedArrival,
    required this.remainingTime,
    required this.confidence,
    required this.busId,
    required this.destination,
    required this.remainingStops,
  });
}

class RouteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MapsService _mapsService = MapsService();

  /// Find optimal routes between two bus stops
  Future<List<OptimalRoute>> findOptimalRoutes(
    BusStop startStop,
    BusStop endStop, {
    RoutePreference? preference,
    DateTime? departureTime,
  }) async {
    try {
      preference ??= RoutePreference();
      departureTime ??= DateTime.now();

      // Get all possible routes
      List<OptimalRoute> allRoutes = [];

      // 1. Direct routes (no transfers)
      final directRoutes = await _findDirectRoutes(startStop, endStop, preference);
      allRoutes.addAll(directRoutes);

      // 2. Routes with one transfer
      final oneTransferRoutes = await _findOneTransferRoutes(startStop, endStop, preference);
      allRoutes.addAll(oneTransferRoutes);

      // 3. Routes with two transfers (if allowed)
      if (preference.maxTransfers >= 2) {
        final twoTransferRoutes = await _findTwoTransferRoutes(startStop, endStop, preference);
        allRoutes.addAll(twoTransferRoutes);
      }

      // Sort routes based on preference
      allRoutes = _sortRoutesByPreference(allRoutes, preference);

      // Return top 5 routes
      return allRoutes.take(5).toList();
    } catch (e) {
      print('Error finding optimal routes: $e');
      return [];
    }
  }

  /// Find direct routes between two stops
  Future<List<OptimalRoute>> _findDirectRoutes(
    BusStop startStop,
    BusStop endStop,
    RoutePreference preference,
  ) async {
    List<OptimalRoute> routes = [];

    // Find common routes between start and end stops
    final commonRoutes = startStop.routeIds
        .where((routeId) => endStop.routeIds.contains(routeId))
        .toList();

    for (String routeId in commonRoutes) {
      final busRoute = await _getBusRoute(routeId);
      if (busRoute == null) continue;

      final routeSegment = RouteSegment(
        busRoute: busRoute,
        startStop: startStop,
        endStop: endStop,
        duration: await _estimateSegmentDuration(busRoute, startStop, endStop),
        distance: _mapsService.calculateDistance(
          startStop.location.latitude,
          startStop.location.longitude,
          endStop.location.latitude,
          endStop.location.longitude,
        ),
        fare: _calculateFare(busRoute, startStop, endStop),
        type: 'bus',
        instructions: 'Take ${busRoute.routeName} from ${startStop.name} to ${endStop.name}',
      );

      final optimalRoute = OptimalRoute(
        segments: [routeSegment],
        totalDuration: routeSegment.duration,
        totalDistance: routeSegment.distance,
        totalFare: routeSegment.fare,
        transferCount: 0,
        estimatedArrival: DateTime.now().add(routeSegment.duration),
        confidenceScore: _calculateConfidenceScore(busRoute, [routeSegment]),
      );

      routes.add(optimalRoute);
    }

    return routes;
  }

  /// Find routes with one transfer
  Future<List<OptimalRoute>> _findOneTransferRoutes(
    BusStop startStop,
    BusStop endStop,
    RoutePreference preference,
  ) async {
    List<OptimalRoute> routes = [];

    // Get all bus stops within reasonable distance for transfers
    final nearbyStops = await _mapsService.getNearbyBusStops(
      startStop.location,
      radiusInKm: 5.0,
    );

    for (BusStop transferStop in nearbyStops) {
      if (transferStop.id == startStop.id || transferStop.id == endStop.id) {
        continue;
      }

      // Check if there's a route from start to transfer stop
      final firstLegRoutes = startStop.routeIds
          .where((routeId) => transferStop.routeIds.contains(routeId))
          .toList();

      // Check if there's a route from transfer stop to end stop
      final secondLegRoutes = transferStop.routeIds
          .where((routeId) => endStop.routeIds.contains(routeId))
          .toList();

      if (firstLegRoutes.isNotEmpty && secondLegRoutes.isNotEmpty) {
        for (String firstRouteId in firstLegRoutes) {
          for (String secondRouteId in secondLegRoutes) {
            final firstRoute = await _getBusRoute(firstRouteId);
            final secondRoute = await _getBusRoute(secondRouteId);

            if (firstRoute == null || secondRoute == null) continue;

            final segments = [
              RouteSegment(
                busRoute: firstRoute,
                startStop: startStop,
                endStop: transferStop,
                duration: await _estimateSegmentDuration(firstRoute, startStop, transferStop),
                distance: _mapsService.calculateDistance(
                  startStop.location.latitude,
                  startStop.location.longitude,
                  transferStop.location.latitude,
                  transferStop.location.longitude,
                ),
                fare: _calculateFare(firstRoute, startStop, transferStop),
                type: 'bus',
                instructions: 'Take ${firstRoute.routeName} to ${transferStop.name}',
              ),
              RouteSegment(
                busRoute: secondRoute,
                startStop: transferStop,
                endStop: endStop,
                duration: await _estimateSegmentDuration(secondRoute, transferStop, endStop),
                distance: _mapsService.calculateDistance(
                  transferStop.location.latitude,
                  transferStop.location.longitude,
                  endStop.location.latitude,
                  endStop.location.longitude,
                ),
                fare: _calculateFare(secondRoute, transferStop, endStop),
                type: 'bus',
                instructions: 'Transfer to ${secondRoute.routeName} and go to ${endStop.name}',
              ),
            ];

            final totalDuration = segments.fold<Duration>(
              Duration.zero,
              (sum, segment) => sum + segment.duration,
            ) + const Duration(minutes: 5); // Transfer time

            final optimalRoute = OptimalRoute(
              segments: segments,
              totalDuration: totalDuration,
              totalDistance: segments.fold<double>(0, (sum, seg) => sum + seg.distance),
              totalFare: segments.fold<double>(0, (sum, seg) => sum + seg.fare),
              transferCount: 1,
              estimatedArrival: DateTime.now().add(totalDuration),
              confidenceScore: _calculateConfidenceScore(firstRoute, segments) * 0.9,
            );

            routes.add(optimalRoute);
          }
        }
      }
    }

    return routes;
  }

  /// Find routes with two transfers
  Future<List<OptimalRoute>> _findTwoTransferRoutes(
    BusStop startStop,
    BusStop endStop,
    RoutePreference preference,
  ) async {
    // Implementation for two-transfer routes (simplified for brevity)
    // This would follow similar logic but with an additional transfer stop
    return [];
  }

  /// Sort routes based on user preference
  List<OptimalRoute> _sortRoutesByPreference(
    List<OptimalRoute> routes,
    RoutePreference preference,
  ) {
    routes.sort((a, b) {
      switch (preference.type) {
        case RoutePreferenceType.shortest:
          return a.totalDistance.compareTo(b.totalDistance);
        case RoutePreferenceType.fastest:
          return a.totalDuration.compareTo(b.totalDuration);
        case RoutePreferenceType.leastTransfers:
          return a.transferCount.compareTo(b.transferCount);
        case RoutePreferenceType.cheapest:
          return a.totalFare.compareTo(b.totalFare);
        case RoutePreferenceType.mostComfortable:
          return b.confidenceScore.compareTo(a.confidenceScore);
      }
    });

    return routes;
  }

  /// Calculate ETA for a specific bus to reach a destination
  Future<ETACalculation?> calculateETA(String busId, BusStop destination) async {
    try {
      // Get current bus location and route
      final busDoc = await _firestore.collection('buses').doc(busId).get();
      if (!busDoc.exists) return null;

      final bus = Bus.fromJson({
        'id': busDoc.id,
        ...busDoc.data() as Map<String, dynamic>,
      }, busDoc.id);
      final busRoute = await _getBusRoute(bus.routeId);
      if (busRoute == null) return null;

      // Find destination stop in route
      final destinationIndex = busRoute.stops.indexWhere(
        (stop) => stop.stopId == destination.id,
      );
      if (destinationIndex == -1) return null;

      // Find current position in route (nearest stop)
      final currentLocation = bus.currentLocation != null 
          ? GeoPoint(bus.currentLocation!.latitude, bus.currentLocation!.longitude)
          : null;
      
      if (currentLocation == null) return null;
      
      final currentStopIndex = await _findNearestStopIndexFromRouteStops(
        currentLocation,
        busRoute.stops,
      );

      if (currentStopIndex >= destinationIndex) {
        // Bus has already passed the destination
        return null;
      }

      // Calculate remaining stops and convert RouteStops to BusStops
      final remainingRouteStops = busRoute.stops
          .sublist(currentStopIndex + 1, destinationIndex + 1);
      
      // Convert RouteStops to BusStops for compatibility
      final remainingStops = await _convertRouteStopsToBusStops(remainingRouteStops);

      // Estimate time based on average speed and traffic
      final estimatedMinutes = _estimateTimeToDestinationFromRouteStops(
        remainingRouteStops,
        currentLocation,
        destination.location,
      );

      final estimatedArrival = DateTime.now().add(
        Duration(minutes: estimatedMinutes),
      );

      return ETACalculation(
        estimatedArrival: estimatedArrival,
        remainingTime: Duration(minutes: estimatedMinutes),
        confidence: _calculateETAConfidence(remainingStops.length, estimatedMinutes),
        busId: busId,
        destination: destination,
        remainingStops: remainingStops,
      );
    } catch (e) {
      print('Error calculating ETA: $e');
      return null;
    }
  }

  /// Get alternative routes if primary route is disrupted
  Future<List<OptimalRoute>> getAlternativeRoutes(
    BusStop startStop,
    BusStop endStop, {
    List<String>? excludeRouteIds,
  }) async {
    // Find routes excluding the disrupted ones
    final allRoutes = await findOptimalRoutes(startStop, endStop);
    
    if (excludeRouteIds == null || excludeRouteIds.isEmpty) {
      return allRoutes;
    }

    return allRoutes.where((route) {
      return !route.segments.any((segment) =>
          segment.busRoute != null &&
          excludeRouteIds.contains(segment.busRoute!.id));
    }).toList();
  }

  /// Update user route preferences
  Future<void> updateRoutePreferences(String userId, RoutePreference preference) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'routePreferences': {
          'type': preference.type.toString(),
          'avoidCrowdedBuses': preference.avoidCrowdedBuses,
          'preferAirConditioned': preference.preferAirConditioned,
          'maxWalkingDistance': preference.maxWalkingDistance,
          'maxTransfers': preference.maxTransfers,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating route preferences: $e');
    }
  }

  /// Helper method to get bus route by ID
  Future<BusRoute?> _getBusRoute(String routeId) async {
    try {
      final doc = await _firestore.collection('busRoutes').doc(routeId).get();
      if (doc.exists) {
        return BusRoute.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting bus route: $e');
      return null;
    }
  }

  /// Estimate duration for a route segment
  Future<Duration> _estimateSegmentDuration(
    BusRoute route,
    BusStop startStop,
    BusStop endStop,
  ) async {
    // Base calculation on average speed and distance
    final distance = _mapsService.calculateDistance(
      startStop.location.latitude,
      startStop.location.longitude,
      endStop.location.latitude,
      endStop.location.longitude,
    );

    // Average bus speed in urban areas (considering traffic)
    const double averageSpeedKmH = 20.0;
    final timeInHours = distance / averageSpeedKmH;
    final baseMinutes = (timeInHours * 60).round();

    // Add buffer time based on number of stops
    final stopCount = _countStopsBetween(route, startStop, endStop);
    final stopDelayMinutes = stopCount * 2; // 2 minutes per stop

    return Duration(minutes: baseMinutes + stopDelayMinutes);
  }

  /// Calculate fare for a route segment
  double _calculateFare(BusRoute route, BusStop startStop, BusStop endStop) {
    // Base fare calculation (simplified)
    const double baseFare = 50.0; // Base fare in local currency
    const double farePerKm = 5.0;

    final distance = _mapsService.calculateDistance(
      startStop.location.latitude,
      startStop.location.longitude,
      endStop.location.latitude,
      endStop.location.longitude,
    );

    return baseFare + (distance * farePerKm);
  }

  /// Calculate confidence score for a route
  double _calculateConfidenceScore(BusRoute route, List<RouteSegment> segments) {
    // Base confidence
    double score = 0.8;

    // Adjust based on route reliability
    if (route.isActive) score += 0.1;
    
    // Adjust based on number of transfers
    final transferCount = segments.length - 1;
    score -= transferCount * 0.1;

    // Ensure score is between 0 and 1
    return score.clamp(0.0, 1.0);
  }

  /// Find nearest stop index for current bus location from RouteStops
  Future<int> _findNearestStopIndexFromRouteStops(GeoPoint currentLocation, List<RouteStop> stops) async {
    int nearestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < stops.length; i++) {
      final distance = _mapsService.calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        stops[i].location.latitude,
        stops[i].location.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  /// Convert RouteStops to BusStops
  Future<List<BusStop>> _convertRouteStopsToBusStops(List<RouteStop> routeStops) async {
    List<BusStop> busStops = [];
    
    for (RouteStop routeStop in routeStops) {
      try {
        final doc = await _firestore.collection('busStops').doc(routeStop.stopId).get();
        if (doc.exists) {
          final busStop = BusStop.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          }, doc.id);
          busStops.add(busStop);
        }
      } catch (e) {
        print('Error converting route stop ${routeStop.stopId}: $e');
      }
    }
    
    return busStops;
  }

  /// Estimate time to destination from RouteStops
  int _estimateTimeToDestinationFromRouteStops(
    List<RouteStop> remainingStops,
    GeoPoint currentLocation,
    GeoPoint destination,
  ) {
    // Calculate total distance
    double totalDistance = 0.0;

    // Distance from current location to first stop
    if (remainingStops.isNotEmpty) {
      totalDistance += _mapsService.calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        remainingStops.first.location.latitude,
        remainingStops.first.location.longitude,
      );
    }

    // Distance between stops
    for (int i = 0; i < remainingStops.length - 1; i++) {
      totalDistance += _mapsService.calculateDistance(
        remainingStops[i].location.latitude,
        remainingStops[i].location.longitude,
        remainingStops[i + 1].location.latitude,
        remainingStops[i + 1].location.longitude,
      );
    }

    // Convert to time (assuming average speed of 20 km/h)
    const double averageSpeedKmH = 20.0;
    final timeInHours = totalDistance / averageSpeedKmH;
    final baseMinutes = (timeInHours * 60).round();

    // Add stop delays
    final stopDelayMinutes = remainingStops.length * 2;

    return baseMinutes + stopDelayMinutes;
  }

  /// Calculate ETA confidence based on various factors
  double _calculateETAConfidence(int stopCount, int estimatedMinutes) {
    double confidence = 0.9;

    // Reduce confidence for longer routes
    if (estimatedMinutes > 60) confidence -= 0.2;
    if (estimatedMinutes > 30) confidence -= 0.1;

    // Reduce confidence for routes with many stops
    if (stopCount > 10) confidence -= 0.1;
    if (stopCount > 20) confidence -= 0.2;

    return confidence.clamp(0.3, 1.0);
  }

  /// Count stops between two stops on a route
  int _countStopsBetween(BusRoute route, BusStop startStop, BusStop endStop) {
    final startIndex = route.stops.indexWhere((stop) => stop.stopId == startStop.id);
    final endIndex = route.stops.indexWhere((stop) => stop.stopId == endStop.id);

    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
      return 0;
    }

    return endIndex - startIndex;
  }
}