# Flutter Public Transportation App - Development Guide

## Project Overview
A comprehensive Flutter application for public transportation with real-time tracking, route planning, and crowd-sourced bus location sharing. Built with Material UI 3, Firebase integration, and Google Maps.

## ⚡ Quick Start
```bash
# 1. Install dependencies
flutter pub get

# 2. Run the application
flutter run
```

## Tech Stack
- **Framework**: Flutter (Latest stable)
- **UI Design**: Material UI 3 with pastel color palette
- **Backend**: Firebase (Auth, Firestore, Cloud Messaging)
- **Maps**: Google Maps API
- **State Management**: Provider/Riverpod
- **Location Services**: Geolocator
- **Push Notifications**: Firebase Cloud Messaging

## Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI & Navigation
  material_symbols_icons: ^4.2719.3
  go_router: ^14.2.7
  
  # State Management
  provider: ^6.1.2
  # OR riverpod: ^2.5.1
  
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  firebase_firestore: ^5.4.3
  firebase_messaging: ^15.1.3
  firebase_analytics: ^11.3.3
  
  # Location & Maps
  google_maps_flutter: ^2.9.0
  geolocator: ^13.0.1
  geocoding: ^3.0.0
  location: ^7.0.0
  
  # HTTP & API
  http: ^1.2.2
  dio: ^5.7.0
  
  # Local Storage
  shared_preferences: ^2.3.2
  sqflite: ^2.3.3+1
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.5.1
  permission_handler: ^11.3.1
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
```

## Project Structure
###Don't consider implemented files. More than 3/4 is created. Check files.
```
lib/
├── config/
│   ├── app_theme.dart                 ✅ Created
│   ├── app_routes.dart               ✅ Created
│   ├── firebase_config.dart          🔄 To Implement
│   └── constants.dart                🔄 To Implement
│
├── models/
│   ├── bus_route.dart                ✅ Created
│   ├── user_model.dart              ✅ Created
│   ├── bus_model.dart               🔄 To Implement
│   ├── bus_stop_model.dart          🔄 To Implement
│   ├── journey_model.dart           🔄 To Implement
│   ├── alert_model.dart             🔄 To Implement
│   └── rating_model.dart            🔄 To Implement
│
├── services/
│   ├── firebase_service.dart         ✅ Created
│   ├── location_service.dart        ✅ Created
│   ├── auth_service.dart            🔄 To Implement
│   ├── route_service.dart           🔄 To Implement
│   ├── notification_service.dart    🔄 To Implement
│   ├── maps_service.dart            🔄 To Implement
│   ├── database_service.dart        🔄 To Implement
│   └── api_service.dart             🔄 To Implement
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart         🔄 To Implement
│   │   └── registration_screen.dart  🔄 To Implement
│   │
│   ├── main/
│   │   ├── main_navigation.dart      ✅ Created
│   │   ├── home_screen.dart         ✅ Created
│   │   ├── routes_screen.dart       ✅ Created
│   │   ├── alerts_screen.dart       🔄 To Implement
│   │   └── account_screen.dart      🔄 To Implement
│   │
│   ├── routes/
│   │   ├── route_results_screen.dart 🔄 To Implement
│   │   ├── route_tracking_screen.dart 🔄 To Implement
│   │   └── route_details_screen.dart 🔄 To Implement
│   │
│   ├── profile/
│   │   ├── saved_routes_screen.dart  🔄 To Implement
│   │   ├── points_screen.dart       🔄 To Implement
│   │   └── help_support_screen.dart 🔄 To Implement
│   │
│   └── common/
│       ├── loading_screen.dart      🔄 To Implement
│       └── error_screen.dart        🔄 To Implement
│
├── widgets/
│   ├── common/
│   │   ├── custom_app_bar.dart      🔄 To Implement
│   │   ├── custom_button.dart       🔄 To Implement
│   │   ├── loading_widget.dart      🔄 To Implement
│   │   └── error_widget.dart        🔄 To Implement
│   │
│   ├── route/
│   │   ├── route_search_bar.dart    🔄 To Implement
│   │   ├── route_result_card.dart   🔄 To Implement
│   │   ├── bus_tracking_card.dart   🔄 To Implement
│   │   └── crowd_level_widget.dart  🔄 To Implement
│   │
│   └── maps/
│       ├── custom_map_widget.dart   🔄 To Implement
│       ├── bus_marker_widget.dart   🔄 To Implement
│       └── route_polyline_widget.dart 🔄 To Implement
│
├── providers/ (or state/)
│   ├── auth_provider.dart           🔄 To Implement
│   ├── location_provider.dart       🔄 To Implement
│   ├── route_provider.dart          🔄 To Implement
│   ├── bus_provider.dart           🔄 To Implement
│   └── user_provider.dart          🔄 To Implement
│
├── utils/
│   ├── validators.dart              🔄 To Implement
│   ├── helpers.dart                🔄 To Implement
│   ├── date_time_utils.dart        🔄 To Implement
│   └── route_calculator.dart       🔄 To Implement
│
└── main.dart                       🔄 To Update
```

## Implementation Roadmap

### Phase 1: Core Setup & Authentication
#### Files to Implement:
1. **config/firebase_config.dart**
   - `initializeFirebase()`
   - `getFirebaseOptions()`

2. **config/constants.dart**
   - API keys, endpoints, app constants

3. **services/auth_service.dart**
   - `signInWithEmail(String email, String password)`
   - `signUpWithEmail(String email, String password, String name)`
   - `signOut()`
   - `getCurrentUser()`
   - `resetPassword(String email)`

4. **screens/auth/login_screen.dart**
   - UI with email/password fields
   - `_handleLogin()`
   - `_navigateToRegister()`
   - Form validation

5. **screens/auth/registration_screen.dart**
   - UI with registration fields
   - `_handleRegistration()`
   - `_navigateToLogin()`
   - Form validation

6. **providers/auth_provider.dart**
   - `signIn(String email, String password)`
   - `signUp(String email, String password, String name)`
   - `signOut()`
   - Authentication state management

### Phase 2: Core Models & Database
#### Files to Implement:
1. **models/bus_model.dart**
   ```dart
   class Bus {
     String id, routeId, plateNumber;
     BusLocation currentLocation;
     int capacity, currentCrowd;
     BusStatus status;
     // fromJson(), toJson(), copyWith()
   }
   ```

2. **models/bus_stop_model.dart**
   ```dart
   class BusStop {
     String id, name;
     GeoPoint location;
     List<String> routeIds;
     // fromJson(), toJson()
   }
   ```

3. **models/journey_model.dart**
   ```dart
   class Journey {
     String id, userId;
     BusStop startStop, endStop;
     DateTime startTime, endTime;
     List<String> busIds;
     JourneyStatus status;
     // fromJson(), toJson()
   }
   ```

4. **services/database_service.dart**
   - `getBusRoutes()`
   - `getBusStops()`
   - `getBusLocation(String busId)`
   - `updateBusLocation(String busId, GeoPoint location)`
   - `saveBusRoute(BusRoute route)`
   - `getUserJourneys(String userId)`

### Phase 3: Location & Maps Integration
#### Files to Implement:
1. **services/maps_service.dart**
   - `getDirections(GeoPoint start, GeoPoint end)`
   - `getNearbyBusStops(GeoPoint location)`
   - `calculateRouteDistance(List<GeoPoint> points)`
   - `getPlaceFromCoordinates(double lat, double lng)`

2. **services/route_service.dart**
   - `findOptimalRoutes(BusStop start, BusStop end)`
   - `calculateETA(String busId, BusStop destination)`
   - `getAlternativeRoutes(BusStop start, BusStop end)`
   - `updateRoutePreferences(String userId, RoutePreference pref)`

3. **widgets/maps/custom_map_widget.dart**
   - Google Maps integration
   - `_buildMap()`
   - `_addMarkers()`
   - `_drawRoute()`

4. **providers/location_provider.dart**
   - `getCurrentLocation()`
   - `startLocationTracking()`
   - `stopLocationTracking()`
   - `getNearestBusStop()`

### Phase 4: Route Planning & Results
#### Files to Implement:
1. **screens/routes/route_results_screen.dart**
   - Display route options
   - `_buildRouteCard(BusRoute route)`
   - `_selectRoute(BusRoute route)`
   - `_showRouteDetails(BusRoute route)`

2. **widgets/route/route_search_bar.dart**
   - Start/destination input
   - Date/time picker
   - `_handleLocationInput()`
   - `_showDateTimePicker()`

3. **widgets/route/route_result_card.dart**
   - Route information display
   - `_buildRouteSteps()`
   - `_buildETAInfo()`
   - `_buildFareInfo()`

4. **providers/route_provider.dart**
   - `searchRoutes(BusStop start, BusStop end)`
   - `selectRoute(BusRoute route)`
   - `saveRoute(BusRoute route)`

### Phase 5: Real-time Tracking
#### Files to Implement:
1. **screens/routes/route_tracking_screen.dart**
   - Real-time bus tracking
   - `_buildTrackingMap()`
   - `_updateBusLocation()`
   - `_toggleBoardingStatus()`
   - `_showCrowdLevelUpdate()`

2. **widgets/route/bus_tracking_card.dart**
   - Bus information display
   - `_buildBusInfo()`
   - `_buildETAWidget()`
   - `_buildCrowdIndicator()`

3. **services/notification_service.dart**
   - `sendGetOffAlert()`
   - `sendBusArrivalAlert()`
   - `scheduleNotification()`
   - `cancelNotification()`

4. **providers/bus_provider.dart**
   - `trackBus(String busId)`
   - `updateCrowdLevel(String busId, int level)`
   - `shareBusLocation(String busId, GeoPoint location)`

### Phase 6: Alerts & Notifications
#### Files to Implement:
1. **screens/main/alerts_screen.dart**
   - Display all alerts
   - `_buildAlertCard(Alert alert)`
   - `_markAsRead(String alertId)`
   - `_clearAllAlerts()`

2. **models/alert_model.dart**
   ```dart
   class Alert {
     String id, userId, message, type;
     DateTime timestamp;
     bool isRead;
     AlertPriority priority;
     // fromJson(), toJson()
   }
   ```

### Phase 7: User Profile & Account
#### Files to Implement:
1. **screens/main/account_screen.dart**
   - User profile interface
   - `_buildProfileHeader()`
   - `_buildMenuOptions()`
   - `_handleSignOut()`

2. **screens/profile/saved_routes_screen.dart**
   - Display saved routes
   - `_buildSavedRouteCard()`
   - `_deleteRoute(String routeId)`
   - `_useRoute(BusRoute route)`

3. **screens/profile/points_screen.dart**
   - Points system display
   - `_buildPointsHistory()`
   - `_buildRewards()`
   - `_claimReward(String rewardId)`

4. **providers/user_provider.dart**
   - `updateUserProfile(UserModel user)`
   - `getSavedRoutes()`
   - `getUserPoints()`
   - `addPoints(int points, String reason)`

### Phase 8: Rating & Feedback
#### Files to Implement:
1. **models/rating_model.dart**
   ```dart
   class Rating {
     String id, userId, busId, journeyId;
     int rating;
     String comment;
     DateTime timestamp;
     // fromJson(), toJson()
   }
   ```

2. **widgets/common/rating_widget.dart**
   - Star rating component
   - `_buildStars()`
   - `_handleRatingChange()`

### Phase 9: Utility Functions
#### Files to Implement:
1. **utils/validators.dart**
   - `validateEmail(String email)`
   - `validatePassword(String password)`
   - `validatePhoneNumber(String phone)`

2. **utils/helpers.dart**
   - `formatDateTime(DateTime dateTime)`
   - `calculateDistance(GeoPoint p1, GeoPoint p2)`
   - `formatDuration(Duration duration)`

3. **utils/route_calculator.dart**
   - `calculateOptimalRoute(List<BusRoute> routes)`
   - `estimateJourneyTime(BusRoute route)`
   - `calculateFare(BusRoute route)`

## Firebase Configuration

### Firestore Collections Structure:
```
users/
  - {userId}/
    - profile data
    - savedRoutes/
    - journeys/
    - points/

