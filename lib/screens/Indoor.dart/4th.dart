import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Custom exception for handling errors related to loading graph data.
class GraphDataException implements Exception {
  final String message;

  GraphDataException(this.message);

  @override
  String toString() => 'GraphDataException: $message';
}

/// Represents a location detail with a number and description.
class LocationDetail {
  final String number;
  final String description;

  LocationDetail({
    required this.number,
    required this.description,
  });

  factory LocationDetail.fromJson(Map<String, dynamic> json) {
    return LocationDetail(
      number: json['number'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

/// Represents a vertex in the graph with its coordinates and optional metadata.
class VertexData {
  final String id;
  final String? objectName;
  final double cx;
  final double cy;
  final String? description;

  VertexData({
    required this.id,
    this.objectName,
    required this.cx,
    required this.cy,
    this.description,
  });

  factory VertexData.fromJson(Map<String, dynamic> json, List<LocationDetail> locationDetails) {
    final objectName = json['objectName'] as String?;
    final description = objectName != null
        ? locationDetails
            .firstWhere(
              (detail) => detail.number == objectName,
              orElse: () => LocationDetail(number: objectName, description: ''),
            )
            .description
        : null;

    return VertexData(
      id: json['id'] as String? ?? '',
      objectName: objectName,
      cx: (json['cx'] as num?)?.toDouble() ?? 0.0,
      cy: (json['cy'] as num?)?.toDouble() ?? 0.0,
      description: description != null && description.isNotEmpty ? description : null,
    );
  }
}

/// Represents an edge in the graph connecting two vertices.
class EdgeData {
  final String id;
  final String from;
  final String to;

  EdgeData({
    required this.id,
    required this.from,
    required this.to,
  });

  factory EdgeData.fromJson(Map<String, dynamic> json) {
    return EdgeData(
      id: json['id'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
    );
  }
}

/// Represents the graph structure consisting of vertices and edges.
class GraphData {
  final List<VertexData> vertices;
  final List<EdgeData> edges;

  GraphData({
    required this.vertices,
    required this.edges,
  });

  factory GraphData.fromJson(Map<String, dynamic> json, List<LocationDetail> locationDetails) {
    return GraphData(
      vertices: (json['vertices'] as List<dynamic>?)
              ?.map((v) => VertexData.fromJson(v as Map<String, dynamic>, locationDetails))
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => EdgeData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Helper function to load and parse JSON from an asset file.
Future<T> _loadJsonFromAsset<T>(
  String path, {
  Future<String> Function(String path)? assetLoader,
}) async {
  try {
    final loader = assetLoader ?? rootBundle.loadString;
    final jsonString = await loader(path);
    return jsonDecode(jsonString) as T;
  } catch (e) {
    throw GraphDataException('Failed to load JSON from $path: $e');
  }
}

/// Loads location details from the assets.
Future<List<LocationDetail>> loadLocationDetails({
  Future<String> Function(String path)? assetLoader,
}) async {
  final jsonData = await _loadJsonFromAsset<List<dynamic>>(
    'assets/Indoor/LocationDetails.json',
    assetLoader: assetLoader,
  );
  return jsonData.map((json) => LocationDetail.fromJson(json as Map<String, dynamic>)).toList();
}

/// Loads graph data from the assets, including vertices and edges.
Future<GraphData> loadGraphData({
  Future<String> Function(String path)? assetLoader,
}) async {
  final locationDetails = await loadLocationDetails(assetLoader: assetLoader);
  final jsonData = await _loadJsonFromAsset<Map<String, dynamic>>(
    'assets/Indoor/4th.json',
    assetLoader: assetLoader,
  );
  return GraphData.fromJson(jsonData, locationDetails);
}