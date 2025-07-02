import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'MapConfig.dart';
import 'MapService.dart';
import 'RoutingService.dart';

class MapFunctions {
  static Timer? _messageTimeout;
  static bool isRoutingMode = false;
  static final Map<String, Map<String, dynamic>> _boundsCache = {};

  // Show notification (equivalent to showNotification in JS)
  static void showNotification(
    BuildContext context,
    String message,
    String type, {
    int duration = 3000,
  }) {
    Color backgroundColor;
    IconData icon;
    switch (type) {
      case 'success':
        backgroundColor = MapConfig.colors['SUCCESS']!;
        icon = FontAwesomeIcons.checkCircle;
        break;
      case 'error':
        backgroundColor = MapConfig.colors['ERROR']!;
        icon = FontAwesomeIcons.exclamationCircle;
        break;
      case 'warning':
        backgroundColor = MapConfig.colors['WARNING']!;
        icon = FontAwesomeIcons.exclamationTriangle;
        break;
      default:
        backgroundColor = MapConfig.colors['PARKING_AREAS']!;
        icon = FontAwesomeIcons.infoCircle;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            FaIcon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontFamily: 'Zain'),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(milliseconds: duration),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );

    _messageTimeout?.cancel();
    _messageTimeout = Timer(Duration(milliseconds: duration), () {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  // Check if location is inside university (equivalent to isInsideUniversity)
  static bool isInsideUniversity(LatLng latlng) {
    final bounds = MapConfig.mapConfig['maxBounds'] as List<LatLng>;
    final sw = bounds[0]; // Southwest
    final ne = bounds[1]; // Northeast
    return latlng.latitude >= sw.latitude &&
        latlng.latitude <= ne.latitude &&
        latlng.longitude >= sw.longitude &&
        latlng.longitude <= ne.longitude;
  }

  // Constrain the center to stay within bounds
  static LatLng _constrainCenter(LatLng center, List<LatLng> bounds) {
    final sw = bounds[0]; // Southwest
    final ne = bounds[1]; // Northeast
    final lat = center.latitude.clamp(sw.latitude, ne.latitude);
    final lng = center.longitude.clamp(sw.longitude, ne.longitude);
    return LatLng(lat, lng);
  }

  // Initialize routing control (equivalent to initializeRoutingControl)
  static Map<String, dynamic> initializeRoutingControl(
    MapController mapController,
    MapService mapService,
    RoutingService routingService,
  ) {
    List<LatLng> waypoints = [];

    return {
      'waypoints': waypoints,
      'setWaypoints': (List<LatLng> newWaypoints, Function setState) async {
        waypoints = newWaypoints;
        mapService.routeArrows.clear();
        mapService.currentPath = [];

        if (waypoints.length >= 2) {
          final start = waypoints[0];
          final end = waypoints[1];

          if (!isInsideUniversity(start) || !isInsideUniversity(end)) {
            showNotification(
              mapService.context,
              'Start or end point is outside university bounds.',
              'error',
            );
            return;
          }

          final path = routingService.dijkstra(
            start,
            end,
            mapService.routePoints,
          );
          if (path.isNotEmpty) {
            mapService.currentPath = path;
            mapService.routeArrows.clear();
            mapService.routeArrows.addAll(routingService.routeArrows);
            final bounds = _calculateBounds(path);
            // Constrain the center to stay within bounds
            final constrainedCenter = _constrainCenter(
              bounds['center'],
              MapConfig.mapConfig['maxBounds'] as List<LatLng>,
            );
            mapController.move(constrainedCenter, bounds['zoom']);
            showNotification(
              mapService.context,
              'Route calculated successfully! (${path.length} points)',
              'success',
            );
          } else {
            showNotification(
              mapService.context,
              'No path found between selected points.',
              'error',
            );
          }

          setState(() {});
        }
      },
    };
  }

  // Initialize advanced routing (equivalent to initializeAdvancedRouting)
  static void initializeAdvancedRouting(
    BuildContext context,
    MapController mapController,
    MapService mapService,
    RoutingService routingService,
    Function setState,
    Map<String, dynamic> routingControl,
  ) {
    List<LatLng> routingWaypoints = [];
    List<Marker> routingMarkers = [];

    void clearRouting() {
      routingMarkers.clear();
      routingWaypoints.clear();
      mapService.currentPath = [];
      mapService.routeArrows.clear();
      setState(() {});
    }

    void toggleRoutingMode() {
      setState(() {
        isRoutingMode = !isRoutingMode;
        if (isRoutingMode) {
          showNotification(
            context,
            'Routing Mode: Tap to set start and end points',
            'info',
          );
          clearRouting();
        } else {
          showNotification(context, 'Routing mode cancelled', 'info');
          clearRouting();
        }
      });
    }

    void handleMapClick(LatLng point) {
      if (!isRoutingMode || !isInsideUniversity(point)) {
        if (!isInsideUniversity(point)) {
          showNotification(
            context,
            'Selected point is outside university bounds.',
            'error',
          );
        }
        return;
      }

      final marker = Marker(
        point: point,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: routingWaypoints.isEmpty
                ? MapConfig.colors['SUCCESS']
                : MapConfig.colors['ERROR'],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
            ],
          ),
        ),
      );

      routingWaypoints.add(point);
      routingMarkers.add(marker);
      mapService.markers.add(marker);
      setState(() {});

      if (routingWaypoints.length == 2) {
        final start = routingWaypoints[0];
        final end = routingWaypoints[1];

        final path = routingService.dijkstra(
          start,
          end,
          mapService.routePoints,
        );
        if (path.isNotEmpty) {
          mapService.currentPath = path;
          mapService.routeArrows.clear();
          mapService.routeArrows.addAll(routingService.routeArrows);
          final bounds = _calculateBounds(path);
          // Constrain the center to stay within bounds
          final constrainedCenter = _constrainCenter(
            bounds['center'],
            MapConfig.mapConfig['maxBounds'] as List<LatLng>,
          );
          mapController.move(constrainedCenter, bounds['zoom']);
          showNotification(
            context,
            'Route calculated successfully! (${path.length} points)',
            'success',
          );
        } else {
          showNotification(
            context,
            'No path found between selected points.',
            'error',
          );
          clearRouting();
        }

        isRoutingMode = false;
        routingWaypoints.clear();
        routingMarkers.forEach(mapService.markers.remove);
        setState(() {});
      }
    }

