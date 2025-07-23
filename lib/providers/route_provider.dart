import 'package:flutter/foundation.dart';
import '../models/bus_route_model.dart';
import '../models/bus_stop_model.dart';
import '../services/route_service.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';

/// Provider for managing route-related state and operations
/// Handles route searching, saving, and management functionality
class RouteProvider extends ChangeNotifier {
  final RouteService _routeService;
  final DatabaseService _databaseService;

  RouteProvider({
    required RouteService routeService,
    required DatabaseService databaseService,
    required FirebaseService firebaseService, // Keep for future use
  }) : _routeService = routeService,
       _databaseService = databaseService;

  // State variables
  List<BusRoute> _searchResults = [];
  List<OptimalRoute> _optimalRoutes = [];
  List<BusRoute> _savedRoutes = [];
  List<BusRoute> _popularRoutes = [];
  BusRoute? _selectedRoute;

  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  // Search criteria
  BusStop? _lastStartStop;
  BusStop? _lastEndStop;
  DateTime? _lastDepartureTime;

  // Getters
  List<BusRoute> get searchResults => List.unmodifiable(_searchResults);
  List<OptimalRoute> get optimalRoutes => List.unmodifiable(_optimalRoutes);
  List<BusRoute> get savedRoutes => List.unmodifiable(_savedRoutes);
  List<BusRoute> get popularRoutes => List.unmodifiable(_popularRoutes);
  BusRoute? get selectedRoute => _selectedRoute;

  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  // Last search criteria getters
  BusStop? get lastStartStop => _lastStartStop;
  BusStop? get lastEndStop => _lastEndStop;
  DateTime? get lastDepartureTime => _lastDepartureTime;

