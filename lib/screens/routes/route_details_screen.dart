import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:math' as math;
import '../../models/bus_route_model.dart';

class RouteDetailsScreen extends StatefulWidget {
  final BusRoute route;

  const RouteDetailsScreen({
    Key? key,
    required this.route,
  }) : super(key: key);

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late TabController _tabController;
  bool _isRouteBookmarked = false;
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeMapData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeMapData() {
    // Initialize markers for bus stops
    for (int i = 0; i < widget.route.stops.length; i++) {
      final stop = widget.route.stops[i];
      _markers.add(
        Marker(
          markerId: MarkerId(stop.stopId),
          position: LatLng(stop.location.latitude, stop.location.longitude),
          infoWindow: InfoWindow(
            title: stop.stopName,
            snippet: 'Stop ${i + 1}',
          ),
          icon: i == 0
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : i == widget.route.stops.length - 1
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Create polyline for the route
    final List<LatLng> routePoints = widget.route.stops
        .map((stop) => LatLng(stop.location.latitude, stop.location.longitude))
        .toList();

    _polylines.add(
      Polyline(
        polylineId: PolylineId(widget.route.id),
        points: routePoints,
        color: Theme.of(context).colorScheme.primary,
        width: 4,
        patterns: [],
      ),
    );
  }

  void _toggleBookmark() {
    setState(() {
      _isRouteBookmarked = !_isRouteBookmarked;
    });
    // TODO: Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRouteBookmarked 
            ? 'Route saved to bookmarks' 
            : 'Route removed from bookmarks'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startTracking() {
    // TODO: Navigate to route tracking screen - for now just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route tracking feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // When route tracking is implemented:
    // context.go('/route-tracking', extra: {'route': widget.route});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.route.routeName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _toggleBookmark,
            icon: Icon(
              _isRouteBookmarked ? Symbols.bookmark : Symbols.bookmark_add,
              fill: _isRouteBookmarked ? 1 : 0,
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Share route functionality
            },
            icon: const Icon(Symbols.share),
          ),
        ],
      ),
      body: Column(
        children: [
          // Route Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.route.routeNumber,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.route.routeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Symbols.schedule,
                      label: '${widget.route.estimatedDuration.inMinutes} min',
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Symbols.route,
                      label: '${_calculateDistance().toStringAsFixed(1)} km',
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Symbols.currency_rupee,
                      label: '₹${widget.route.baseFare}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Symbols.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.route.stops.isNotEmpty ? widget.route.stops.first.stopName : 'Start Location',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Symbols.flag,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.route.stops.isNotEmpty ? widget.route.stops.last.stopName : 'End Location',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Map'),
              Tab(text: 'Stops'),
              Tab(text: 'Schedule'),
            ],
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapView(),
                _buildStopsView(),
                _buildScheduleView(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _startTracking,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.navigation),
              SizedBox(width: 8),
              Text(
                'Start Navigation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(
            widget.route.stops.first.location.latitude,
            widget.route.stops.first.location.longitude,
          ),
          zoom: 12.0,
        ),
        markers: _markers,
        polylines: _polylines,
        mapType: MapType.normal,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: true,
        trafficEnabled: true,
      ),
    );
  }

  Widget _buildStopsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.route.stops.length,
      itemBuilder: (context, index) {
        final stop = widget.route.stops[index];
        final isFirst = index == 0;
        final isLast = index == widget.route.stops.length - 1;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isFirst
                    ? Colors.green.withOpacity(0.2)
                    : isLast
                        ? Colors.red.withOpacity(0.2)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isFirst
                    ? Symbols.trip_origin
                    : isLast
                        ? Symbols.location_on
                        : Symbols.radio_button_unchecked,
                color: isFirst
                    ? Colors.green
                    : isLast
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              stop.stopName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Stop ${index + 1}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Symbols.schedule,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ETA: ${_calculateETA(index)} min',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              onPressed: () {
                _showStopDetails(stop);
              },
              icon: const Icon(Symbols.info),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleView() {
    final schedules = _generateSampleSchedule();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: schedule['isActive'] 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Symbols.directions_bus,
                    color: schedule['isActive'] 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            schedule['departureTime'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (schedule['isActive'])
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bus #${schedule['busNumber']}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Symbols.people,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Capacity: ${schedule['capacity']}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (schedule['isActive'])
                  ElevatedButton(
                    onPressed: () => _startTracking(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Track'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStopDetails(RouteStop stop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stop.stopName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Stop Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sequence: ${stop.sequenceNumber}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (stop.fareFromStart != null) ...[
              const SizedBox(height: 4),
              Text(
                'Fare from start: ₹${stop.fareFromStart!.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to stop on map
                },
                child: const Text('Show on Map'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateETA(int stopIndex) {
    // Simple ETA calculation based on stop index
    final baseETA = stopIndex * 5; // 5 minutes per stop
    return baseETA.toString();
  }

  double _calculateDistance() {
    if (widget.route.stops.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 0; i < widget.route.stops.length - 1; i++) {
      final stop1 = widget.route.stops[i];
      final stop2 = widget.route.stops[i + 1];
      
      // Simple distance calculation using Haversine formula
      const double earthRadius = 6371; // Earth's radius in kilometers
      final double lat1Rad = stop1.location.latitude * (math.pi / 180);
      final double lon1Rad = stop1.location.longitude * (math.pi / 180);
      final double lat2Rad = stop2.location.latitude * (math.pi / 180);
      final double lon2Rad = stop2.location.longitude * (math.pi / 180);
      
      final double deltaLat = lat2Rad - lat1Rad;
      final double deltaLon = lon2Rad - lon1Rad;
      
      final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
          math.cos(lat1Rad) * math.cos(lat2Rad) *
          math.sin(deltaLon / 2) * math.sin(deltaLon / 2);
      final double c = 2 * math.asin(math.sqrt(a));
      
      totalDistance += earthRadius * c;
    }
    
    return totalDistance;
  }

  List<Map<String, dynamic>> _generateSampleSchedule() {
    return [
      {
        'departureTime': '08:30 AM',
        'busNumber': 'TN34K1234',
        'capacity': '42/50',
        'isActive': true,
      },
      {
        'departureTime': '09:00 AM',
        'busNumber': 'TN34K5678',
        'capacity': '38/50',
        'isActive': false,
      },
      {
        'departureTime': '09:30 AM',
        'busNumber': 'TN34K9012',
        'capacity': '45/50',
        'isActive': false,
      },
      {
        'departureTime': '10:00 AM',
        'busNumber': 'TN34K3456',
        'capacity': '28/50',
        'isActive': false,
      },
    ];
  }
}