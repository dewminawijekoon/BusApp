import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/bus_stop_model.dart';
import '../../models/bus_model.dart';
import '../../services/maps_service.dart' as maps_service;

class CustomMapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final double initialZoom;
  final Set<Marker>? initialMarkers;
  final Set<Polyline>? initialPolylines;
  final Set<Circle>? initialCircles;
  final bool showUserLocation;
  final bool showBusStops;
  final bool showActiveBuses;
  final List<String>? filterRouteIds;
  final Function(LatLng)? onMapTap;
  final Function(Marker)? onMarkerTap;
  final Function(GoogleMapController)? onMapCreated;
  final bool enableCurrentLocation;
  final VoidCallback? onCurrentLocationPressed;

  const CustomMapWidget({
    Key? key,
    this.initialLocation,
    this.initialZoom = 14.0,
    this.initialMarkers,
    this.initialPolylines,
    this.initialCircles,
    this.showUserLocation = true,
    this.showBusStops = true,
    this.showActiveBuses = false,
    this.filterRouteIds,
    this.onMapTap,
    this.onMarkerTap,
    this.onMapCreated,
    this.enableCurrentLocation = true,
    this.onCurrentLocationPressed,
  }) : super(key: key);

  @override
  State<CustomMapWidget> createState() => _CustomMapWidgetState();
}

class _CustomMapWidgetState extends State<CustomMapWidget> {
  GoogleMapController? _mapController;
  final maps_service.MapsService _mapsService = maps_service.MapsService();
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _busLocationSubscription;
  
  bool _isLoading = true;
  bool _showTraffic = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _busLocationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Initialize markers from props
      if (widget.initialMarkers != null) {
        _markers.addAll(widget.initialMarkers!);
      }

      // Initialize polylines from props
      if (widget.initialPolylines != null) {
        _polylines.addAll(widget.initialPolylines!);
      }

      // Initialize circles from props
      if (widget.initialCircles != null) {
        _circles.addAll(widget.initialCircles!);
      }

      // Get current location if needed
      if (widget.showUserLocation) {
        await _getCurrentLocation();
      }

      // Load bus stops if enabled
      if (widget.showBusStops) {
        await _loadBusStops();
      }

