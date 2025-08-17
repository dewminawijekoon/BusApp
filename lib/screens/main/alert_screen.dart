import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({Key? key}) : super(key: key);

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  AlertType _mapType(String? t) {
    switch (t) {
      case 'delay':
        return AlertType.delay;
      case 'warning':
        return AlertType.warning;
      default:
        return AlertType.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Updates'),
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing alerts...')),
              );
              // Firestore stream auto-refreshes; this is just UX feedback.
            },
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
            children: [
              const SizedBox(height: 12),

              // ✅ NEW: Live alerts from Firestore appear at the top
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('alerts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Keep layout stable while loading
                    return const SizedBox.shrink();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    // No dynamic alerts yet -> nothing to render here
                    return const SizedBox.shrink();
                  }

                  final docs = snapshot.data!.docs;

                  return Column(
                    children: [
                      // Optional spacing to separate dynamic & static sections
                      for (final doc in docs) ...[
                        _buildAlertCard(
                          title:
                              "Route ${(doc.data() as Map<String, dynamic>)['route'] ?? '-'} • ${(doc.data() as Map<String, dynamic>)['halt'] ?? '-'}",
                          message:
                              "Crowd: ${(doc.data() as Map<String, dynamic>)['crowd'] ?? '-'} | "
                              "Status: ${(doc.data() as Map<String, dynamic>)['status'] ?? '-'} | "
                              "ETA: ${(doc.data() as Map<String, dynamic>)['etaMins'] ?? 0} mins",
                          type: _mapType(
                            (doc.data() as Map<String, dynamic>)['type']
                                as String?,
                          ),
                          timestamp:
                              ((doc.data() as Map<String, dynamic>)['createdAt']
                                      as Timestamp?)
                                  ?.toDate() ??
                              DateTime.now(),
                          context: context,
                        ),
                        const SizedBox(height: 12),
                      ],
                      const Divider(height: 32),
                    ],
                  );
                },
              ),

              // 🔷 Your original static messages (unchanged)
              _buildAlertCard(
                title: 'Level Up! 🎉',
                message:
                    'Congratulations! You have been upgraded to Silver Level from Bronze. Enjoy enhanced benefits and rewards!',
                type: AlertType.info,
                timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
                context: context,
              ),
              _buildAlertCard(
                title: 'Bus Delay Notice 🚌⏳',
                message:
                    'The Colombo → Maharagama bus is running late by approximately 5 minutes. Please plan accordingly.',
                type: AlertType.warning,
                timestamp: DateTime.now(),
                context: context,
              ),
              const SizedBox(height: 12),
              _buildAlertCard(
                title: 'Lost Item Found',
                message:
                    'A blue backpack was found on bus route 156. If this belongs to you, please contact the Central Station lost and found office.',
                type: AlertType.info,
                timestamp: DateTime.now().subtract(const Duration(hours: 1)),
                context: context,
              ),
              const SizedBox(height: 12),
              _buildAlertCard(
                title: 'Found Item Claimed',
                message:
                    'A wallet found on bus 203 has been successfully returned to its owner. Thank you for using our lost and found service!',
                type: AlertType.info,
                timestamp: DateTime.now().subtract(const Duration(hours: 3)),
                context: context,
              ),
              _buildAlertCard(
                title: 'Route 138 Delay',
                message:
                    'Bus route 138 is experiencing delays due to heavy traffic at Colombo Road.',
                type: AlertType.delay,
                timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
                context: context,
              ),
              const SizedBox(height: 12),
              _buildAlertCard(
                title: 'Service Update',
                message:
                    'New express bus service starting from Central Station to Airport from tomorrow.',
                type: AlertType.info,
                timestamp: DateTime.now().subtract(const Duration(hours: 2)),
                context: context,
              ),
              const SizedBox(height: 12),
              _buildAlertCard(
                title: 'Weather Warning',
                message:
                    'Heavy rain expected. Some routes may experience delays.',
                type: AlertType.warning,
                timestamp: DateTime.now().subtract(const Duration(hours: 4)),
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String message,
    required AlertType type,
    required DateTime timestamp,
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _getAlertIcon(type, context),
        title: Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy hh:mm a').format(timestamp),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _getAlertIcon(AlertType type, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color backgroundColor;

    switch (type) {
      case AlertType.delay:
        icon = Icons.timer;
        backgroundColor = colorScheme.errorContainer;
        break;
      case AlertType.warning:
        icon = Icons.warning;
        backgroundColor = colorScheme.error;
        break;
      case AlertType.info:
        icon = Icons.info;
        backgroundColor = colorScheme.primary;
        break;
    }

    return CircleAvatar(
      backgroundColor: backgroundColor,
      child: Icon(icon, color: colorScheme.onPrimary, size: 20),
    );
  }
}

enum AlertType { delay, warning, info }
