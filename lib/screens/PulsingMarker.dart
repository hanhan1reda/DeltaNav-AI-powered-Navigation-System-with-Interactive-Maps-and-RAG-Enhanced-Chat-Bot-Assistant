import 'package:flutter/material.dart';
import 'MapConfig.dart';
class PulsingMarker extends StatefulWidget {
  final Color color;
  final double size;
  final Duration pulseSpeed;
  final VoidCallback? onTap;

  const PulsingMarker({
  super.key,
  this.color = const Color(0xFF3498DB), // #3498DB
  this.size = 30.0,
  this.pulseSpeed = const Duration(seconds: 2),
  this.onTap,
});

  @override
  _PulsingMarkerState createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<PulsingMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    try {
      _controller = AnimationController(
        duration: widget.pulseSpeed,
        vsync: this,
      )..repeat();
      _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
      );
    } catch (e) {
      debugPrint('Error initializing PulsingMarker animation: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final pulseSize = widget.size * _pulseAnimation.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulse effect
              Container(
                width: pulseSize * 1.5,
                height: pulseSize * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.3),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Main marker
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_pin,
                  color: Colors.white,
                  size: widget.size * 0.6,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}