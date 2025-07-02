import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'MapConfig.dart';

class EducationalSidebar extends StatelessWidget {
  final List<Map<String, dynamic>> buildings;
  final VoidCallback onClose;
  final MapController mapController;
  final Function(LatLng) onNavigate;

  const EducationalSidebar({
    super.key,
    required this.buildings,
    required this.onClose,
    required this.mapController,
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
    final sidebarWidth = screenWidth > 600 ? 320.0 : screenWidth * 0.85;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth,
      margin: const EdgeInsets.symmetric(vertical: 100, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBuildingList(context)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Educational Buildings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Zain',
            ),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingList(BuildContext context) {
    if (buildings.isEmpty) {
      return const Center(
        child: Text(
          'No buildings available',
          style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Zain'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: buildings.length,
      itemBuilder: (context, index) {
        final building = buildings[index];
        final buildingName = building['name']?.toString() ?? 'Unknown';
        final imagePath = MapConfig.collegeImages[buildingName]?['imageUrl'] ??
            'assets/Map/MapIMG/graduation.png'; // Fallback image
        final description = MapConfig.getFeatureDescription(buildingName);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: ClipOval(
              child: Image.asset(
                imagePath,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  FontAwesomeIcons.building,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
            ),
            title: Text(
              buildingName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF2563EB),
                fontFamily: 'Zain',
              ),
            ),
            subtitle: Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], fontFamily: 'Zain'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const FaIcon(FontAwesomeIcons.directions, color: Color(0xFF2563EB), size: 20),
              onPressed: () {
                final coords = building['coordinates']?[0][0];
                if (coords != null && coords is List && coords.length >= 2) {
                  try {
                    final center = LatLng(coords[1] as double, coords[0] as double);
                    final constrainedCenter = _constrainCenter(center);
                    mapController.move(constrainedCenter, 18);
                    onNavigate(constrainedCenter);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Error navigating to building location.'),
                        backgroundColor: MapConfig.colors['ERROR'],
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Invalid coordinates for this building.'),
                      backgroundColor: MapConfig.colors['ERROR'],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            onTap: () {
              final coords = building['coordinates']?[0][0];
              if (coords != null && coords is List && coords.length >= 2) {
                try {
                  final center = LatLng(coords[1] as double, coords[0] as double);
                  final constrainedCenter = _constrainCenter(center);
                  mapController.move(constrainedCenter, 18);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Error moving to building location.'),
                      backgroundColor: MapConfig.colors['ERROR'],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Invalid coordinates for this building.'),
                    backgroundColor: MapConfig.colors['ERROR'],
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}