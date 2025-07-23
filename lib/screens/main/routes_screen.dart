import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as material show TimeOfDay;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bus_route_model.dart';
import '../../models/bus_stop_model.dart';
import '../../providers/route_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/route/route_result_card.dart';
import '../../widgets/common/loading_widget.dart';

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
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: Implement loadPopularRoutes and loadSavedRoutes in RouteProvider
      // context.read<RouteProvider>().loadPopularRoutes();
      // context.read<RouteProvider>().loadSavedRoutes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

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

    // Combine date and time
    final DateTime searchDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Perform search
    final routeProvider = context.read<RouteProvider>();
    
    // Create BusStop objects from the text input
    final now = DateTime.now();
    final startStop = BusStop(
      id: 'start_${_fromController.text.hashCode}',
      name: _fromController.text,
      location: const GeoPoint(0.0, 0.0), // Would need actual coordinates
      address: _fromController.text,
      createdAt: now,
      updatedAt: now,
    );
    
    final endStop = BusStop(
      id: 'end_${_toController.text.hashCode}',
      name: _toController.text,
      location: const GeoPoint(0.0, 0.0), // Would need actual coordinates
      address: _toController.text,
      createdAt: now,
      updatedAt: now,
    );
    
    await routeProvider.searchRoutes(
      startStop: startStop,
      endStop: endStop,
      departureTime: searchDateTime,
    );

    // Switch to search results tab
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
          // Search Header
          Container(
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
                // Main search card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // From field
                        Row(
                          children: [
                            Icon(
                              Symbols.trip_origin,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
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
                        ),
                        
                        // Divider with swap button
                        Row(
                          children: [
                            const SizedBox(width: 32),
                            Expanded(
                              child: Divider(
                                color: theme.colorScheme.onSurface.withOpacity(0.2),
                              ),
                            ),
                            IconButton(
                              onPressed: _swapLocations,
                              icon: const Icon(Symbols.swap_vert),
                              iconSize: 20,
                            ),
                            Expanded(
                              child: Divider(
                                color: theme.colorScheme.onSurface.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                        
                        // To field
                        Row(
                          children: [
                            Icon(
                              Symbols.location_on,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
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
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Date and time selection
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _isSearchExpanded ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectDate(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: theme.colorScheme.outline.withOpacity(0.3),
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Symbols.calendar_today, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              _selectedDate != null
                                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                                  : 'Select Date',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectTime(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: theme.colorScheme.outline.withOpacity(0.3),
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Symbols.schedule, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              _selectedTime != null
                                                  ? _selectedTime!.format(context)
                                                  : 'Select Time',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ) : const SizedBox.shrink(),
                        ),
                        
                        // Search button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _handleSearch,
                            icon: const Icon(Symbols.search),
                            label: const Text('Search Routes'),
                          ),
                        ),
                        
                        // Expand/Collapse button
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
                          label: Text(_isSearchExpanded ? 'Less options' : 'More options'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Tab bar
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
          ),
          
          // Tab content
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

  Widget _buildSearchResults() {
    return Consumer<RouteProvider>(
      builder: (context, provider, child) {
        if (provider.isSearching) {
          return const Center(child: LoadingWidget());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Symbols.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _handleSearch,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Symbols.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No routes found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching for different locations or times',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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

  Widget _buildPopularRoutes() {
    return Consumer<RouteProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: LoadingWidget());
        }

        // For now, show search results as "popular" routes
        if (provider.searchResults.isEmpty) {
          return _buildEmptyState(
            icon: Symbols.trending_up,
            title: 'No Popular Routes',
            subtitle: 'Popular routes will appear here based on community usage',
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
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
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
    // Navigate to route details screen
    Navigator.pushNamed(
      context,
      '/route-details',
      arguments: route,
    );
  }
}