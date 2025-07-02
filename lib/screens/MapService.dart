import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'MapConfig.dart';
import 'PulsingMarker.dart';

class MapService {
  final BuildContext context;
  final List<Marker> markers = [];
  final List<LatLng> universityBorder = [];
  final List<LatLng> routePoints = [];
  late final List<Marker> routeArrows = [];
  final List<Map<String, dynamic>> educationalBuildings = [];
  List<Map<String, dynamic>> geoJsonFeatures = [];
  List<Map<String, dynamic>> searchablePlaces = [];
  Marker? userMarker;
  Marker? destinationMarker;
  CircleLayer? accuracyCircle;
  PolygonLayer? geoJsonPolygons;
  PolylineLayer? geoJsonPolylines;
  MarkerLayer? geoJsonMarkers;
  List<LatLng> currentPath = [];
  Function(LatLng)? onMapTap;
  Map<String, dynamic> routingControl = {};

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondaryColor = Color(0xFFF97316);

  MapService(this.context);

  Future<void> loadGeoJsonData() async {
    try {
      final geoJson = await _loadAssetJson('assets/Map/MapFiles/map.geojson');
      geoJsonFeatures = List<Map<String, dynamic>>.from(geoJson['features']);
      List<Polygon> polygons = [];
      List<Polyline> polylines = [];
      List<Marker> markers = [];

      for (var feature in geoJsonFeatures) {
        final name = feature['properties']['name'] ?? '';
        final geometryType = feature['geometry']['type'];

        if (geometryType == 'Polygon') {
          final coords = feature['geometry']['coordinates'][0];
          final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          final center = calculateCenter(points);

          if (MapConfig.isFacultyBuilding(name)) {
            markers.add(
              Marker(
                point: center,
                child: GestureDetector(
                  onTap: () {
                    onMapTap?.call(center);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected: ${MapConfig.collegeImages[name]?['name'] ?? name}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Image.asset(
                    'assets/Map/MapIMG/graduation.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
            );
            educationalBuildings.add({
              'name': name,
              'coordinates': feature['geometry']['coordinates'],
              'properties': feature['properties'],
              'center': center,
            });
          }

          polygons.add(
            Polygon(
              points: points,
              color: MapConfig.getFeatureColor(name).withOpacity(
                MapConfig.isFacultyBuilding(name) ? 0.4 : 0.7,
              ),
              borderColor: Colors.transparent,
              borderStrokeWidth: 0,
              isFilled: true,
            ),
          );
        } else if (geometryType == 'LineString') {
          final coords = feature['geometry']['coordinates'];
          final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          polylines.add(
            Polyline(
              points: points,
              color: MapConfig.getFeatureColor(name),
              strokeWidth: 3,
            ),
          );
        } else if (geometryType == 'Point') {
          final coords = feature['geometry']['coordinates'];
          final point = LatLng(coords[1], coords[0]);
          markers.add(
            Marker(
              point: point,
              child: Icon(
                Icons.location_pin,
                color: MapConfig.getFeatureColor(name),
                size: 30,
              ),
            ),
          );
        }
      }

      if (polygons.isNotEmpty) {
        geoJsonPolygons = PolygonLayer(polygons: polygons);
      }
      if (polylines.isNotEmpty) {
        geoJsonPolylines = PolylineLayer(polylines: polylines);
      }
      if (markers.isNotEmpty) {
        geoJsonMarkers = MarkerLayer(markers: markers);
      }
    } catch (e) {
      throw Exception('Failed to load GeoJSON data: $e');
    }
  }

  Future<void> loadPaths() async {
    try {
      final pathsJson = await _loadAssetJson('assets/Map/MapFiles/delta_university_paths.geojson');
      for (var feature in pathsJson['features']) {
        if (feature['geometry']['type'] == 'LineString') {
          final coords = feature['geometry']['coordinates'];
          final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          routePoints.addAll(points);
        } else if (feature['geometry']['type'] == 'Polygon' && feature['properties']['name'] == 'delta borders') {
          final coords = feature['geometry']['coordinates'][0];
          universityBorder.addAll(coords.map<LatLng>((c) => LatLng(c[1], c[0])));
        }
      }
    } catch (e) {
      print('Error loading paths or university border: $e');
      universityBorder.clear();
      throw Exception('Failed to load paths: $e');
    }
  }

  Future<dynamic> _loadAssetJson(String path) async {
    try {
      final data = await DefaultAssetBundle.of(context).loadString(path);
      return jsonDecode(data);
    } catch (e) {
      throw Exception('Failed to load $path: $e');
    }
  }

  LatLng calculateCenter(List<LatLng> points) {
    double latSum = 0, lngSum = 0;
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  void updateUserPosition(Position position) {
    final userPos = LatLng(position.latitude, position.longitude);
    final accuracy = position.accuracy;
    final isInside = _isInsideUniversity(userPos);

    if (isInside) {
      userMarker = Marker(
        point: userPos,
        child: const PulsingMarker(
          color: Color(0xFF2ECC71),
          size: 30,
        ),
      );
      accuracyCircle = CircleLayer(
        circles: [
          CircleMarker(
            point: userPos,
            radius: accuracy,
            color: accuracy <= 10
                ? const Color(0xFF2ECC71).withOpacity(0.3)
                : accuracy <= 30
                    ? const Color(0xFFF1C40F).withOpacity(0.3)
                    : const Color(0xFFE74C3C).withOpacity(0.3),
            useRadiusInMeter: true,
          ),
        ],
      );
      if (destinationMarker != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route updated based on new position'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      userMarker = null;
      accuracyCircle = null;
      routePoints.clear();
      routeArrows.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are outside the university bounds'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  bool _isInsideUniversity(LatLng latlng) {
    final bounds = MapConfig.mapConfig['maxBounds'] as List<LatLng>?;
    if (bounds == null || bounds.length < 2) {
      return false;
    }
    final sw = bounds[0];
    final ne = bounds[1];
    return latlng.latitude >= sw.latitude &&
        latlng.latitude <= ne.latitude &&
        latlng.longitude >= sw.longitude &&
        latlng.longitude <= ne.longitude;
  }

  void setDestination(LatLng point) {
    final isInside = _isInsideUniversity(point);
    if (isInside) {
      destinationMarker = Marker(
        point: point,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: secondaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
            ],
          ),
        ),
      );
      if (userMarker != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destination set. Calculating route...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destination is outside university bounds'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void clearRoute() {
    routeArrows.clear();
    currentPath.clear();
    userMarker = null;
    destinationMarker = null;
  }

  List<Map<String, dynamic>> searchFeatures(String query) {
    final lowerQuery = query.toLowerCase();
    return searchablePlaces.where((place) {
      return place['name'].toLowerCase().contains(lowerQuery) ||
          place['type'].toLowerCase().contains(lowerQuery);
    }).toList();
  }
}