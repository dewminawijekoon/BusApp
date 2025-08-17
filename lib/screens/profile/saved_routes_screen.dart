import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/bus_route_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/route_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.12),
          width: 1,
        ),
      ),
      color: colorScheme.surface,
      child: InkWell(
        onTap: () => _useRoute(route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${route.stops.first.stopName} → ${route.stops.last.stopName}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
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
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'use',
                        child: Row(
                          children: [
                            Icon(Icons.navigation_outlined, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            Text('Use Route', style: TextStyle(color: colorScheme.onSurface)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: colorScheme.error),
                            const SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: colorScheme.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.access_time_outlined,
                    label: '${route.estimatedDuration.inMinutes} min',
                    color: colorScheme.primary.withOpacity(0.1),
                    textColor: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.directions_bus_outlined,
                    label: '${route.stops.length} stops',
                    color: colorScheme.secondary.withOpacity(0.1),
                    textColor: colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.currency_rupee,
                    label: '${route.baseFare.toStringAsFixed(0)}',
                    color: colorScheme.tertiary.withOpacity(0.1),
                    textColor: colorScheme.tertiary,
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
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BusRoute route) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Route',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${route.routeName}"?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface.withOpacity(0.7),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteRoute(route.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_outlined,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Saved Routes',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save your frequently used routes for quick access',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.go(AppRoutes.routesPage);
              },
              icon: const Icon(Icons.search),
              label: const Text('Find Routes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Routes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.routesPage),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Routes',
        ),
        actions: [
          if (_savedRoutes.isNotEmpty)
            IconButton(
              onPressed: _loadSavedRoutes,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : _savedRoutes.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: colorScheme.primary,
              onRefresh: _loadSavedRoutes,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _savedRoutes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSavedRouteCard(_savedRoutes[index]),
                  );
                },
              ),
            ),
    );
  }
}
