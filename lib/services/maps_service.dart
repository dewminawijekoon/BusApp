import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_stop_model.dart';

class DirectionsResult {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final List<DirectionStep> steps;

  DirectionsResult({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.steps,
  });
}

class DirectionStep {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;

  DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
  });
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatLng && 
           other.latitude == latitude && 
           other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

class MapsService {
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with actual API key
  static const String _directionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _geocodingBaseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get directions between two points using Google Directions API
  Future<DirectionsResult?> getDirections(
    GeoPoint start, 
    GeoPoint end, {
    String travelMode = 'driving',
  }) async {
    try {
      final String url = '$_directionsBaseUrl?'
          'origin=${start.latitude},${start.longitude}&'
          'destination=${end.latitude},${end.longitude}&'
          'mode=$travelMode&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return _parseDirectionsResponse(data);
        }
      }
      return null;
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  /// Parse Google Directions API response
  DirectionsResult _parseDirectionsResponse(Map<String, dynamic> data) {
    final route = data['routes'][0];
    final leg = route['legs'][0];
    
    // Extract polyline points
    final polylinePoints = _decodePolyline(route['overview_polyline']['points']);
    
    // Extract steps
    final steps = <DirectionStep>[];
    for (var step in leg['steps']) {
      steps.add(DirectionStep(
        instruction: step['html_instructions'],
        distance: step['distance']['text'],
        duration: step['duration']['text'],
        startLocation: LatLng(
          step['start_location']['lat'].toDouble(),
          step['start_location']['lng'].toDouble(),
        ),
        endLocation: LatLng(
          step['end_location']['lat'].toDouble(),
          step['end_location']['lng'].toDouble(),
        ),
      ));
    }

    return DirectionsResult(
      polylinePoints: polylinePoints,
      distance: leg['distance']['text'],
      duration: leg['duration']['text'],
      steps: steps,
    );
  }

  /// Decode Google polyline encoding
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  /// Get nearby bus stops within specified radius
  Future<List<BusStop>> getNearbyBusStops(
    GeoPoint location, {
    double radiusInKm = 2.0,
  }) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('busStops')
          .get();

      List<BusStop> nearbyStops = [];

      for (var doc in querySnapshot.docs) {
        final busStop = BusStop.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }, doc.id);
        final distance = calculateDistance(
          location.latitude,
          location.longitude,
          busStop.location.latitude,
          busStop.location.longitude,
        );

        if (distance <= radiusInKm) {
          nearbyStops.add(busStop);
        }
      }

      // Sort by distance
      nearbyStops.sort((a, b) {
        final distanceA = calculateDistance(
          location.latitude,
          location.longitude,
          a.location.latitude,
          a.location.longitude,
        );
        final distanceB = calculateDistance(
          location.latitude,
          location.longitude,
          b.location.latitude,
          b.location.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      return nearbyStops;
    } catch (e) {
      print('Error getting nearby bus stops: $e');
      return [];
    }
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  /// Calculate total distance for a route with multiple points
  double calculateRouteDistance(List<GeoPoint> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return totalDistance;
  }

  /// Get place information from coordinates using reverse geocoding
  Future<String?> getPlaceFromCoordinates(double lat, double lng) async {
    try {
      // First try using geocoding package
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return _formatPlacemark(place);
      }

      // Fallback to Google Geocoding API
      return await _getPlaceFromGoogleGeocoding(lat, lng);
    } catch (e) {
      print('Error getting place from coordinates: $e');
      return null;
    }
  }

  /// Format placemark into readable address
  String _formatPlacemark(Placemark place) {
    List<String> parts = [];
    
    if (place.name != null && place.name!.isNotEmpty) {
      parts.add(place.name!);
    }
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    return parts.join(', ');
  }

  /// Get place using Google Geocoding API as fallback
  Future<String?> _getPlaceFromGoogleGeocoding(double lat, double lng) async {
    try {
      final String url = '$_geocodingBaseUrl?'
          'latlng=$lat,$lng&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
      return null;
    } catch (e) {
      print('Error with Google Geocoding API: $e');
      return null;
    }
  }

  /// Get coordinates from place name
  Future<GeoPoint?> getCoordinatesFromPlace(String placeName) async {
    try {
      List<Location> locations = await locationFromAddress(placeName);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        return GeoPoint(location.latitude, location.longitude);
      }
      return null;
    } catch (e) {
      print('Error getting coordinates from place: $e');
      return null;
    }
  }

  /// Search for places using Google Places API
  Future<List<PlaceSearchResult>> searchPlaces(
    String query, 
    GeoPoint? location, {
    double radiusInMeters = 5000,
  }) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?'
          'query=${Uri.encodeComponent(query)}&'
          'key=$_apiKey';

      if (location != null) {
        url += '&location=${location.latitude},${location.longitude}&'
               'radius=$radiusInMeters';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return (data['results'] as List)
              .map((result) => PlaceSearchResult.fromJson(result))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location permission status
  Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await getLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }
}

class PlaceSearchResult {
  final String placeId;
  final String name;
  final String formattedAddress;
  final GeoPoint location;
  final double? rating;

  PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.location,
    this.rating,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      location: GeoPoint(
        json['geometry']['location']['lat'].toDouble(),
        json['geometry']['location']['lng'].toDouble(),
      ),
      rating: json['rating']?.toDouble(),
    );
  }
}