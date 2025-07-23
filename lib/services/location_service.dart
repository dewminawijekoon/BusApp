import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  String? _currentAddress;
  bool _isTracking = false;

  // Stream controllers for broadcasting location updates
  final StreamController<Position> _positionStreamController = 
      StreamController<Position>.broadcast();
  final StreamController<String> _addressStreamController = 
      StreamController<String>.broadcast();

  // Public streams
  Stream<Position> get positionStream => _positionStreamController.stream;
  Stream<String> get addressStream => _addressStreamController.stream;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isTracking => _isTracking;
  
  LatLng? get currentLatLng => _currentPosition != null
      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
      : null;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Handle location permission and service checks
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  /// Get current position once
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) async {
    try {
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit,
      );

      _currentPosition = position;
      _positionStreamController.add(position);
      
      // Update address
      await _updateAddress(position);

      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<bool> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) async {
    try {
      if (_isTracking) {
        debugPrint('Location tracking is already active');
        return true;
      }

      final hasPermission = await handleLocationPermission();
      if (!hasPermission) return false;

      final LocationSettings locationSettings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          _positionStreamController.add(position);
          _updateAddress(position);
        },
        onError: (error) {
          debugPrint('Location tracking error: $error');
          stopLocationTracking();
        },
      );

      _isTracking = true;
      debugPrint('Location tracking started');
      return true;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    debugPrint('Location tracking stopped');
  }

  /// Update address from coordinates
  Future<void> _updateAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentAddress = _formatAddress(place);
        _addressStreamController.add(_currentAddress!);
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
  }

  /// Format placemark to readable address
  String _formatAddress(Placemark place) {
    final components = <String>[];
    
    if (place.street?.isNotEmpty == true) {
      components.add(place.street!);
    }
    if (place.subLocality?.isNotEmpty == true) {
      components.add(place.subLocality!);
    }
    if (place.locality?.isNotEmpty == true) {
      components.add(place.locality!);
    }
    if (place.administrativeArea?.isNotEmpty == true) {
      components.add(place.administrativeArea!);
    }

    return components.join(', ');
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return _formatAddress(placemarks.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Get coordinates from address
  Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      debugPrint('Error getting coordinates from address: $e');
      return [];
    }
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two points
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if user is within radius of a point
  bool isWithinRadius(
    double centerLatitude,
    double centerLongitude,
    double radius, {
    Position? userPosition,
  }) {
    final position = userPosition ?? _currentPosition;
    if (position == null) return false;

    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      centerLatitude,
      centerLongitude,
    );

    return distance <= radius;
  }

  /// Get nearby bus stops within radius
  Future<List<LatLng>> getNearbyPoints(
    List<LatLng> points,
    double radiusInMeters, {
    Position? fromPosition,
  }) async {
    final position = fromPosition ?? _currentPosition;
    if (position == null) return [];

    final nearbyPoints = <LatLng>[];

    for (final point in points) {
      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        point.latitude,
        point.longitude,
      );

      if (distance <= radiusInMeters) {
        nearbyPoints.add(point);
      }
    }

    // Sort by distance
    nearbyPoints.sort((a, b) {
      final distanceA = calculateDistance(
        position.latitude,
        position.longitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = calculateDistance(
        position.latitude,
        position.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });

    return nearbyPoints;
  }

  /// Format distance to human readable format
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Format duration to human readable format
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Check if location accuracy is good enough
  bool isAccuracyAcceptable(Position position, {double threshold = 10.0}) {
    return position.accuracy <= threshold;
  }

  /// Get location settings for different use cases
  LocationSettings getLocationSettings(LocationTrackingMode mode) {
    switch (mode) {
      case LocationTrackingMode.highAccuracy:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        );
      case LocationTrackingMode.balanced:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
      case LocationTrackingMode.lowPower:
        return const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 25,
        );
      case LocationTrackingMode.passive:
        return const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 100,
        );
    }
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Error opening location settings: $e');
      return false;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  /// Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('Error getting last known position: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
    _positionStreamController.close();
    _addressStreamController.close();
  }
}

/// Location tracking modes for different use cases
enum LocationTrackingMode {
  highAccuracy,    // Best accuracy, more battery usage
  balanced,        // Good balance of accuracy and battery
  lowPower,        // Lower accuracy, less battery usage
  passive,         // Minimal battery usage
}

/// Location service extensions for easy access
extension LocationServiceExtensions on LocationService {
  /// Quick check if location is available
  Future<bool> get isLocationAvailable async {
    final hasPermission = await handleLocationPermission();
    return hasPermission && await isLocationServiceEnabled();
  }

  /// Get current LatLng or null
  Future<LatLng?> get currentLatLngAsync async {
    final position = await getCurrentPosition();
    return position != null 
        ? LatLng(position.latitude, position.longitude)
        : null;
  }

  /// Quick distance check
  bool isNearby(LatLng point, double radiusMeters) {
    return isWithinRadius(
      point.latitude, 
      point.longitude, 
      radiusMeters,
    );
  }
}