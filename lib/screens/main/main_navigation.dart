import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;

  const MainNavigation({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Symbols.home,
      label: 'Home',
      route: '/',
    ),
    NavigationItem(
      icon: Symbols.route,
      label: 'Routes',
      route: '/routes',
    ),
    NavigationItem(
      icon: Symbols.notifications,
      label: 'Alerts',
      route: '/alerts',
    ),
    NavigationItem(
      icon: Symbols.account_circle,
      label: 'Account',
      route: '/account',
    ),
  ];

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    if (index < 0 || index >= _navigationItems.length) return;

    setState(() {
      _currentIndex = index;
    });

    context.go(_navigationItems[index].route);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    try {
      final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
      for (int i = 0; i < _navigationItems.length; i++) {
        if (location.startsWith(_navigationItems[i].route)) {
          if (_currentIndex != i) {
            setState(() {
              _currentIndex = i;
            });
          }
          break;
        }
      }
    } catch (e) {
      // Fallback: keep current index if unable to determine location
      debugPrint('Error updating navigation index: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          indicatorColor: colorScheme.secondaryContainer,
          height: 80,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 300),
          destinations: _navigationItems.map((item) {
            return NavigationDestination(
              icon: Icon(
                item.icon,
                size: 24,
              ),
              selectedIcon: Icon(
                item.icon,
                size: 24,
                weight: 600,
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}