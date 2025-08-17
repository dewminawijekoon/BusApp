import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as material show TimeOfDay;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import 'onboard_screen.dart';
import '../../models/bus_route_model.dart';
import '../../models/bus_stop_model.dart';
import '../../providers/route_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/route/route_result_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../config/app_routes.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({Key? key}) : super(key: key);

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  bool _isSearchExpanded = false;

  // Google Map vars
  GoogleMapController? mapController;
  BitmapDescriptor? busIcon;
  LatLng _busLocation = const LatLng(6.9271, 79.9931);
  bool _showMap = false;
  bool _isMapExpanded = false;

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(6.9271, 79.9931),
    zoom: 14.0,
  );

  // 🔵 Route drawing state
  final Set<Polyline> _polylines = {};
  final Set<Marker> _routeMarkers = {};
  final PolylinePoints _polylineDecoder = PolylinePoints();
  static const String _googleApiKey = 'AIzaSyAiR1opo-AoCsZ0vhXkZZ3lQU65uJWgneI';

  // Search controllers
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  DateTime? _selectedDate;
  material.TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDate = DateTime.now();
    _selectedTime = material.TimeOfDay.now();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      busIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/bus_icon.png',
      );
    } catch (e) {
      debugPrint('Error loading bus icon: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // 🔵 Helper: clear previous route
  void _clearRoute() {
    _polylines.clear();
    _routeMarkers.clear();
    setState(() {});
  }

  // 🔵 Helper: fit camera to all given points
  Future<void> _fitCameraToBounds(List<LatLng> points) async {
    if (mapController == null || points.isEmpty) return;
    double x0 = points.first.latitude, x1 = points.first.latitude;
    double y0 = points.first.longitude, y1 = points.first.longitude;
    for (final p in points) {
      if (p.latitude > x1) x1 = p.latitude;
      if (p.latitude < x0) x0 = p.latitude;
      if (p.longitude > y1) y1 = p.longitude;
      if (p.longitude < y0) y0 = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  // 🔵 1) Turn "from" and "to" text into coordinates (geocoding)
  Future<LatLng?> _geocode(String address) async {
    try {
      if (address.trim().toLowerCase() == 'current location') {
        final lp = context.read<LocationProvider>();
        final pos = await lp.getCurrentLocation();
        if (pos == null) return null;
        return LatLng(pos.latitude, pos.longitude);
      }
      final results = await geocoding.locationFromAddress(address);
      if (results.isEmpty) return null;
      final r = results.first;
      return LatLng(r.latitude, r.longitude);
    } catch (e) {
      return null;
    }
  }

  // 🔵 2) Fetch route from Google Directions API and draw purple polyline (as shown)
  Future<void> _drawRoute(LatLng start, LatLng end) async {
    try {
      // Clear any existing route first
      _clearRoute();

      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=driving&units=metric&alternatives=false&key=$_googleApiKey';

      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        throw 'Directions API failed (${resp.statusCode})';
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final routes = (data['routes'] as List?) ?? [];
      if (routes.isEmpty) {
        throw 'No route found between the two points';
      }

      // Use the first route
      final overview = routes.first['overview_polyline']?['points'] as String?;
      if (overview == null) {
        throw 'No overview polyline returned';
      }

      final decoded = _polylineDecoder.decodePolyline(
        overview,
      ); // List<PointLatLng>
      final points = decoded
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(growable: false);

      // Add start/end markers
      _routeMarkers.addAll({
        Marker(
          markerId: const MarkerId('start'),
          position: start,
          infoWindow: const InfoWindow(title: 'Start'),
        ),
        Marker(
          markerId: const MarkerId('end'),
          position: end,
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      });

      // Add purple polyline
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_polyline'),
          width: 6,
          jointType: JointType.round,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
          geodesic: true,
          color: const Color.fromARGB(
            255,
            0,
            41,
            190,
          ), // 🔵 Purple route to match your style
          points: points,
        ),
      );

      setState(() {}); // refresh markers & polylines
      await _fitCameraToBounds(points);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not draw route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ⬇️ Your existing search now geocodes + draws the route
  void _handleSearch() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both pickup and destination locations'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final DateTime searchDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final routeProvider = context.read<RouteProvider>();

    final now = DateTime.now();
    final startStop = BusStop(
      id: 'start_${_fromController.text.hashCode}',
      name: _fromController.text,
      location: const GeoPoint(0.0, 0.0),
      address: _fromController.text,
      createdAt: now,
      updatedAt: now,
    );

    final endStop = BusStop(
      id: 'end_${_toController.text.hashCode}',
      name: _toController.text,
      location: const GeoPoint(0.0, 0.0),
      address: _toController.text,
      createdAt: now,
      updatedAt: now,
    );

    await routeProvider.searchRoutes(
      startStop: startStop,
      endStop: endStop,
      departureTime: searchDateTime,
    );

    // 🔵 Geocode & draw the route
    final startLatLng = await _geocode(_fromController.text);
    final endLatLng = await _geocode(_toController.text);

    if (startLatLng == null || endLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find coordinates for the given addresses'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      await _drawRoute(startLatLng, endLatLng);
    }

    setState(() {
      _showMap = true;
    });

    _tabController.animateTo(0);
  }

  void _swapLocations() {
    final temp = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = temp;
  }

  void _useCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();
    try {
      final position = await locationProvider.getCurrentLocation();
      if (position != null) {
        _fromController.text = "Current Location";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get current location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          _buildSearchHeader(theme),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchResults(),
                _buildPopularRoutes(),
                _buildSavedRoutes(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFromField(theme),
                  _buildSwapDivider(theme),
                  _buildToField(theme),
                  const SizedBox(height: 16),
                  _buildSearchButton(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSearchExpanded = !_isSearchExpanded;
                      });
                    },
                    icon: Icon(
                      _isSearchExpanded
                          ? Symbols.expand_less
                          : Symbols.expand_more,
                      size: 16,
                    ),
                    label: Text(
                      _isSearchExpanded ? 'Less options' : 'More options',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Search Results'),
              Tab(text: 'Popular Routes'),
              Tab(text: 'Saved Routes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFromField(ThemeData theme) => Row(
    children: [
      Icon(Symbols.trip_origin, color: theme.colorScheme.primary, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: _fromController,
          decoration: InputDecoration(
            hintText: 'From where?',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
      IconButton(
        onPressed: _useCurrentLocation,
        icon: const Icon(Symbols.my_location),
        iconSize: 20,
      ),
    ],
  );

  Widget _buildSwapDivider(ThemeData theme) => Row(
    children: [
      const SizedBox(width: 32),
      Expanded(
        child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.2)),
      ),
      IconButton(
        onPressed: _swapLocations,
        icon: const Icon(Symbols.swap_vert),
        iconSize: 20,
      ),
      Expanded(
        child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.2)),
      ),
    ],
  );

  Widget _buildToField(ThemeData theme) => Row(
    children: [
      Icon(Symbols.location_on, color: theme.colorScheme.error, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: _toController,
          decoration: InputDecoration(
            hintText: 'Where to?',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildSearchButton() => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: _handleSearch,
      icon: const Icon(Symbols.search),
      label: const Text('Search Routes'),
    ),
  );

  /// ✅ Modified Search Results to include Google Map
  Widget _buildSearchResults() {
    return Consumer<RouteProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              if (_showMap) _buildGoogleMap(),
              if (provider.isSearching)
                const Center(child: LoadingWidget())
              else if (provider.error != null)
                _buildErrorState(provider)
              else if (provider.searchResults.isEmpty)
                _buildNoRoutesFound()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final route = provider.searchResults[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RouteResultCard(
                        route: route,
                        onTap: () => _navigateToRouteDetails(route),
                        onSave: () => provider.saveRoute(route),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoogleMap() {
    // Merge your dynamic bus marker with route markers
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('busMarker'),
        position: _busLocation,
        icon: busIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(
          title: 'Bus Location',
          snippet: 'Live Tracking',
        ),
      ),
      ..._routeMarkers,
    };

    return GestureDetector(
      onTap: () {
        setState(() {
          _isMapExpanded = !_isMapExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isMapExpanded ? 400 : 200,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            markers: markers,
            polylines: _polylines, // 🔵 show route here
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(RouteProvider provider) {
    return Center(
      child: Column(
        children: [
          Icon(
            Symbols.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('Error', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            provider.error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _handleSearch, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildNoRoutesFound() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const OnBoardScreen(crowdLevel: "Medium", isLate: false),
            ),
          );
        },
        icon: const Icon(Icons.directions_bus),
        label: const Text("On Board"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildPopularRoutes() {
    return Consumer<RouteProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: LoadingWidget());
        }

        if (provider.searchResults.isEmpty) {
          return _buildEmptyState(
            icon: Symbols.trending_up,
            title: 'No Popular Routes',
            subtitle:
                'Popular routes will appear here based on community usage',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.searchResults.length,
          itemBuilder: (context, index) {
            final route = provider.searchResults[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RouteResultCard(
                route: route,
                onTap: () => _navigateToRouteDetails(route),
                onSave: () => provider.saveRoute(route),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedRoutes() {
    return Consumer<RouteProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: LoadingWidget());
        }

        if (provider.savedRoutes.isEmpty) {
          return _buildEmptyState(
            icon: Symbols.bookmark_border,
            title: 'No Saved Routes',
            subtitle: 'Save routes from search results to access them quickly',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.savedRoutes.length,
          itemBuilder: (context, index) {
            final route = provider.savedRoutes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RouteResultCard(
                route: route,
                onTap: () => _navigateToRouteDetails(route),
                onSave: () => provider.removeSavedRoute(route.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? material.TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _navigateToRouteDetails(BusRoute route) {
    context.go(AppRoutes.routeDetails, extra: {'route': route});
  }
}
