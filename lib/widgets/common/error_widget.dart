import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final ErrorType type;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final Widget? customIcon;
  final bool showRetryButton;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;

  const ErrorWidget({
    Key? key,
    this.title,
    this.message,
    this.type = ErrorType.general,
    this.onRetry,
    this.retryButtonText,
    this.customIcon,
    this.showRetryButton = true,
    this.onSecondaryAction,
    this.secondaryActionText,
  }) : super(key: key);

  // Named constructors for common error types
  const ErrorWidget.network({
    Key? key,
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryButtonText,
    VoidCallback? onSecondaryAction,
    String? secondaryActionText,
  }) : this(
          key: key,
          title: title ?? 'No Internet Connection',
          message: message ?? 'Please check your internet connection and try again.',
          type: ErrorType.network,
          onRetry: onRetry,
          retryButtonText: retryButtonText,
          onSecondaryAction: onSecondaryAction,
          secondaryActionText: secondaryActionText,
        );

  const ErrorWidget.location({
    Key? key,
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryButtonText,
    VoidCallback? onSecondaryAction,
    String? secondaryActionText,
  }) : this(
          key: key,
          title: title ?? 'Location Access Denied',
          message: message ?? 'Please enable location permissions to find nearby routes.',
          type: ErrorType.location,
          onRetry: onRetry,
          retryButtonText: retryButtonText ?? 'Enable Location',
          onSecondaryAction: onSecondaryAction,
          secondaryActionText: secondaryActionText,
        );

  const ErrorWidget.noRoutes({
    Key? key,
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryButtonText,
    VoidCallback? onSecondaryAction,
    String? secondaryActionText,
  }) : this(
          key: key,
          title: title ?? 'No Routes Found',
          message: message ?? 'We couldn\'t find any routes for your search. Try different locations.',
          type: ErrorType.noData,
          onRetry: onRetry,
          retryButtonText: retryButtonText ?? 'Search Again',
          onSecondaryAction: onSecondaryAction,
          secondaryActionText: secondaryActionText,
        );

  const ErrorWidget.server({
    Key? key,
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryButtonText,
    VoidCallback? onSecondaryAction,
    String? secondaryActionText,
  }) : this(
          key: key,
          title: title ?? 'Server Error',
          message: message ?? 'Something went wrong on our end. Please try again later.',
          type: ErrorType.server,
          onRetry: onRetry,
          retryButtonText: retryButtonText,
          onSecondaryAction: onSecondaryAction,
          secondaryActionText: secondaryActionText,
        );

  const ErrorWidget.timeout({
    Key? key,
    String? title,
    String? message,
    VoidCallback? onRetry,
    String? retryButtonText,
    VoidCallback? onSecondaryAction,
    String? secondaryActionText,
  }) : this(
          key: key,
          title: title ?? 'Request Timeout',
          message: message ?? 'The request is taking longer than expected. Please try again.',
          type: ErrorType.timeout,
          onRetry: onRetry,
          retryButtonText: retryButtonText,
          onSecondaryAction: onSecondaryAction,
          secondaryActionText: secondaryActionText,
        );

  const ErrorWidget.fullScreen({
    Key? key,
    String? title,
    String? message,
    ErrorType type = ErrorType.general,
    VoidCallback? onRetry,
    String? retryButtonText,
    VoidCallback? onSecondaryAction,
    String? secondaryActionText,
  }) : this(
          key: key,
          title: title,
          message: message,
          type: type,
          onRetry: onRetry,
          retryButtonText: retryButtonText,
          onSecondaryAction: onSecondaryAction,
          secondaryActionText: secondaryActionText,
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorConfig = _getErrorConfig();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: errorConfig.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: customIcon ??
                  Icon(
                    errorConfig.icon,
                    size: 40,
                    color: errorConfig.color,
                  ),
            ),
            
            const SizedBox(height: 24),
            
            // Error Title
            if (title != null)
              Text(
                title!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            
            if (title != null && message != null) 
              const SizedBox(height: 8),
            
            // Error Message
            if (message != null)
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Column(
              children: [
                if (showRetryButton && onRetry != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: Icon(errorConfig.retryIcon),
                      label: Text(retryButtonText ?? 'Try Again'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                
                if (onSecondaryAction != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onSecondaryAction,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(secondaryActionText ?? 'Go Back'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  _ErrorConfig _getErrorConfig() {
    switch (type) {
      case ErrorType.network:
        return _ErrorConfig(
          icon: Symbols.wifi_off,
          retryIcon: Symbols.refresh,
          color: Colors.orange,
        );
      
      case ErrorType.location:
        return _ErrorConfig(
          icon: Symbols.location_disabled,
          retryIcon: Symbols.my_location,
          color: Colors.red,
        );
      
      case ErrorType.noData:
        return _ErrorConfig(
          icon: Symbols.search_off,
          retryIcon: Symbols.search,
          color: Colors.blue,
        );
      
      case ErrorType.server:
        return _ErrorConfig(
          icon: Symbols.cloud_off,
          retryIcon: Symbols.refresh,
          color: Colors.red,
        );
      
      case ErrorType.timeout:
        return _ErrorConfig(
          icon: Symbols.schedule,
          retryIcon: Symbols.refresh,
          color: Colors.amber,
        );
      
      case ErrorType.general:
      default:
        return _ErrorConfig(
          icon: Symbols.error,
          retryIcon: Symbols.refresh,
          color: Colors.grey,
        );
    }
  }
}

enum ErrorType {
  general,
  network,
  location,
  noData,
  server,
  timeout,
}

class _ErrorConfig {
  final IconData icon;
  final IconData retryIcon;
  final Color color;

  _ErrorConfig({
    required this.icon,
    required this.retryIcon,
    required this.color,
  });
}

// Compact error widget for inline display
class CompactErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final ErrorType type;

  const CompactErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
    this.type = ErrorType.general,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorConfig = _getErrorConfig();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorConfig.color.withOpacity(0.1),
        border: Border.all(
          color: errorConfig.color.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            errorConfig.icon,
            size: 24,
            color: errorConfig.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(
                errorConfig.retryIcon,
                size: 16,
              ),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: errorConfig.color,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _ErrorConfig _getErrorConfig() {
    switch (type) {
      case ErrorType.network:
        return _ErrorConfig(
          icon: Symbols.wifi_off,
          retryIcon: Symbols.refresh,
          color: Colors.orange,
        );
      
      case ErrorType.location:
        return _ErrorConfig(
          icon: Symbols.location_disabled,
          retryIcon: Symbols.my_location,
          color: Colors.red,
        );
      
      case ErrorType.noData:
        return _ErrorConfig(
          icon: Symbols.search_off,
          retryIcon: Symbols.search,
          color: Colors.blue,
        );
      
      case ErrorType.server:
        return _ErrorConfig(
          icon: Symbols.cloud_off,
          retryIcon: Symbols.refresh,
          color: Colors.red,
        );
      
      case ErrorType.timeout:
        return _ErrorConfig(
          icon: Symbols.schedule,
          retryIcon: Symbols.refresh,
          color: Colors.amber,
        );
      
      case ErrorType.general:
      default:
        return _ErrorConfig(
          icon: Symbols.error,
          retryIcon: Symbols.refresh,
          color: Colors.grey,
        );
    }
  }
}

// Error boundary widget for handling widget tree errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;
  final String? fallbackMessage;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
    this.fallbackMessage,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    
    // Set up error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _errorDetails = details;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_errorDetails!);
      }
      
      return ErrorWidget(
        title: 'Something went wrong',
        message: widget.fallbackMessage ?? 
            'An unexpected error occurred. Please try again.',
        onRetry: () {
          setState(() {
            _errorDetails = null;
          });
        },
      );
    }

    return widget.child;
  }
}

// Snackbar error helper
class ErrorSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    ErrorType type = ErrorType.general,
    VoidCallback? onRetry,
    String? retryText,
    Duration duration = const Duration(seconds: 4),
  }) {
    final errorConfig = _getErrorConfigForType(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              errorConfig.icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: errorConfig.color,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: retryText ?? 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static _ErrorConfig _getErrorConfigForType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return _ErrorConfig(
          icon: Symbols.wifi_off,
          retryIcon: Symbols.refresh,
          color: Colors.orange,
        );
      
      case ErrorType.location:
        return _ErrorConfig(
          icon: Symbols.location_disabled,
          retryIcon: Symbols.my_location,
          color: Colors.red,
        );
      
      case ErrorType.server:
        return _ErrorConfig(
          icon: Symbols.cloud_off,
          retryIcon: Symbols.refresh,
          color: Colors.red,
        );
      
      case ErrorType.general:
      default:
        return _ErrorConfig(
          icon: Symbols.error,
          retryIcon: Symbols.refresh,
          color: Colors.red.shade700,
        );
    }
  }
}