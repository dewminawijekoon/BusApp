import 'package:flutter/foundation.dart';
import '../models/bus_route_model.dart';
import '../models/bus_stop_model.dart';
import '../services/route_service.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';

class RouteProvider with ChangeNotifier {
  final RouteService _routeService;
  final DatabaseService _databaseService;
  final FirebaseService _firebaseService;

  RouteProvider({
    required RouteService routeService,
    required DatabaseService databaseService,
    required FirebaseService firebaseService,
  })  : _routeService = routeService,
        _databaseService = databaseService,
        _firebaseService = firebaseService;

  // State variables
  List<BusRoute> _searchResults = [];
  BusRoute? _selectedRoute;
  List<BusRoute> _savedRoutes = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String? _error;
  
  // Search parameters
  BusStop? _startStop;
  BusStop? _endStop;
  DateTime? _searchDateTime;
  RoutePreferenceType _routePreference = RoutePreferenceType.fastest;

  // Getters
  List<BusRoute> get searchResults => _searchResults;
  BusRoute? get selectedRoute => _selectedRoute;
  List<BusRoute> get savedRoutes => _savedRoutes;
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;
  String? get error => _error;
  BusStop? get startStop => _startStop;
  BusStop? get endStop => _endStop;
  DateTime? get searchDateTime => _searchDateTime;
  RoutePreferenceType get routePreference => _routePreference;

  /// Search for routes between start and end stops
  Future<void> searchRoutes({
    required BusStop startStop,
    required BusStop endStop,
    DateTime? departureTime,
    RoutePreferenceType? preference,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      _isSearching = true;

      // Update search parameters
      _startStop = startStop;
      _endStop = endStop;
      _searchDateTime = departureTime ?? DateTime.now();
      _routePreference = preference ?? RoutePreferenceType.fastest;

      // Clear previous results
      _searchResults.clear();
      notifyListeners();

      // Find optimal routes using route service
      final routes = await _routeService.findOptimalRoutes(
        startStop,
        endStop,
        preference: RoutePreference(type: _routePreference),
        departureTime: _searchDateTime!,
      );

      // Convert OptimalRoutes to simplified BusRoutes for display
      _searchResults = routes.map((optimalRoute) => _convertOptimalRouteToBusRoute(optimalRoute)).toList();
      _isSearching = false;

      // Log search for analytics
      await _logRouteSearch(startStop, endStop);

    } catch (e) {
      _setError('Failed to search routes: ${e.toString()}');
      _isSearching = false;
    } finally {
      _setLoading(false);
    }
  }

