import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bus_stop_model.dart';
import '../../config/app_theme.dart';

class RouteSearchBar extends StatefulWidget {
  final BusStop? startStop;
  final BusStop? endStop;
  final DateTime? travelDateTime;
  final Function(BusStop? start, BusStop? end, DateTime? dateTime)? onSearch;
  final VoidCallback? onSwapLocations;

  const RouteSearchBar({
    super.key,
    this.startStop,
    this.endStop,
    this.travelDateTime,
    this.onSearch,
    this.onSwapLocations,
  });

  @override
  State<RouteSearchBar> createState() => _RouteSearchBarState();
}

class _RouteSearchBarState extends State<RouteSearchBar> {
  late TextEditingController _startController;
  late TextEditingController _endController;
  BusStop? _selectedStart;
  BusStop? _selectedEnd;
  DateTime? _selectedDateTime;
  bool _isStartFocused = false;
  bool _isEndFocused = false;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(text: widget.startStop?.name ?? '');
    _endController = TextEditingController(text: widget.endStop?.name ?? '');
    _selectedStart = widget.startStop;
    _selectedEnd = widget.endStop;
    _selectedDateTime = widget.travelDateTime;
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _showLocationPicker(bool isStart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationPickerBottomSheet(
        isStart: isStart,
        onLocationSelected: (busStop) {
          setState(() {
            if (isStart) {
              _selectedStart = busStop;
              _startController.text = busStop.name;
            } else {
              _selectedEnd = busStop;
              _endController.text = busStop.name;
            }
          });
          _triggerSearch();
        },
      ),
    );
  }

  void _showDateTimePicker() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && mounted) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppTheme.primaryColor,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
        _triggerSearch();
      }
    }
  }

  void _swapLocations() {
    setState(() {
      final tempStart = _selectedStart;
      final tempStartText = _startController.text;
      
      _selectedStart = _selectedEnd;
      _startController.text = _endController.text;
      
      _selectedEnd = tempStart;
      _endController.text = tempStartText;
    });
    
    widget.onSwapLocations?.call();
    _triggerSearch();
  }

  void _triggerSearch() {
    if (_selectedStart != null && _selectedEnd != null) {
      widget.onSearch?.call(_selectedStart, _selectedEnd, _selectedDateTime);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today, ${TimeOfDay.fromDateTime(dateTime).format(context)}';
    } else if (difference == 1) {
      return 'Tomorrow, ${TimeOfDay.fromDateTime(dateTime).format(context)}';
    } else {
      return '${dateTime.day}/${dateTime.month}, ${TimeOfDay.fromDateTime(dateTime).format(context)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // From/To inputs
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildLocationInput(
                      controller: _startController,
                      hint: 'From',
                      icon: Icons.trip_origin,
                      iconColor: AppTheme.primaryColor,
                      isStart: true,
                      isFocused: _isStartFocused,
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.grey[200],
                    ),
                    _buildLocationInput(
                      controller: _endController,
                      hint: 'To',
                      icon: Icons.location_on,
                      iconColor: AppTheme.secondaryColor,
                      isStart: false,
                      isFocused: _isEndFocused,
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _swapLocations,
                  icon: const Icon(Icons.swap_vert),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.backgroundColor,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  tooltip: 'Swap locations',
                ),
              ),
            ],
          ),
          
          // Date/Time picker
          InkWell(
            onTap: _showDateTimePicker,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDateTime != null
                          ? _formatDateTime(_selectedDateTime!)
                          : 'Leave now',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _selectedDateTime != null
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: _selectedDateTime != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isStart,
    required bool isFocused,
  }) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          if (isStart) {
            _isStartFocused = hasFocus;
          } else {
            _isEndFocused = hasFocus;
          }
        });
      },
      child: TextFormField(
        controller: controller,
        onTap: () => _showLocationPicker(isStart),
        readOnly: true,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      controller.clear();
                      if (isStart) {
                        _selectedStart = null;
                      } else {
                        _selectedEnd = null;
                      }
                    });
                  },
                  icon: const Icon(Icons.close, size: 16),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.grey[400],
                  ),
                )
              : null,
        ),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _LocationPickerBottomSheet extends StatefulWidget {
  final bool isStart;
  final Function(BusStop) onLocationSelected;

  const _LocationPickerBottomSheet({
    required this.isStart,
    required this.onLocationSelected,
  });

  @override
  State<_LocationPickerBottomSheet> createState() =>
      _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState
    extends State<_LocationPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<BusStop> _searchResults = [];
  List<BusStop> _recentStops = [];
  List<BusStop> _nearbyStops = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    // TODO: Load recent and nearby bus stops
    // This would typically fetch from local storage and location service
    setState(() {
      _recentStops = _getDummyBusStops().take(3).toList();
      _nearbyStops = _getDummyBusStops().skip(3).take(5).toList();
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement actual search using maps service
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchResults = _getDummyBusStops()
              .where((stop) =>
                  stop.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
          _isLoading = false;
        });
      }
    });
  }

  List<BusStop> _getDummyBusStops() {
    // TODO: Replace with actual bus stops data
    final now = DateTime.now();
    return [
      BusStop(
        id: '1',
        name: 'Fort Railway Station',
        address: 'Fort, Colombo 01',
        location: const GeoPoint(6.9344, 79.8428),
        routeIds: const ['1', '2', '3'],
        createdAt: now,
        updatedAt: now,
      ),
      BusStop(
        id: '2',
        name: 'Pettah Bus Station',
        address: 'Pettah, Colombo 11',
        location: const GeoPoint(6.9355, 79.8500),
        routeIds: const ['4', '5', '6'],
        createdAt: now,
        updatedAt: now,
      ),
      BusStop(
        id: '3',
        name: 'Colombo General Hospital',
        address: 'Regent Street, Colombo 08',
        location: const GeoPoint(6.9271, 79.8612),
        routeIds: const ['7', '8', '9'],
        createdAt: now,
        updatedAt: now,
      ),
      BusStop(
        id: '4',
        name: 'University of Colombo',
        address: 'College House, Colombo 03',
        location: const GeoPoint(6.9022, 79.8607),
        routeIds: const ['10', '11'],
        createdAt: now,
        updatedAt: now,
      ),
      BusStop(
        id: '5',
        name: 'Bambalapitiya Junction',
        address: 'Galle Road, Colombo 04',
        location: const GeoPoint(6.8769, 79.8554),
        routeIds: const ['12', '13', '14'],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No bus stops found'),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        if (_searchController.text.isEmpty && _recentStops.isNotEmpty) ...[
          _buildSectionHeader('Recent'),
          ..._recentStops.map((stop) => _buildStopTile(stop, isRecent: true)),
          const SizedBox(height: 16),
        ],
        if (_searchController.text.isEmpty && _nearbyStops.isNotEmpty) ...[
          _buildSectionHeader('Nearby'),
          ..._nearbyStops.map((stop) => _buildStopTile(stop, isNearby: true)),
        ],
        if (_searchController.text.isNotEmpty) ...[
          _buildSectionHeader('Search Results'),
          ..._searchResults.map((stop) => _buildStopTile(stop)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildStopTile(BusStop stop, {bool isRecent = false, bool isNearby = false}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isRecent
              ? AppTheme.primaryColor.withOpacity(0.1)
              : isNearby
                  ? AppTheme.secondaryColor.withOpacity(0.1)
                  : AppTheme.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isRecent
              ? Icons.history
              : isNearby
                  ? Icons.near_me
                  : Icons.directions_bus,
          color: isRecent
              ? AppTheme.primaryColor
              : isNearby
                  ? AppTheme.secondaryColor
                  : AppTheme.accentColor,
          size: 20,
        ),
      ),
      title: Text(
        stop.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        '${stop.routeIds.length} routes available',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
      ),
      onTap: () {
        widget.onLocationSelected(stop);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.isStart ? 'Select starting point' : 'Select destination',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search bus stops...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ),

          // Results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }
}