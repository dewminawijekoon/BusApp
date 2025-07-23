import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  // Authentication Routes
  static const String login = '/login';
  static const String register = '/register';
  
  // Main Navigation Routes
  static const String home = '/';
  static const String routesPage = '/routes';
  static const String alerts = '/alerts';
  static const String account = '/account';
  
  // Route Management Routes
  static const String routeResults = '/route-results';
  static const String routeDetails = '/route-details';
  static const String routeTracking = '/route-tracking';
  
  // Profile & Settings Routes
  static const String savedRoutes = '/saved-routes';
  static const String points = '/points';
  static const String helpSupport = '/help-support';
  static const String settings = '/settings';

  // GoRouter navigation helpers
  static void goToLogin(BuildContext context) {
    context.go(login);
  }
  
  static void goToRegister(BuildContext context) {
    context.go(register);
  }
  
  static void goToHome(BuildContext context) {
    context.go(home);
  }
  
  static void goToRoutes(BuildContext context) {
    context.go(routesPage);
  }
  
  static void goToAlerts(BuildContext context) {
    context.go(alerts);
  }
  
  static void goToAccount(BuildContext context) {
    context.go(account);
  }
  
  static void goToRouteResults(BuildContext context, {
    String? startStop,
    String? endStop,
    DateTime? travelDateTime,
  }) {
    context.go(routeResults, extra: {
      'startStop': startStop,
      'endStop': endStop,
      'travelDateTime': travelDateTime,
    });
  }
  
  static void goToRouteDetails(BuildContext context, {
    dynamic route,
  }) {
    context.go(routeDetails, extra: {
      'route': route,
    });
  }
  
  // Helper method to check if route exists
  static bool hasRoute(String routeName) {
    const allRoutes = [
      login, register, home, routesPage, alerts, account,
      routeResults, routeDetails, routeTracking,
      savedRoutes, points, helpSupport, settings,
    ];
    return allRoutes.contains(routeName);
  }
  
  // Backward compatibility for any remaining traditional navigation
  @Deprecated('Use GoRouter navigation helpers instead. This will be removed in future versions.')
  static Map<String, WidgetBuilder> get routes => {};
}