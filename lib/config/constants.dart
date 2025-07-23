class AppConstants {
  // App Information
  static const String appName = 'TransitEase';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String googleMapsApiKey = 'your-google-maps-api-key';
  static const String googleDirectionsApiKey = 'your-google-directions-api-key';
  static const String baseUrl = 'https://your-api-base-url.com';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String busRoutesCollection = 'busRoutes';
  static const String busesCollection = 'buses';
  static const String busStopsCollection = 'busStops';
  static const String journeysCollection = 'journeys';
  static const String alertsCollection = 'alerts';
  static const String ratingsCollection = 'ratings';
  static const String savedRoutesCollection = 'savedRoutes';

  // User Preferences Keys
  static const String userPrefsKey = 'user_preferences';
  static const String locationPermissionKey = 'location_permission_granted';
  static const String notificationPermissionKey = 'notification_permission_granted';
  static const String firstLaunchKey = 'is_first_launch';
  static const String selectedLanguageKey = 'selected_language';

  // Location Settings
  static const double defaultLatitude = 6.9271; // Colombo, Sri Lanka
  static const double defaultLongitude = 79.8612;
  static const double searchRadius = 5000.0; // 5km in meters
  static const double nearbyBusStopRadius = 500.0; // 500m in meters

  // Time Constants
  static const int locationUpdateIntervalSeconds = 10;
  static const int busLocationUpdateIntervalSeconds = 5;
  static const int routeRefreshIntervalMinutes = 5;
  static const int alertCheckIntervalMinutes = 1;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double mapZoomLevel = 15.0;

  // Notification Constants
  static const String busArrivalChannelId = 'bus_arrival_notifications';
  static const String busArrivalChannelName = 'Bus Arrival Alerts';
  static const String getOffChannelId = 'get_off_notifications';
  static const String getOffChannelName = 'Get Off Alerts';
  static const String generalChannelId = 'general_notifications';
  static const String generalChannelName = 'General Notifications';

  // Points System
  static const int pointsForCompletingJourney = 10;
  static const int pointsForRatingBus = 5;
  static const int pointsForReportingIssue = 15;
  static const int pointsForSharingLocation = 2;

  // Bus Crowd Levels
  static const int emptyCrowdLevel = 1;
  static const int lowCrowdLevel = 2;
  static const int mediumCrowdLevel = 3;
  static const int highCrowdLevel = 4;
  static const int fullCrowdLevel = 5;

  // Route Planning
  static const int maxRouteAlternatives = 5;
  static const int maxTransfers = 3;
  static const double walkingSpeedKmh = 5.0;
  static const double busAverageSpeedKmh = 25.0;

  // Error Messages
  static const String noInternetError = 'No internet connection. Please check your network.';
  static const String locationPermissionError = 'Location permission is required for this feature.';
  static const String authenticationError = 'Authentication failed. Please try again.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';

  // Validation Constants
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  // Storage Keys
  static const String lastKnownLocationKey = 'last_known_location';
  static const String cachedRoutesKey = 'cached_routes';
  static const String userSettingsKey = 'user_settings';
}

class ApiEndpoints {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String refreshToken = '/auth/refresh';
  
  static const String routes = '/routes';
  static const String buses = '/buses';
  static const String busStops = '/bus-stops';
  static const String directions = '/directions';
  
  static const String userProfile = '/user/profile';
  static const String savedRoutes = '/user/saved-routes';
  static const String userJourneys = '/user/journeys';
  
  static const String ratings = '/ratings';
  static const String alerts = '/alerts';
  static const String notifications = '/notifications';
}

class RouteStatus {
  static const String active = 'active';
  static const String inactive = 'inactive';
  static const String delayed = 'delayed';
  static const String cancelled = 'cancelled';
}

class BusStatus {
  static const String inService = 'in_service';
  static const String outOfService = 'out_of_service';
  static const String maintenance = 'maintenance';
  static const String delayed = 'delayed';
}

class JourneyStatus {
  static const String planning = 'planning';
  static const String waiting = 'waiting';
  static const String onBoard = 'on_board';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class AlertType {
  static const String busArrival = 'bus_arrival';
  static const String getOff = 'get_off';
  static const String routeChange = 'route_change';
  static const String delay = 'delay';
  static const String cancellation = 'cancellation';
  static const String general = 'general';
}

class AlertPriority {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String urgent = 'urgent';
}