      // Start tracking active buses if enabled
      if (widget.showActiveBuses) {
        _startBusTracking();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing map: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _mapsService.getCurrentPosition();
      if (position != null) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        
        // Add current location marker
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(
              title: 'Your Location',
              snippet: 'Current position',
            ),
          ),
        );

        // Start location tracking
        _startLocationTracking();
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentLocation = newLocation;
        
        // Update current location marker
        _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: newLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(
              title: 'Your Location',
              snippet: 'Current position',
            ),
          ),
        );
      });
    });
  }

  Future<void> _loadBusStops() async {
    try {
      List<BusStop> busStops = [];

      if (widget.filterRouteIds != null && widget.filterRouteIds!.isNotEmpty) {
        // Load bus stops for specific routes
        for (String routeId in widget.filterRouteIds!) {
          final routeStops = await _getBusStopsForRoute(routeId);
          busStops.addAll(routeStops);
        }
        // Remove duplicates
        busStops = busStops.toSet().toList();
      } else {
        // Load all bus stops in the area
        busStops = await _getAllBusStops();
      }

      // Create markers for bus stops
      for (BusStop stop in busStops) {
        _markers.add(
          Marker(
            markerId: MarkerId('bus_stop_${stop.id}'),
            position: LatLng(stop.location.latitude, stop.location.longitude),
            icon: await _createBusStopIcon(),
            infoWindow: InfoWindow(
              title: stop.name,
              snippet: 'ID: ${stop.id}${stop.routeIds.isNotEmpty ? '\nRoutes: ${stop.routeIds.join(", ")}' : ''}',
            ),
            onTap: () {
              if (widget.onMarkerTap != null) {
                widget.onMarkerTap!(Marker(
                  markerId: MarkerId('bus_stop_${stop.id}'),
                  position: LatLng(stop.location.latitude, stop.location.longitude),
                ));
              }
            },
          ),
        );
      }

      setState(() {});
    } catch (e) {
      print('Error loading bus stops: $e');
    }
  }

  Future<List<BusStop>> _getBusStopsForRoute(String routeId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('busStops')
          .where('routeIds', arrayContains: routeId)
          .get();

      return querySnapshot.docs
          .map((doc) => BusStop.fromJson({
            'id': doc.id,
            ...doc.data(),
          }, doc.id))
          .toList();
    } catch (e) {
      print('Error getting bus stops for route: $e');
      return [];
    }
  }

  Future<List<BusStop>> _getAllBusStops() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('busStops')
          .where('isActive', isEqualTo: true)
          .limit(100) // Limit to prevent too many markers
          .get();

      return querySnapshot.docs
          .map((doc) => BusStop.fromJson({
            'id': doc.id,
            ...doc.data(),
          }, doc.id))
          .toList();
    } catch (e) {
      print('Error getting all bus stops: $e');
      return [];
    }
  }

  void _startBusTracking() {
    Query query = FirebaseFirestore.instance
        .collection('buses')
        .where('isActive', isEqualTo: true);

    if (widget.filterRouteIds != null && widget.filterRouteIds!.isNotEmpty) {
      query = query.where('routeId', whereIn: widget.filterRouteIds);
    }

    _busLocationSubscription = query.snapshots().listen((snapshot) {
      _updateBusMarkers(snapshot.docs);
    });
  }

  void _updateBusMarkers(List<QueryDocumentSnapshot> busDocs) {
    // Remove existing bus markers
    _markers.removeWhere((marker) => 
        marker.markerId.value.startsWith('bus_'));

    // Add updated bus markers
    for (var doc in busDocs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;
      
      final bus = Bus.fromJson({
        'id': doc.id,
        ...data,
      }, doc.id);
      
      // Only add marker if bus has current location
      if (bus.currentLocation == null) continue;
      
      _markers.add(
        Marker(
          markerId: MarkerId('bus_${bus.id}'),
          position: LatLng(
            bus.currentLocation!.latitude,
            bus.currentLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Bus ${bus.plateNumber}',
            snippet: 'Route: ${bus.routeId}\nCrowd: ${bus.currentCrowd}/${bus.capacity}',
          ),
          rotation: 0.0, // Use default rotation since heading is not available
          onTap: () {
            if (widget.onMarkerTap != null) {
              widget.onMarkerTap!(Marker(
                markerId: MarkerId('bus_${bus.id}'),
                position: LatLng(
                  bus.currentLocation!.latitude,
                  bus.currentLocation!.longitude,
                ),
              ));
            }
          },
        ),
      );
    }

    setState(() {});
  }

  Future<BitmapDescriptor> _createBusStopIcon() async {
    // You can customize this to create a custom bus stop icon
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Set initial camera position if current location is available
    if (_currentLocation != null && widget.initialLocation == null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, widget.initialZoom),
      );
    }

    // Call the provided callback
    if (widget.onMapCreated != null) {
      widget.onMapCreated!(controller);
    }
  }

  void _onCurrentLocationPressed() {
    if (widget.onCurrentLocationPressed != null) {
      widget.onCurrentLocationPressed!();
    } else {
      _moveToCurrentLocation();
    }
  }

  Future<void> _moveToCurrentLocation() async {
    if (_currentLocation != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 16.0),
      );
    } else {
      // Try to get current location if not available
      await _getCurrentLocation();
      if (_currentLocation != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 16.0),
        );
      }
    }
  }

  void _toggleTraffic() {
    setState(() {
      _showTraffic = !_showTraffic;
    });
  }

  LatLng get _initialCameraPosition {
    if (widget.initialLocation != null) {
      return widget.initialLocation!;
    } else if (_currentLocation != null) {
      return _currentLocation!;
    } else {
      // Default to Colombo, Sri Lanka (you can change this to your default location)
      return const LatLng(6.9271, 79.8612);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialCameraPosition,
          zoom: widget.initialZoom,
        ),
        markers: _markers,
        polylines: _polylines,
        circles: _circles,
        onTap: widget.onMapTap,
        myLocationEnabled: widget.showUserLocation,
        myLocationButtonEnabled: false, // We'll use our custom button
        trafficEnabled: _showTraffic,
        buildingsEnabled: true,
        compassEnabled: true,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        rotateGesturesEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        tiltGesturesEnabled: true,
        mapType: MapType.normal,
      ),
      floatingActionButton: widget.enableCurrentLocation
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Traffic toggle button
                FloatingActionButton(
                  heroTag: "traffic",
                  mini: true,
                  onPressed: _toggleTraffic,
                  backgroundColor: _showTraffic ? Colors.green : Colors.grey,
                  child: Icon(
                    Icons.traffic,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Current location button
                FloatingActionButton(
                  heroTag: "location",
                  onPressed: _onCurrentLocationPressed,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}