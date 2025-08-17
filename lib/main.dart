import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
//import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/main/main_navigation.dart';
import 'screens/main/home_screen.dart';
import 'screens/main/routes_screen.dart';
import 'screens/main/account_screen.dart';
import 'screens/profile/saved_routes_screen.dart';
import 'screens/profile/points_screen.dart';
import 'screens/routes/route_results_screen.dart';
import 'screens/routes/route_details_screen.dart';
import 'config/app_theme.dart';
import 'config/app_routes.dart';
import 'providers/auth_provider.dart' as auth;
import 'providers/user_provider.dart';
import 'providers/location_provider.dart';
import 'providers/route_provider.dart';
import 'services/route_service.dart';
import 'services/database_service.dart';
import 'services/firebase_service.dart';
import 'screens/main/alert_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    //options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TransitApp());
}

// GoRouter configuration with auth state listener
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }
}

final GoRouter _router = GoRouter(
  initialLocation: AppRoutes.home,
  refreshListenable: AuthNotifier(),
  routes: [
    // Shell route for main navigation
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigation(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: HomeScreen()),
        ),
        GoRoute(
          path: AppRoutes.routesPage,
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: RoutesScreen()),
        ),
        GoRoute(
          path: AppRoutes.alerts,
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: AlertScreen()),
        ),
        GoRoute(
          path: AppRoutes.account,
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: AccountScreen()),
        ),
      ],
    ),
    // Auth routes (outside shell)
    GoRoute(path: AppRoutes.login, builder: (context, state) => LoginScreen()),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => RegistrationScreen(),
    ),
    // Profile routes (outside shell for full screen experience)
    GoRoute(
      path: AppRoutes.savedRoutes,
      builder: (context, state) => SavedRoutesScreen(),
    ),
    GoRoute(
      path: AppRoutes.points,
      builder: (context, state) => PointsScreen(),
    ),
    GoRoute(
      path: AppRoutes.helpSupport,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text('Help & Support'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.help_outline,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: 16),
                Text(
                  'Help & Support',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'This feature is coming soon!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings, size: 64, color: AppTheme.primaryColor),
                SizedBox(height: 16),
                Text(
                  'App Settings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'This feature is coming soon!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    // Route management routes
    GoRoute(
      path: AppRoutes.routeResults,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return RouteResultsScreen(
          startStop: extra?['startStop'],
          endStop: extra?['endStop'],
          travelDateTime: extra?['travelDateTime'],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.routeDetails,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return RouteDetailsScreen(route: extra?['route']);
      },
    ),
  ],
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isAuthRoute =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register;

    if (kDebugMode) {
      print('GoRouter redirect: location=${state.matchedLocation}, isLoggedIn=$isLoggedIn, user=${user?.uid}');
    }

    // If not logged in and not on auth route, redirect to login
    if (!isLoggedIn && !isAuthRoute) {
      if (kDebugMode) print('Redirecting to login - not authenticated');
      return AppRoutes.login;
    }

    // If logged in and on auth route, redirect to home
    if (isLoggedIn && isAuthRoute) {
      if (kDebugMode) print('Redirecting to home - authenticated on auth route');
      return AppRoutes.home;
    }

    if (kDebugMode) print('No redirect needed');
    return null; // No redirect needed
  },
);

class TransitApp extends StatelessWidget {
  const TransitApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
          create: (_) => RouteProvider(
            routeService: RouteService(),
            databaseService: DatabaseService(),
            firebaseService: FirebaseService(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Transit Tracker',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}

// No need for AuthWrapper - GoRouter handles auth redirect
