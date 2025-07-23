import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/bus_route_model.dart';
import '../../config/app_theme.dart';

class RouteResultCard extends StatelessWidget {
  final BusRoute route;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const RouteResultCard({
    super.key,
    required this.route,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildRouteInfo(context),
              const SizedBox(height: 12),
              _buildFareInfo(context),
              const SizedBox(height: 12),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getRouteTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getRouteTypeIcon(),
                size: 16,
                color: _getRouteTypeColor(),
              ),
              const SizedBox(width: 4),
              Text(
                _getRouteTypeLabel(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getRouteTypeColor(),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          route.routeNumber,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onSave,
          icon: const Icon(Symbols.bookmark_border),
          iconSize: 20,
          style: IconButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: EdgeInsets.zero,
            minimumSize: const Size(24, 24),
          ),
          tooltip: 'Save route',
        ),
      ],
    );
  }

  Widget _buildRouteInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          route.routeName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (route.description.isNotEmpty) ...[
          Text(
            route.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Icon(
              Symbols.location_on,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${route.stops.length} stops',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            Icon(
              Symbols.schedule,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(route.estimatedDuration),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFareInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.attach_money,
            size: 18,
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Base Fare: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            'Rs. ${route.baseFare.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondaryColor,
                ),
          ),
          const Spacer(),
          if (route.averageRating != null) ...[
            Icon(
              Symbols.star,
              size: 16,
              color: Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              route.averageRating!.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Show route details
              onTap?.call();
            },
            icon: const Icon(Symbols.info, size: 16),
            label: const Text('Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Symbols.navigation, size: 16),
            label: const Text('Select Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getRouteTypeColor() {
    switch (route.type) {
      case RouteType.express:
        return Colors.green;
      case RouteType.regular:
        return AppTheme.primaryColor;
      case RouteType.intercity:
        return Colors.blue;
      case RouteType.shuttle:
        return Colors.orange;
      case RouteType.nightService:
        return Colors.purple;
    }
  }

  IconData _getRouteTypeIcon() {
    switch (route.type) {
      case RouteType.express:
        return Symbols.speed;
      case RouteType.regular:
        return Symbols.directions_bus;
      case RouteType.intercity:
        return Symbols.travel_explore;
      case RouteType.shuttle:
        return Symbols.airport_shuttle;
      case RouteType.nightService:
        return Symbols.nightlight;
    }
  }

  String _getRouteTypeLabel() {
    switch (route.type) {
      case RouteType.express:
        return 'Express';
      case RouteType.regular:
        return 'Regular';
      case RouteType.intercity:
        return 'Intercity';
      case RouteType.shuttle:
        return 'Shuttle';
      case RouteType.nightService:
        return 'Night Service';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}