  /// Select a specific route for navigation
  Future<void> selectRoute(BusRoute route) async {
    try {
      _setLoading(true);
      _setError(null);

      _selectedRoute = route;
      
      // Log route selection
      await _logRouteSelection(route);

      notifyListeners();
    } catch (e) {
      _setError('Failed to select route: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Save a route to user's favorites
  Future<void> saveRoute(BusRoute route) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if route is already saved
      final existingRoute = _savedRoutes.firstWhere(
        (savedRoute) => savedRoute.id == route.id,
        orElse: () => _createEmptyRoute(),
      );

      if (existingRoute.id.isNotEmpty) {
        throw Exception('Route is already saved');
      }

      // Save to database (route will be saved as-is)
      await _databaseService.saveUserRoute(userId, route);

      // Update local state
      _savedRoutes.add(route);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to save route: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Remove a saved route
  Future<void> removeSavedRoute(String routeId) async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Remove from database
      await _firebaseService.removeUserRoute(userId, routeId);

      // Update local state
      _savedRoutes.removeWhere((route) => route.id == routeId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove saved route: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load user's saved routes
  Future<void> loadSavedRoutes() async {
    try {
      _setLoading(true);
      _setError(null);

      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final routes = await _databaseService.getUserSavedRoutes(userId);
      _savedRoutes = routes;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load saved routes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Get alternative routes for current search
  Future<void> getAlternativeRoutes() async {
    if (_startStop == null || _endStop == null) {
      _setError('Start and end stops must be selected');
      return;
    }

    try {
      _setLoading(true);
      _setError(null);

      final alternatives = await _routeService.getAlternativeRoutes(
        _startStop!,
        _endStop!,
      );

      // Convert OptimalRoutes to BusRoutes and add to existing results without duplicates
      for (final optimalRoute in alternatives) {
        final route = _convertOptimalRouteToBusRoute(optimalRoute);
        if (!_searchResults.any((existing) => existing.id == route.id)) {
          _searchResults.add(route);
        }
      }

      // Re-sort all results
      _searchResults.sort((a, b) => _compareRoutes(a, b));
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to get alternative routes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Update route preference and re-search if needed
  void updateRoutePreference(RoutePreferenceType preference) {
    if (_routePreference != preference) {
      _routePreference = preference;
      
      // Re-sort existing results based on new preference
      if (_searchResults.isNotEmpty) {
        _searchResults.sort((a, b) => _compareRoutes(a, b));
        notifyListeners();
      }
    }
  }

  /// Refresh ETAs for current search results
  Future<void> refreshETAs() async {
    if (_searchResults.isEmpty) return;

    try {
      // For now, just notify listeners to refresh the UI
      // In a real implementation, you would update the ETAs from live data
      notifyListeners();
    } catch (e) {
      // Silently fail ETA refresh to not interrupt user experience
      debugPrint('Failed to refresh ETAs: $e');
    }
  }

  /// Clear all search results and selected route
  void clearSearch() {
    _searchResults.clear();
    _selectedRoute = null;
    _startStop = null;
    _endStop = null;
    _searchDateTime = null;
    _isSearching = false;
    _setError(null);
    notifyListeners();
  }

  /// Swap start and end stops for return journey
  void swapStops() {
    if (_startStop != null && _endStop != null) {
      final temp = _startStop;
      _startStop = _endStop;
      _endStop = temp;
      notifyListeners();
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Compare routes based on current preference
  int _compareRoutes(BusRoute a, BusRoute b) {
    switch (_routePreference) {
      case RoutePreferenceType.fastest:
        return a.estimatedDuration.compareTo(b.estimatedDuration);
      case RoutePreferenceType.cheapest:
        return a.baseFare.compareTo(b.baseFare);
      case RoutePreferenceType.leastTransfers:
        // Since BusRoute doesn't have transfers, compare by number of stops as a proxy
        final stopsComparison = a.stops.length.compareTo(b.stops.length);
        if (stopsComparison == 0) {
          return a.estimatedDuration.compareTo(b.estimatedDuration);
        }
        return stopsComparison;
      case RoutePreferenceType.mostComfortable:
        // For comfort, prefer shorter duration and fewer stops
        final durationComparison = a.estimatedDuration.compareTo(b.estimatedDuration);
        if (durationComparison == 0) {
          return a.stops.length.compareTo(b.stops.length);
        }
        return durationComparison;
      case RoutePreferenceType.shortest:
        // Balanced scoring: duration (50%) + fare (30%) + stops (20%)
        final scoreA = _calculateBalancedScore(a);
        final scoreB = _calculateBalancedScore(b);
        return scoreA.compareTo(scoreB);
    }
  }

  /// Calculate balanced score for route comparison
  double _calculateBalancedScore(BusRoute route) {
    // Normalize values (assuming reasonable maximums)
    final durationScore = route.estimatedDuration.inMinutes / 120.0; // Max 2 hours
    final fareScore = route.baseFare / 200.0; // Max Rs. 200
    final stopsScore = route.stops.length / 20.0; // Max 20 stops

    return (durationScore * 0.5) + 
           (fareScore * 0.3) + 
           (stopsScore * 0.2);
  }

  /// Log route search for analytics
  Future<void> _logRouteSearch(BusStop startStop, BusStop endStop) async {
    try {
      await _firebaseService.logEvent('route_search', {
        'start_stop': startStop.name,
        'end_stop': endStop.name,
        'search_time': DateTime.now().toIso8601String(),
        'preference': _routePreference.toString(),
      });
    } catch (e) {
      debugPrint('Failed to log route search: $e');
    }
  }

  /// Log route selection for analytics
  Future<void> _logRouteSelection(BusRoute route) async {
    try {
      await _firebaseService.logEvent('route_selected', {
        'route_id': route.id,
        'duration_minutes': route.estimatedDuration.inMinutes,
        'fare': route.baseFare,
        'stops_count': route.stops.length,
        'selection_time': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to log route selection: $e');
    }
  }

  /// Convert OptimalRoute to BusRoute for display purposes
  BusRoute _convertOptimalRouteToBusRoute(OptimalRoute optimalRoute) {
    // For now, create a simplified BusRoute from the OptimalRoute
    // In a real app, you might want to create a more sophisticated mapping
    final mainSegment = optimalRoute.segments.firstWhere(
      (segment) => segment.busRoute != null,
      orElse: () => optimalRoute.segments.first,
    );

    return BusRoute(
      id: 'optimal_${DateTime.now().millisecondsSinceEpoch}',
      routeName: mainSegment.busRoute?.routeName ?? 'Multi-Route Journey',
      routeNumber: mainSegment.busRoute?.routeNumber ?? 'MULTI',
      description: 'Optimized route with ${optimalRoute.transferCount} transfers',
      stops: _getStopsFromSegments(optimalRoute.segments),
      baseFare: optimalRoute.totalFare,
      estimatedDuration: optimalRoute.totalDuration,
      operatorId: mainSegment.busRoute?.operatorId ?? 'system',
      createdAt: DateTime.now(),
    );
  }

  /// Extract stops from route segments
  List<RouteStop> _getStopsFromSegments(List<RouteSegment> segments) {
    final stops = <RouteStop>[];
    int sequenceNumber = 0;

    for (final segment in segments) {
      if (segment.type == 'bus' && segment.busRoute != null) {
        // Add the relevant stops from this bus route segment
        final relevantStops = segment.busRoute!.stops.where((stop) {
          return stop.stopId == segment.startStop.id || stop.stopId == segment.endStop.id;
        }).toList();
        
        for (final stop in relevantStops) {
          stops.add(stop.copyWith(sequenceNumber: sequenceNumber++));
        }
      } else {
        // For walking segments, create basic route stops
        stops.add(RouteStop(
          stopId: segment.startStop.id,
          stopName: segment.startStop.name,
          location: segment.startStop.location,
          sequenceNumber: sequenceNumber++,
        ));
      }
    }

    return stops;
  }

  /// Create an empty route for comparison
  BusRoute _createEmptyRoute() {
    return BusRoute(
      id: '',
      routeName: '',
      routeNumber: '',
      stops: [],
      baseFare: 0.0,
      estimatedDuration: Duration.zero,
      operatorId: '',
      createdAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    // Clean up any subscriptions or resources
    super.dispose();
  }
}

