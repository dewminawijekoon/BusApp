import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as material show TimeOfDay;
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../../models/bus_route_model.dart';
import '../../models/bus_stop_model.dart';
import '../../providers/route_provider.dart';
import '../../widgets/route/route_result_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart' as custom;
import '../../config/app_theme.dart';

class RouteResultsScreen extends StatefulWidget {
  final BusStop startStop;
  final BusStop endStop;
  final DateTime? travelDateTime;

  const RouteResultsScreen({
    super.key,
    required this.startStop,
    required this.endStop,
    this.travelDateTime,
  });

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  String _sortBy = 'fastest'; // fastest, cheapest, least_transfers
  bool _showOnlyDirect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchRoutes();
    });
  }

  void _searchRoutes() {
    context.read<RouteProvider>().searchRoutes(
      startStop: widget.startStop,
      endStop: widget.endStop,
      departureTime: widget.travelDateTime,
    );
  }

  void _selectRoute(BusRoute route) {
    context.read<RouteProvider>().selectRoute(route);
    context.go('/route-details', extra: {'route': route});
  }

  void _saveRoute(BusRoute route) {
    context.read<RouteProvider>().saveRoute(route);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Route saved successfully'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort by',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSortChip('Fastest', 'fastest', Symbols.speed),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSortChip('Cheapest', 'cheapest', Symbols.attach_money),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSortChip('Less Transfers', 'least_transfers', Symbols.transfer_within_a_station),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _showOnlyDirect,
                onChanged: (value) {
                  setState(() {
                    _showOnlyDirect = value ?? false;
                  });
                  _searchRoutes();
                },
                activeColor: AppTheme.primaryColor,
              ),
              Text(
                'Direct routes only',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = value;
          });
          _searchRoutes();
        }
      },
      selectedColor: AppTheme.primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.primaryColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildRoutesList(List<BusRoute> routes) {
    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.directions_bus_filled,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No routes found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _searchRoutes,
              icon: const Icon(Symbols.refresh),
              label: const Text('Search Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final route = routes[index];
        return RouteResultCard(
          route: route,
          onTap: () => _selectRoute(route),
          onSave: () => _saveRoute(route),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.trip_origin,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.startStop.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: Column(
              children: List.generate(
                3,
                (index) => Container(
                  width: 2,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                Symbols.location_on,
                color: AppTheme.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.endStop.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          if (widget.travelDateTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Symbols.schedule,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Travel time: ${_formatDateTime(widget.travelDateTime!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    final timeOfDay = material.TimeOfDay.fromDateTime(dateTime);
    
    if (difference == 0) {
      return 'Today at ${timeOfDay.format(context)}';
    } else if (difference == 1) {
      return 'Tomorrow at ${timeOfDay.format(context)}';
    } else {
      return '${dateTime.day}/${dateTime.month} at ${timeOfDay.format(context)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Route Options'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _searchRoutes,
            icon: const Icon(Symbols.refresh),
            tooltip: 'Refresh results',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSortOptions(),
          Expanded(
            child: Consumer<RouteProvider>(
              builder: (context, routeProvider, child) {
                if (routeProvider.isLoading) {
                  return const LoadingWidget(message: 'Finding best routes...');
                }

                if (routeProvider.error != null) {
                  return custom.ErrorWidget(
                    message: routeProvider.error!,
                    onRetry: _searchRoutes,
                  );
                }

                return _buildRoutesList(routeProvider.searchResults);
              },
            ),
          ),
        ],
      ),
    );
  }
}