busRoutes/
  - {routeId}/
    - route information
    - stops array
    - schedule

buses/
  - {busId}/
    - current location
    - capacity info
    - route assignment

busStops/
  - {stopId}/
    - location
    - connected routes

alerts/
  - {alertId}/
    - user-specific alerts
```

### Security Rules:
- Users can only read/write their own data
- Bus location updates require authentication
- Public read access for routes and stops

## Development Notes

### Key Features to Implement:
1. **Offline Mode**: Cache routes and stops for offline use
2. **Real-time Updates**: Use Firestore listeners for live data
3. **Push Notifications**: FCM integration for alerts
4. **Location Permissions**: Proper permission handling
5. **Error Handling**: Comprehensive error management
6. **Testing**: Unit and widget tests for core functionality

### Performance Considerations:
- Implement pagination for route results
- Use appropriate caching for map tiles
- Optimize Firestore queries with proper indexing
- Implement connection status monitoring

### UI/UX Guidelines:
- Follow Material Design 3 principles
- Use consistent pastel color palette
- Implement proper loading states
- Add haptic feedback for interactions
- Ensure accessibility compliance

## Next Steps
1. Set up Firebase project and configuration
2. Implement authentication flow
3. Create core models and database structure
4. Build route search and results functionality
5. Add real-time tracking capabilities
6. Implement notification system
7. Complete user profile features
8. Add rating and feedback system
9. Perform thorough testing
10. Deploy and monitor

---

**Status Legend:**
- ✅ Completed
- 🔄 To Implement
- ❌ Blocked/Issues

This document will be updated as development progresses.