  /// Search for routes between two bus stops
  Future<void> searchRoutes({
    required BusStop startStop,
    required BusStop endStop,
    DateTime? departureTime,
  }) async {
    _isSearching = true;
    _error = null;
    _lastStartStop = startStop;
    _lastEndStop = endStop;
    _lastDepartureTime = departureTime;
    notifyListeners();

    try {
      // Use route service to find optimal routes
      final optimalRoutes = await _routeService.findOptimalRoutes(
        startStop,
        endStop,
        departureTime: departureTime,
      );

      _optimalRoutes = optimalRoutes;

      // Convert OptimalRoute to BusRoute for compatibility
      // For now, we'll use a simple conversion - in a real app,
      // you'd want to get actual BusRoute objects from the segments
      _searchResults = await _convertOptimalRoutesToBusRoutes(optimalRoutes);
      _error = null;
    } catch (e) {
      _error = 'Failed to search routes: ${e.toString()}';
      _searchResults = [];
      _optimalRoutes = [];
      debugPrint('RouteProvider.searchRoutes error: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Convert OptimalRoutes to BusRoutes for UI compatibility
  Future<List<BusRoute>> _convertOptimalRoutesToBusRoutes(
    List<OptimalRoute> optimalRoutes,
  ) async {
    List<BusRoute> busRoutes = [];

    for (int i = 0; i < optimalRoutes.length; i++) {
      final optimal = optimalRoutes[i];

      // Create a synthetic BusRoute from OptimalRoute data
      final busRoute = BusRoute(
        id: 'search_result_$i',
        routeName: 'Route ${i + 1}',
        routeNumber: '${i + 1}',
        description: 'Optimal route with ${optimal.transferCount} transfers',
        stops: [], // Would need to extract from segments
        baseFare: optimal.totalFare,
        estimatedDuration: optimal.totalDuration,
        operatorId: 'unknown',
        createdAt: DateTime.now(),
      );

      busRoutes.add(busRoute);
    }

    return busRoutes;
  }

  /// Get alternative routes for the same search criteria
  Future<void> getAlternativeRoutes() async {
    if (_lastStartStop == null || _lastEndStop == null) {
      _error = 'No previous search criteria available';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final optimalRoutes = await _routeService.getAlternativeRoutes(
        _lastStartStop!,
        _lastEndStop!,
      );

      _optimalRoutes = optimalRoutes;
      _searchResults = await _convertOptimalRoutesToBusRoutes(optimalRoutes);
      _error = null;
    } catch (e) {
      _error = 'Failed to get alternative routes: ${e.toString()}';
      debugPrint('RouteProvider.getAlternativeRoutes error: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Select a route for detailed viewing or tracking
  void selectRoute(BusRoute route) {
    _selectedRoute = route;
    notifyListeners();
  }

  /// Clear the currently selected route
  void clearSelectedRoute() {
    _selectedRoute = null;
    notifyListeners();
  }

  /// Save a route to user's saved routes
  Future<void> saveRoute(BusRoute route) async {
    try {
      // Save to database
      await _databaseService.saveBusRoute(route);

      // Add to local saved routes if not already present
      if (!_savedRoutes.any((r) => r.id == route.id)) {
        _savedRoutes.add(route);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to save route: ${e.toString()}';
      notifyListeners();
      debugPrint('RouteProvider.saveRoute error: $e');
    }
  }

  /// Remove a route from saved routes
  Future<void> removeSavedRoute(String routeId) async {
    try {
      // For now, use a placeholder user ID - in real app, get from AuthProvider
      const userId = 'anonymous';

      // Remove from database
      await _databaseService.removeSavedRoute(userId, routeId);

      // Remove from local saved routes
      _savedRoutes.removeWhere((route) => route.id == routeId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove saved route: ${e.toString()}';
      notifyListeners();
      debugPrint('RouteProvider.removeSavedRoute error: $e');
    }
  }

  /// Load user's saved routes from database
  Future<void> loadSavedRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For now, use a placeholder user ID - in real app, get from AuthProvider
      const userId = 'anonymous';
      final routes = await _databaseService.getUserSavedRoutes(userId);
      _savedRoutes = routes;
      _error = null;
    } catch (e) {
      _error = 'Failed to load saved routes: ${e.toString()}';
      _savedRoutes = [];
      debugPrint('RouteProvider.loadSavedRoutes error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load popular routes from the community
  Future<void> loadPopularRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For now, use all routes as popular routes
      // In real implementation, this would be a separate method
      final routes = await _databaseService.getBusRoutes();
      _popularRoutes = routes.take(10).toList(); // Top 10 as popular
      _error = null;
    } catch (e) {
      _error = 'Failed to load popular routes: ${e.toString()}';
      _popularRoutes = [];
      debugPrint('RouteProvider.loadPopularRoutes error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update route preferences for better personalized results
  Future<void> updateRoutePreferences({
    required String userId,
    RoutePreferenceType? preferredType,
    bool? avoidCrowdedBuses,
    bool? preferAirConditioned,
    int? maxWalkingDistance,
    int? maxTransfers,
  }) async {
    try {
      final preference = RoutePreference(
        type: preferredType ?? RoutePreferenceType.fastest,
        avoidCrowdedBuses: avoidCrowdedBuses ?? false,
        preferAirConditioned: preferAirConditioned ?? false,
        maxWalkingDistance: maxWalkingDistance ?? 500,
        maxTransfers: maxTransfers ?? 2,
      );

      await _routeService.updateRoutePreferences(userId, preference);
    } catch (e) {
      _error = 'Failed to update route preferences: ${e.toString()}';
      notifyListeners();
      debugPrint('RouteProvider.updateRoutePreferences error: $e');
    }
  }

  /// Calculate estimated time of arrival for a bus on a specific route
  Future<String?> calculateETA(String busId, BusStop destination) async {
    try {
      final etaCalculation = await _routeService.calculateETA(
        busId,
        destination,
      );
      return etaCalculation?.remainingTime.toString();
    } catch (e) {
      debugPrint('RouteProvider.calculateETA error: $e');
      return null;
    }
  }

  /// Sort search results by different criteria
  void sortSearchResults(RouteSortCriteria criteria) {
    switch (criteria) {
      case RouteSortCriteria.fastest:
        _searchResults.sort(
          (a, b) => a.estimatedDuration.compareTo(b.estimatedDuration),
        );
        break;
      case RouteSortCriteria.cheapest:
        _searchResults.sort((a, b) => a.baseFare.compareTo(b.baseFare));
        break;
      case RouteSortCriteria.leastTransfers:
        // For BusRoute, assume direct routes (no transfers) come first
        _searchResults.sort((a, b) => a.stops.length.compareTo(b.stops.length));
        break;
      case RouteSortCriteria.earliest:
        // Sort by creation time for now
        _searchResults.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }
    notifyListeners();
  }

  /// Filter search results by criteria
  void filterSearchResults({
    bool? directRoutesOnly,
    double? maxFare,
    Duration? maxDuration,
    int? maxStops,
  }) {
    List<BusRoute> filteredResults = List.from(_searchResults);

    if (directRoutesOnly == true) {
      // Filter by fewer stops for "direct" routes
      final averageStops = _searchResults.isEmpty
          ? 10
          : _searchResults.map((r) => r.stops.length).reduce((a, b) => a + b) /
                _searchResults.length;
      filteredResults = filteredResults
          .where((route) => route.stops.length <= averageStops)
          .toList();
    }

    if (maxFare != null) {
      filteredResults = filteredResults
          .where((route) => route.baseFare <= maxFare)
          .toList();
    }

    if (maxDuration != null) {
      filteredResults = filteredResults
          .where((route) => route.estimatedDuration <= maxDuration)
          .toList();
    }

    if (maxStops != null) {
      filteredResults = filteredResults
          .where((route) => route.stops.length <= maxStops)
          .toList();
    }

    _searchResults = filteredResults;
    notifyListeners();
  }

  /// Clear all search results
  void clearSearchResults() {
    _searchResults.clear();
    _lastStartStop = null;
    _lastEndStop = null;
    _lastDepartureTime = null;
    notifyListeners();
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([loadSavedRoutes(), loadPopularRoutes()]);
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}

/// Enum for route sorting criteria
enum RouteSortCriteria { fastest, cheapest, leastTransfers, earliest }
