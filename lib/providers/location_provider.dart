import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';
import '../models/bus_stop_model.dart';
import 'dart:math' show cos, pi;

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  // State variables
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  bool _isTracking = false;
  String? _errorMessage;
  LocationPermission? _permissionStatus;
  bool _serviceEnabled = false;
  
  // Nearest bus stop data
  BusStop? _nearestBusStop;
  double? _distanceToNearestStop;
  bool _isLoadingNearestStop = false;
  
  // Stream subscriptions
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<String>? _addressSubscription;
  Timer? _nearestStopUpdateTimer;
  
  // Safe notification flag
  bool _canNotify = true;
  
  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  bool get isTracking => _isTracking;
  String? get errorMessage => _errorMessage;
  LocationPermission? get permissionStatus => _permissionStatus;
  bool get serviceEnabled => _serviceEnabled;
  BusStop? get nearestBusStop => _nearestBusStop;
  double? get distanceToNearestStop => _distanceToNearestStop;
  bool get isLoadingNearestStop => _isLoadingNearestStop;
  
  LatLng? get currentLatLng => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : null;
  
  bool get hasLocation => _currentPosition != null;
  bool get hasPermission => _permissionStatus == LocationPermission.always || 
                           _permissionStatus == LocationPermission.whileInUse;
  
  /// Safe notifyListeners that prevents calling during widget initialization
  void _safeNotifyListeners() {
    if (_canNotify) {
      try {
        notifyListeners();
      } catch (e) {
        // Ignore notification errors during initialization
        debugPrint('LocationProvider: Safe notification caught error: $e');
      }
    }
  }

  LocationProvider();

  /// Initialize the provider - call this manually after widget is built
  Future<void> initialize() async {
    await _checkLocationService();
    await _checkPermissions();
    
    // Try to get last known position
    final lastPosition = await _locationService.getLastKnownPosition();
    if (lastPosition != null) {
      _currentPosition = lastPosition;
      _safeNotifyListeners();
    }
  }

  /// Check if location service is enabled
  Future<void> _checkLocationService() async {
    try {
      _serviceEnabled = await _locationService.isLocationServiceEnabled();
      notifyListeners();
    } catch (e) {
      _handleError('Failed to check location service: ${e.toString()}');
    }
  }

  /// Check location permissions
  Future<void> _checkPermissions() async {
    try {
      _permissionStatus = await _locationService.checkPermission();
      notifyListeners();
    } catch (e) {
      _handleError('Failed to check permissions: ${e.toString()}');
    }
  }

  /// Request location permissions
  Future<bool> requestPermissions() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _permissionStatus = await _locationService.requestPermission();
      
      if (_permissionStatus == LocationPermission.denied || 
          _permissionStatus == LocationPermission.deniedForever) {
        _handleError('Location permission denied');
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _handleError('Failed to request permissions: ${e.toString()}');
      return false;
    }
  }

  /// Get current location once
  Future<Position?> getCurrentLocation({bool forceUpdate = false}) async {
    try {
      // Return cached position if available and not forcing update
      if (!forceUpdate && _currentPosition != null) {
        return _currentPosition;
      }

      _isLoading = true;
      _errorMessage = null;
      _safeNotifyListeners();

      // Check permissions first
      if (!hasPermission) {
        final granted = await requestPermissions();
        if (!granted) return null;
      }

      // Check service
      await _checkLocationService();
      if (!_serviceEnabled) {
        _handleError('Location service is disabled');
        return null;
      }

      // Get current position
      final position = await _locationService.getCurrentPosition();
      
      if (position != null) {
        _currentPosition = position;
        await _updateAddress();
        await getNearestBusStop(); // Automatically find nearest bus stop
      }

      _isLoading = false;
      _safeNotifyListeners();
      return position;
    } catch (e) {
      _handleError('Failed to get current location: ${e.toString()}');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<bool> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) async {
    try {
      if (_isTracking) return true;

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Check permissions
      if (!hasPermission) {
        final granted = await requestPermissions();
        if (!granted) return false;
      }

      // Start tracking
      final success = await _locationService.startLocationTracking(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );

      if (success) {
        _isTracking = true;
        
        // Subscribe to position updates
        _positionSubscription = _locationService.positionStream.listen(
          (position) {
            _currentPosition = position;
            notifyListeners();
          },
          onError: (error) {
            _handleError('Location tracking error: ${error.toString()}');
          },
        );

        // Subscribe to address updates
        _addressSubscription = _locationService.addressStream.listen(
          (address) {
            _currentAddress = address;
            notifyListeners();
          },
        );

        // Start periodic nearest stop updates
        _startNearestStopUpdates();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _handleError('Failed to start location tracking: ${e.toString()}');
      return false;
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    try {
      _locationService.stopLocationTracking();
      _positionSubscription?.cancel();
      _addressSubscription?.cancel();
      _nearestStopUpdateTimer?.cancel();
      
      _isTracking = false;
      _positionSubscription = null;
      _addressSubscription = null;
      _nearestStopUpdateTimer = null;
      
      notifyListeners();
    } catch (e) {
      _handleError('Failed to stop location tracking: ${e.toString()}');
    }
  }

  /// Get nearest bus stop
  Future<BusStop?> getNearestBusStop({double radiusKm = 2.0}) async {
    if (_currentPosition == null) {
      await getCurrentLocation();
      if (_currentPosition == null) return null;
    }

    try {
      _isLoadingNearestStop = true;
      notifyListeners();

      // Calculate search bounds
      final centerLat = _currentPosition!.latitude;
      final centerLng = _currentPosition!.longitude;
      
      // Rough conversion: 1 degree ≈ 111 km
      final latDelta = radiusKm / 111.0;
      final lngDelta = radiusKm / (111.0 * cos(centerLat * pi / 180));

      // Query Firestore for nearby bus stops
      final querySnapshot = await FirebaseFirestore.instance
          .collection('busStops')
          .where('isActive', isEqualTo: true)
          .where('location.latitude', isGreaterThan: centerLat - latDelta)
          .where('location.latitude', isLessThan: centerLat + latDelta)
          .limit(50) // Limit results for performance
          .get();

      if (querySnapshot.docs.isEmpty) {
        _nearestBusStop = null;
        _distanceToNearestStop = null;
        _isLoadingNearestStop = false;
        notifyListeners();
        return null;
      }

      // Parse bus stops and calculate distances
      final busStops = querySnapshot.docs
          .map((doc) => BusStop.fromJson({
            'id': doc.id,
            ...doc.data(),
          }, doc.id))
          .toList();

      BusStop? nearest;
      double? shortestDistance;

      for (final stop in busStops) {
        // Check longitude bounds
        if ((stop.location.longitude - centerLng).abs() > lngDelta) continue;

        final distance = _locationService.calculateDistance(
          centerLat,
          centerLng,
          stop.location.latitude,
          stop.location.longitude,
        );

        // Only consider stops within radius
        if (distance <= radiusKm * 1000) {
          if (shortestDistance == null || distance < shortestDistance) {
            nearest = stop;
            shortestDistance = distance;
          }
        }
      }

      _nearestBusStop = nearest;
      _distanceToNearestStop = shortestDistance;
      _isLoadingNearestStop = false;
      notifyListeners();

      return nearest;
    } catch (e) {
      _handleError('Failed to get nearest bus stop: ${e.toString()}');
      _isLoadingNearestStop = false;
      notifyListeners();
      return null;
    }
  }

  /// Start periodic updates for nearest bus stop
  void _startNearestStopUpdates() {
    _nearestStopUpdateTimer = Timer.periodic(
      const Duration(seconds: 30), // Update every 30 seconds
      (timer) {
        if (_currentPosition != null) {
          getNearestBusStop();
        }
      },
    );
  }

  /// Update current address
  Future<void> _updateAddress() async {
    if (_currentPosition == null) return;

    try {
      final address = await _locationService.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      _currentAddress = address;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update address: $e');
    }
  }

  /// Handle errors
  void _handleError(String message) {
    _errorMessage = message;
    _isLoading = false;
    _isLoadingNearestStop = false;
    notifyListeners();
    debugPrint('LocationProvider Error: $message');
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if user is within radius of a point
  bool isWithinRadius(double lat, double lng, double radiusMeters) {
    if (_currentPosition == null) return false;
    
    return _locationService.isWithinRadius(lat, lng, radiusMeters);
  }

  /// Calculate distance to a point
  double? calculateDistanceTo(double lat, double lng) {
    if (_currentPosition == null) return null;
    
    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
  }

  /// Get formatted distance to nearest bus stop
  String get formattedDistanceToNearestStop {
    if (_distanceToNearestStop == null) return '';
    return _locationService.formatDistance(_distanceToNearestStop!);
  }

  /// Get all nearby bus stops within radius
  Future<List<BusStop>> getNearbyBusStops({
    double radiusKm = 1.0,
    int limit = 20,
  }) async {
    if (_currentPosition == null) return [];

    try {
      final centerLat = _currentPosition!.latitude;
      final centerLng = _currentPosition!.longitude;
      
      final latDelta = radiusKm / 111.0;
      final lngDelta = radiusKm / (111.0 * cos(centerLat * pi / 180));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('busStops')
          .where('isActive', isEqualTo: true)
          .where('location.latitude', isGreaterThan: centerLat - latDelta)
          .where('location.latitude', isLessThan: centerLat + latDelta)
          .limit(limit)
          .get();

      final busStops = <BusStop>[];

      for (final doc in querySnapshot.docs) {
        final stop = BusStop.fromJson({
          'id': doc.id,
          ...doc.data(),
        }, doc.id);
        
        if ((stop.location.longitude - centerLng).abs() <= lngDelta) {
          final distance = _locationService.calculateDistance(
            centerLat,
            centerLng,
            stop.location.latitude,
            stop.location.longitude,
          );

          if (distance <= radiusKm * 1000) {
            busStops.add(stop);
          }
        }
      }

      // Sort by distance
      busStops.sort((a, b) {
        final distanceA = calculateDistanceTo(
          a.location.latitude,
          a.location.longitude,
        ) ?? double.infinity;
        final distanceB = calculateDistanceTo(
          b.location.latitude,
          b.location.longitude,
        ) ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });

      return busStops;
    } catch (e) {
      debugPrint('Error getting nearby bus stops: $e');
      return [];
    }
  }

  /// Force refresh all location data
  Future<void> refresh() async {
    await getCurrentLocation(forceUpdate: true);
    await getNearestBusStop();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await _locationService.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await _locationService.openAppSettings();
  }

  @override
  void dispose() {
    stopLocationTracking();
    _locationService.dispose();
    super.dispose();
  }
}

// Import for math calculations
