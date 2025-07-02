import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'MapConfig.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RoutingService {
  Map<String, List<Map<String, dynamic>>> graph = {};
  bool _isRoutingMode = false;
  LatLng? _startPoint;
  LatLng? _endPoint;
  List<Marker> routeArrows = [];
  final Map<String, double> _distanceCache = {};

  // Add an edge to the graph
  void addEdge(String a, String b, double weight) {
    if (!graph.containsKey(a)) graph[a] = [];
    if (!graph.containsKey(b)) graph[b] = [];
    graph[a]!.add({'node': b, 'weight': weight});
    graph[b]!.add({'node': a, 'weight': weight}); // Undirected graph
  }

  Future<void> buildGraph() async {
    try {
      final geoJsonData = await rootBundle.loadString(
        'assets/Map/MapFiles/delta_university_paths.geojson',
      );
      final geoJson = jsonDecode(geoJsonData);
      _buildGraphFromGeoJSON(geoJson, tolerance: 5); // Reduced tolerance for precision
      debugPrint('Graph built with ${graph.length} nodes');
    } catch (e) {
      debugPrint('Error building graph: $e');
      throw Exception('Failed to build graph: $e');
    }
  }

  void _buildGraphFromGeoJSON(
    Map<String, dynamic> geojson, {
    double tolerance = 5,
  }) {
    graph.clear();
    final points = <String, List<double>>{};

    // Process LineString features only
    for (var feature in geojson['features']) {
      if (feature['geometry']['type'] == 'LineString') {
        final coords = feature['geometry']['coordinates'];
        for (var i = 0; i < coords.length - 1; i++) {
          final a = coords[i];
          final b = coords[i + 1];

          // Add intermediate points for smoother paths
          const numPoints = 4; // Reduced for performance
          for (var j = 0; j <= numPoints; j++) {
            final t = j / numPoints;
            final lat = a[1] + (b[1] - a[1]) * t;
            final lng = a[0] + (b[0] - a[0]) * t;

            final key = '$lat,$lng';
            points[key] = [lng, lat];

            if (j > 0) {
              final prevKey =
                  '${a[1] + (b[1] - a[1]) * ((j - 1) / numPoints)},${a[0] + (b[0] - a[0]) * ((j - 1) / numPoints)}';
              final distance = _calculateDistance(
                LatLng(lat, lng),
                LatLng(points[prevKey]![1], points[prevKey]![0]),
              );
              addEdge(key, prevKey, distance);
            }
          }
        }
      }
    }

    // Connect nearby points
    final pointArray = points.entries.toList();
    final connectTolerance = tolerance * 2;

    for (var i = 0; i < pointArray.length; i++) {
      final keyA = pointArray[i].key;
      final coordsA = pointArray[i].value;
      for (var j = i + 1; j < pointArray.length; j++) {
        final keyB = pointArray[j].key;
        final coordsB = pointArray[j].value;

        final distance = _calculateDistance(
          LatLng(coordsA[1], coordsA[0]),
          LatLng(coordsB[1], coordsB[0]),
        );
        if (distance < connectTolerance) {
          addEdge(keyA, keyB, distance);
        }
      }
    }

    debugPrint('Graph built with ${points.length} points and ${graph.length} nodes');
  }

  // Calculate distance between two LatLng points in meters
  double _calculateDistance(LatLng a, LatLng b) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, a, b);
  }

  // Find nearest point on the network
  LatLng? findNearestPointOnNetwork(LatLng point, List<LatLng> routePoints) {
    if (!_isInsideUniversity(point)) {
      debugPrint('Point outside university bounds: $point');
      return null;
    }

    LatLng? nearest;
    double minDist = double.infinity;

    for (var routePoint in routePoints) {
      final distance = _calculateDistance(point, routePoint);
      if (distance < minDist) {
        minDist = distance;
        nearest = routePoint;
      }
    }

    debugPrint('Nearest point to $point: $nearest, distance: $minDist meters');
    if (nearest != null && minDist < 100) { // Increased tolerance to 100 meters
      return nearest;
    }
    debugPrint('No nearby point found within tolerance for: $point');
    return null;
  }

  // Generate direction arrows for the path
  List<Marker> generateRouteArrows(List<LatLng> path) {
    routeArrows.clear();
    const arrowSpacing = 20.0; // Meters between arrows
    double accumulatedDistance = 0;

    for (var i = 0; i < path.length - 1; i++) {
      final start = path[i];
      final end = path[i + 1];
      final segmentDistance = _calculateDistance(start, end);

      if (segmentDistance == 0) continue;

      final bearing = _calculateBearing(start, end);
      accumulatedDistance += segmentDistance;

      while (accumulatedDistance >= arrowSpacing) {
        final t = (accumulatedDistance - arrowSpacing) / segmentDistance;
        final arrowPoint = LatLng(
          start.latitude + (end.latitude - start.latitude) * (1 - t),
          start.longitude + (end.longitude - start.longitude) * (1 - t),
        );

        routeArrows.add(
          Marker(
            point: arrowPoint,
            child: Transform.rotate(
              angle: bearing * (3.14159 / 180),
              child: Icon(
                FontAwesomeIcons.arrowUp,
                color: MapConfig.colors['PARKING_AREAS'],
                size: 16,
              ),
            ),
          ),
        );
        accumulatedDistance -= arrowSpacing;
      }
    }

    return routeArrows;
  }

  // Calculate bearing between two points (in degrees)
  double _calculateBearing(LatLng start, LatLng end) {
    final deltaLon = end.longitude - start.longitude;
    final y = sin(deltaLon * (3.14159 / 180)) * cos(end.latitude * (3.14159 / 180));
    final x = cos(start.latitude * (3.14159 / 180)) * sin(end.latitude * (3.14159 / 180)) -
        sin(start.latitude * (3.14159 / 180)) * cos(end.latitude * (3.14159 / 180)) * cos(deltaLon * (3.14159 / 180));
    final bearing = atan2(y, x) * (180 / 3.14159);
    return (bearing + 360) % 360;
  }

  // Dijkstra's algorithm to find shortest path
  List<LatLng> dijkstra(LatLng start, LatLng end, List<LatLng> routePoints) {
    _startPoint = start;
    _endPoint = end;

    debugPrint('Starting Dijkstra from $start to $end');
    debugPrint('Total routePoints: ${routePoints.length}');

    final startKey = '${start.latitude},${start.longitude}';
    final endKey = '${end.latitude},${end.longitude}';
    final nearestStart = findNearestPointOnNetwork(start, routePoints);
    final nearestEnd = findNearestPointOnNetwork(end, routePoints);

    if (nearestStart == null || nearestEnd == null) {
      debugPrint('No valid start or end point found on network');
      return [];
    }

    final nearestStartKey = '${nearestStart.latitude},${nearestStart.longitude}';
    final nearestEndKey = '${nearestEnd.latitude},${nearestEnd.longitude}';

    debugPrint('Nearest start: $nearestStartKey, Nearest end: $nearestEndKey');

    if (!graph.containsKey(nearestStartKey) || !graph.containsKey(nearestEndKey)) {
      debugPrint('Graph does not contain start or end key');
      debugPrint('Graph keys: ${graph.keys.length} nodes');
      return [];
    }

    final cacheKey = '$nearestStartKey-$nearestEndKey';
    if (_distanceCache.containsKey(cacheKey)) {
      debugPrint('Using cached path for $cacheKey');
      // Reconstruct path from cached data (simplified)
    }

    final distances = <String, double>{};
    final previous = <String, String?>{};
    final unvisited = <String>{};

    for (var vertex in graph.keys) {
      distances[vertex] = double.infinity;
      previous[vertex] = null;
      unvisited.add(vertex);
    }
    distances[nearestStartKey] = 0;

    while (unvisited.isNotEmpty) {
      String? current;
      double minDistance = double.infinity;
      for (var vertex in unvisited) {
        if (distances[vertex]! < minDistance) {
          current = vertex;
          minDistance = distances[vertex]!;
        }
      }

      if (current == null || current == nearestEndKey) break;

      unvisited.remove(current);

      for (var neighbor in graph[current]!) {
        final node = neighbor['node'] as String;
        final weight = neighbor['weight'] as double;
        if (unvisited.contains(node)) {
          final distance = distances[current]! + weight;
          if (distance < distances[node]!) {
            distances[node] = distance;
            previous[node] = current;
          }
        }
      }
    }

    if (distances[nearestEndKey] == double.infinity) {
      debugPrint('No path found between $nearestStartKey and $nearestEndKey');
      return [];
    }

    final path = <String>[];
    String? current = nearestEndKey;
    while (current != null) {
      path.insert(0, current);
      current = previous[current];
    }

    final completePath = [
      start,
      nearestStart,
      ...path.map((key) {
        final coords = key.split(',').map(double.parse).toList();
        return LatLng(coords[0], coords[1]);
      }),
      nearestEnd,
      end,
    ];

    _distanceCache[cacheKey] = distances[nearestEndKey]!;
    debugPrint('Path found with length: ${distances[nearestEndKey]} meters');

    // Generate arrows
    generateRouteArrows(completePath);
    return completePath;
  }

  // Toggle routing mode
  bool toggleRoutingMode() {
    _isRoutingMode = !_isRoutingMode;
    if (!_isRoutingMode) {
      clearRoute();
    }
    return _isRoutingMode;
  }

  // Clear current route
  void clearRoute() {
    _startPoint = null;
    _endPoint = null;
    routeArrows.clear();
  }

  // Check if point is inside university bounds
  bool _isInsideUniversity(LatLng point) {
    final bounds = MapConfig.mapConfig['maxBounds'] as List<LatLng>;
    final sw = bounds[0]; // Southwest
    final ne = bounds[1]; // Northeast
    return point.latitude >= sw.latitude &&
        point.latitude <= ne.latitude &&
        point.longitude >= sw.longitude &&
        point.longitude <= ne.longitude;
  }
}

// Extension to parse string to double
extension StringParsing on String {
  double parseDouble() => double.parse(this);
}