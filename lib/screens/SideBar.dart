import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'MapConfig.dart';
import 'package:url_launcher/url_launcher.dart';

class BuildingSidebar extends StatelessWidget {
  final Map<String, dynamic> buildingData;
  final VoidCallback onClose;
  final Function(LatLng) onNavigate;

  const BuildingSidebar({
    super.key,
    required this.buildingData,
    required this.onClose,
    required this.onNavigate,
  });

  // Constrain the center to stay within bounds
  LatLng _constrainCenter(LatLng center) {
    final bounds = MapConfig.mapConfig['maxBounds'] as List<LatLng>;
    final sw = bounds[0]; // Southwest
    final ne = bounds[1]; // Northeast
    final lat = center.latitude.clamp(sw.latitude, ne.latitude);
    final lng = center.longitude.clamp(sw.longitude, ne.longitude);
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 600 ? 360.0 : screenWidth * 0.9;
    final buildingId = buildingData['id']?.toString() ?? '';
    final buildingName = MapConfig.collegeImages[buildingId]?['name'] ?? buildingData['name']?.toString() ?? 'Unknown Building';
    final imageUrl = MapConfig.collegeImages[buildingId]?['imageUrl'] ?? 'assets/Map/MapIMG/graduation.png';
    final description = MapConfig.getFeatureDescription(buildingId);
    final websiteUrl = MapConfig.links[buildingId] ?? MapConfig.links['default'];
    final buildingType = _getBuildingType(buildingId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth,
      margin: const EdgeInsets.symmetric(vertical: 80, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/Map/MapIMG/graduation.png',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    buildingName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: MapConfig.colors['EDUCATIONAL_BUILDINGS'],
                      fontFamily: 'Zain',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: $buildingType',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Zain',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                      fontFamily: 'Zain',
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final center = buildingData['center'];
                            if (center != null && center is LatLng) {
                              final constrainedCenter = _constrainCenter(center);
                              onNavigate(constrainedCenter);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Starting navigation to $buildingName'),
                                  backgroundColor: MapConfig.colors['SUCCESS'],
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Unable to navigate: Invalid coordinates'),
                                  backgroundColor: MapConfig.colors['ERROR'],
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: FaIcon(
                            FontAwesomeIcons.directions,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text('Navigate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MapConfig.colors['PARKING_AREAS'],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            textStyle: const TextStyle(fontFamily: 'Zain', fontSize: 15),
                          ),
                        ),
                      ),
                      if (websiteUrl != '#') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(websiteUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not open $websiteUrl'),
                                    backgroundColor: MapConfig.colors['ERROR'],
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: FaIcon(
                              FontAwesomeIcons.link,
                              size: 18,
                              color: MapConfig.colors['EDUCATIONAL_BUILDINGS'],
                            ),
                            label: const Text('Visit Website'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: MapConfig.colors['EDUCATIONAL_BUILDINGS'],
                              side: BorderSide(color: MapConfig.colors['EDUCATIONAL_BUILDINGS']!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              textStyle: const TextStyle(fontFamily: 'Zain', fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MapConfig.colors['EDUCATIONAL_BUILDINGS']!,
            MapConfig.colors['PARKING_AREAS']!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Building Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Zain',
            ),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white, size: 22),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  String _getBuildingType(String buildingId) {
    final entry = MapConfig.placeCategories.entries.firstWhere(
      (entry) => entry.value.contains(buildingId),
      orElse: () => MapEntry('Unknown', []),
    );
    return entry.key == 'Unknown' ? 'Unknown' : entry.key.replaceAll('_', ' ').capitalize();
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : word).join(' ');
  }
}