    routingControl['toggleRoutingMode'] = toggleRoutingMode;
    routingControl['handleMapClick'] = handleMapClick;
  }

  // Calculate bounds for map zoom
  static Map<String, dynamic> _calculateBounds(List<LatLng> path) {
    final cacheKey = path.map((p) => '${p.latitude},${p.longitude}').join('|');
    if (_boundsCache.containsKey(cacheKey)) {
      return _boundsCache[cacheKey]!;
    }

    double minLat = path[0].latitude;
    double maxLat = path[0].latitude;
    double minLng = path[0].longitude;
    double maxLng = path[0].longitude;

    for (var point in path) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final latDelta = (maxLat - minLat) * 1.2; // Add padding
    final lngDelta = (maxLng - minLng) * 1.2;
    final zoom =
        latDelta == 0 || lngDelta == 0 ? 16.0 : 18 - (latDelta + lngDelta) * 10;

    final result = {'center': center, 'zoom': zoom.clamp(14.0, 18.0)};
    _boundsCache[cacheKey] = result;
    return result;
  }

  // Get current location (equivalent to getCurrentLocation)
  static Future<void> getCurrentLocation(
    BuildContext context,
    MapController mapController,
    MapService mapService,
    Function setState,
  ) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showNotification(context, 'Location permission denied.', 'error');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      showNotification(
        context,
        'Location permission permanently denied. Please enable in settings.',
        'error',
      );
      return;
    }

    showNotification(
      context,
      'Getting your location... This may take longer with poor GPS signal.',
      'info',
    );

    int attempts = 0;
    const maxAttempts = 2;
    double bestAccuracy = double.infinity;
    Position? bestPosition;

    StreamSubscription<Position>? positionStream;
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        timeLimit: Duration(seconds: 30),
      ),
    ).listen(
      (Position position) async {
        attempts++;
        if (position.accuracy < bestAccuracy) {
          bestAccuracy = position.accuracy;
          bestPosition = position;
        }

        final latlng = LatLng(position.latitude, position.longitude);

        if (isInsideUniversity(latlng)) {
          mapService.updateUserPosition(position);
          setState(() {});

          final accuracyColor =
              position.accuracy <= 10
                  ? MapConfig.colors['SUCCESS']!.withOpacity(0.3)
                  : position.accuracy <= 30
                      ? MapConfig.colors['WARNING']!.withOpacity(0.3)
                      : MapConfig.colors['ERROR']!.withOpacity(0.3);

          mapService.accuracyCircle = CircleLayer(
            circles: [
              CircleMarker(
                point: latlng,
                radius: position.accuracy,
                color: accuracyColor,
                useRadiusInMeter: true,
              ),
            ],
          );

          // Constrain the center to stay within bounds
          final constrainedCenter = _constrainCenter(
            latlng,
            MapConfig.mapConfig['maxBounds'] as List<LatLng>,
          );
          mapController.move(constrainedCenter, 18);

          if (position.accuracy <= 10) {
            showNotification(
              context,
              'High accuracy location detected! (${position.accuracy.round()}m)',
              'success',
            );
            await positionStream?.cancel();
          } else if (position.accuracy <= 30) {
            showNotification(
              context,
              'Medium accuracy location detected (${position.accuracy.round()}m). Keep waiting for better accuracy...',
              'info',
            );
          } else {
            showNotification(
              context,
              'Low accuracy location detected (${position.accuracy.round()}m). Move to an open area for better GPS signal.',
              'warning',
            );
          }

          if (attempts >= maxAttempts || position.accuracy <= 10) {
            await positionStream?.cancel();
          }
        } else {
          showNotification(
            context,
            'You are outside the university campus.',
            'error',
          );
          await positionStream?.cancel();
        }
      },
      onError: (error) {
        String message;
        switch (error.code) {
          case 'locationPermissionDenied':
            message =
                'Location access denied. Please enable permissions in settings.';
            break;
          case 'locationPermissionPermanentlyDenied':
            message = 'Location access permanently denied.';
            break;
          default:
            message =
                'Error getting location: $error. Check your network or GPS.';
        }
        showNotification(context, message, 'error');
        positionStream?.cancel();
      },
    );
  }

  // Initialize location tracking (equivalent to initializeLocationTracking)
  static void initializeLocationTracking(
    BuildContext context,
    MapController mapController,
    MapService mapService,
    RoutingService routingService,
    Function setState,
  ) {
    final routingControl = initializeRoutingControl(
      mapController,
      mapService,
      routingService,
    );
    initializeAdvancedRouting(
      context,
      mapController,
      mapService,
      routingService,
      setState,
      routingControl,
    );

    mapService.routingControl = routingControl;
    mapService.onMapTap = routingControl['handleMapClick'];
  }

  // Calculate route between start and destination
  static void calculateRoute(
    BuildContext context,
    LatLng start,
    LatLng destination,
    MapController mapController,
    MapService mapService,
    RoutingService routingService,
  ) {
    if (!isInsideUniversity(start) || !isInsideUniversity(destination)) {
      showNotification(
        mapService.context,
        'Start or end point is outside university bounds.',
        'error',
      );
      return;
    }

    final path = routingService.dijkstra(
      start,
      destination,
      mapService.routePoints,
    );

    if (path.isNotEmpty) {
      mapService.currentPath = path;
      mapService.routeArrows.clear();
      mapService.routeArrows.addAll(routingService.routeArrows);
      final bounds = _calculateBounds(path);
      // Constrain the center to stay within bounds
      final constrainedCenter = _constrainCenter(
        bounds['center'],
        MapConfig.mapConfig['maxBounds'] as List<LatLng>,
      );
      mapController.move(constrainedCenter, bounds['zoom']);
      showNotification(
        context,
        'Route calculated successfully! (${path.length} points)',
        'success',
      );
    } else {
      showNotification(
        context,
        'No path found between selected points.',
        'error',
      );
    }
  }
}