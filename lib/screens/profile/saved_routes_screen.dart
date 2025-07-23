import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bus_route_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/route_provider.dart';
import '../../config/app_theme.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  bool _isLoading = true;
  List<BusRoute> _savedRoutes = [];

  @override
  void initState() {
    super.initState();
    _loadSavedRoutes();
  }

  Future<void> _loadSavedRoutes() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadSavedRoutes();
      setState(() {
        _savedRoutes = userProvider.savedRoutes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load saved routes');
    }
  }

  Future<void> _deleteRoute(String routeId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.deleteSavedRoute(routeId);
      setState(() {
        _savedRoutes.removeWhere((route) => route.id == routeId);
      });
      _showSuccessSnackBar('Route removed successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to remove route');
    }
  }

  Future<void> _useRoute(BusRoute route) async {
    try {
      final routeProvider = Provider.of<RouteProvider>(context, listen: false);
      routeProvider.selectRoute(route);
      if (mounted) {
        // Using GoRouter navigation instead of Navigator.pushNamed
        // Navigator.pushNamed(context, '/route-tracking', arguments: route);

        // For now, just show a message that navigation is not implemented
        _showSuccessSnackBar('Route selected! Navigation feature coming soon.');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start route navigation');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSavedRouteCard(BusRoute route) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _useRoute(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.routeName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${route.stops.first.stopName} → ${route.stops.last.stopName}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'use') {
                        _useRoute(route);
                      } else if (value == 'delete') {
                        _showDeleteDialog(route);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'use',
                        child: Row(
                          children: [
                            Icon(Icons.navigation_outlined),
                            SizedBox(width: 12),
                            Text('Use Route'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.access_time_outlined,
                    label: '${route.estimatedDuration.inMinutes} min',
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.directions_bus_outlined,
                    label: '${route.stops.length} stops',
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.currency_rupee,
                    label: '${route.baseFare.toStringAsFixed(0)}',
                    color: AppTheme.accentColor.withOpacity(0.1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BusRoute route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete "${route.routeName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteRoute(route.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Routes',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your frequently used routes for quick access',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Using GoRouter navigation instead of Navigator.pushNamed
              // Navigator.pushNamed(context, '/routes');

              // For now, just show a message
              _showSuccessSnackBar('Route search feature coming soon!');
            },
            icon: const Icon(Icons.search),
            label: const Text('Find Routes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Routes'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_savedRoutes.isNotEmpty)
            IconButton(
              onPressed: _loadSavedRoutes,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedRoutes.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadSavedRoutes,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _savedRoutes.length,
                itemBuilder: (context, index) {
                  return _buildSavedRouteCard(_savedRoutes[index]);
                },
              ),
            ),
    );
  }
}
