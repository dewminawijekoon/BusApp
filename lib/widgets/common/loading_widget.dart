import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class LoadingWidget extends StatefulWidget {
  final String? message;
  final double? size;
  final Color? color;
  final LoadingType type;
  final bool showMessage;

  const LoadingWidget({
    Key? key,
    this.message,
    this.size,
    this.color,
    this.type = LoadingType.circular,
    this.showMessage = true,
  }) : super(key: key);

  // Named constructors for different use cases
  const LoadingWidget.circular({
    Key? key,
    String? message,
    double? size,
    Color? color,
    bool showMessage = true,
  }) : this(
          key: key,
          message: message,
          size: size,
          color: color,
          type: LoadingType.circular,
          showMessage: showMessage,
        );

  const LoadingWidget.linear({
    Key? key,
    String? message,
    Color? color,
    bool showMessage = true,
  }) : this(
          key: key,
          message: message,
          color: color,
          type: LoadingType.linear,
          showMessage: showMessage,
        );

  const LoadingWidget.dots({
    Key? key,
    String? message,
    double? size,
    Color? color,
    bool showMessage = true,
  }) : this(
          key: key,
          message: message,
          size: size,
          color: color,
          type: LoadingType.dots,
          showMessage: showMessage,
        );

  const LoadingWidget.bus({
    Key? key,
    String? message,
    double? size,
    Color? color,
    bool showMessage = true,
  }) : this(
          key: key,
          message: message,
          size: size,
          color: color,
          type: LoadingType.bus,
          showMessage: showMessage,
        );

  const LoadingWidget.fullScreen({
    Key? key,
    String? message,
    LoadingType type = LoadingType.circular,
  }) : this(
          key: key,
          message: message,
          type: type,
          showMessage: true,
        );

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _dotsController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat();
    _dotsController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.size ?? 48.0;
    final color = widget.color ?? theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoadingIndicator(theme, size, color),
          if (widget.showMessage && widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme, double size, Color color) {
    switch (widget.type) {
      case LoadingType.circular:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );

      case LoadingType.linear:
        return SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: color.withOpacity(0.2),
          ),
        );

      case LoadingType.dots:
        return _buildDotsIndicator(color, size);

      case LoadingType.bus:
        return _buildBusIndicator(color, size);

      default:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
    }
  }

  Widget _buildDotsIndicator(Color color, double size) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animValue = (_dotsController.value - delay).clamp(0.0, 1.0);
            final scale = Curves.elasticOut.transform(animValue);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: 0.5 + (scale * 0.8),
                child: Container(
                  width: size * 0.2,
                  height: size * 0.2,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3 + (scale * 0.7)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildBusIndicator(Color color, double size) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(size * 0.2),
            ),
            child: Icon(
              Symbols.directions_bus,
              size: size * 0.6,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

enum LoadingType {
  circular,
  linear,
  dots,
  bus,
}

// Full-screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final LoadingType type;
  final VoidCallback? onCancel;
  final bool canCancel;

  const LoadingOverlay({
    Key? key,
    this.message,
    this.type = LoadingType.circular,
    this.onCancel,
    this.canCancel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingWidget(
                type: type,
                message: message,
                showMessage: message != null,
              ),
              if (canCancel) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Shimmer loading for list items
class ShimmerLoadingWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoadingWidget({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<ShimmerLoadingWidget> createState() => _ShimmerLoadingWidgetState();
}

class _ShimmerLoadingWidgetState extends State<ShimmerLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                theme.colorScheme.surfaceContainer,
                theme.colorScheme.surfaceContainer.withOpacity(0.5),
                theme.colorScheme.surfaceContainer,
              ],
              stops: [
                _animation.value - 1,
                _animation.value,
                _animation.value + 1,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

// Route card shimmer loading
class RouteCardShimmer extends StatelessWidget {
  const RouteCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerLoadingWidget(
                  width: 60,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShimmerLoadingWidget(
                    width: double.infinity,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const ShimmerLoadingWidget(width: 80, height: 16),
                const SizedBox(width: 16),
                const ShimmerLoadingWidget(width: 60, height: 16),
                const SizedBox(width: 16),
                const ShimmerLoadingWidget(width: 50, height: 16),
              ],
            ),
            const SizedBox(height: 12),
            const ShimmerLoadingWidget(
              width: double.infinity,
              height: 16,
            ),
            const SizedBox(height: 8),
            ShimmerLoadingWidget(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 16,
            ),
          ],
        ),
      ),
    );
  }
}