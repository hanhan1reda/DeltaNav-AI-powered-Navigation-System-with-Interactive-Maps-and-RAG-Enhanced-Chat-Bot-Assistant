import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'CampusAssist.dart';
import 'EducationalSideBar.dart';
import 'SideBar.dart';
import 'RoutingService.dart';
import 'MapService.dart';
import 'Weather.dart';
import 'MapConfig.dart';
import 'Functions.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late MapService _mapService;
  late RoutingService _routingService;
  StreamSubscription<Position>? _positionStream;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSidebarOpen = false;
  bool _isEducationalSidebarOpen = false;
  Map<String, dynamic>? _buildingData;
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondaryColor = Color(0xFFF97316);
  static const Color backgroundLight = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _mapService = MapService(context);
    _routingService = RoutingService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sidebarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await _mapService.loadGeoJsonData();
      await _mapService.loadPaths();
      await _routingService.buildGraph();
      MapFunctions.initializeLocationTracking(
        context,
        _mapController,
        _mapService,
        _routingService,
        setState,
      );
      _initializeSearch();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      print('Error initializing map: $e');
      print(stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load map data: $e';
        });
      }
    }
  }

  void _initializeSearch() {
    _mapService.searchablePlaces =
        _mapService.geoJsonFeatures
            .where((feature) => feature['properties']['name'] != null)
            .map(
              (feature) => {
                'id': feature['properties']['name'],
                'name': feature['properties']['name'],
                'type':
                    MapConfig.isFacultyBuilding(feature['properties']['name'])
                        ? 'building'
                        : 'facility',
              },
            )
            .toList();
  }

  void _performSearch(String query) {
    if (query.isEmpty || !mounted) return;

    setState(() => _isSearching = true);
    final results = _mapService.searchFeatures(query);
    if (results.isNotEmpty && mounted) {
      final result = results[0];
      final feature = _mapService.geoJsonFeatures.firstWhere(
        (f) => f['properties']['name'] == result['id'],
        orElse: () => {},
      );

      if (feature.isNotEmpty) {
        final coordinates =
            feature['geometry']['type'] == 'Polygon'
                ? feature['geometry']['coordinates'][0]
                : feature['geometry']['coordinates'];
        final center =
            feature['geometry']['type'] == 'Point'
                ? LatLng(coordinates[1], coordinates[0])
                : _mapService.calculateCenter(
                  coordinates.map<LatLng>((c) => LatLng(c[1], c[0])).toList(),
                );
        _mapController.move(center, 18);

        final searchMarker = Marker(
          point: center,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color:
                  MapConfig.colors['PARKING_AREAS'] ?? const Color(0xFF3498DB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8),
              ],
            ),
            child: const FaIcon(
              FontAwesomeIcons.mapPin,
              color: Colors.white,
              size: 16,
            ),
          ),
        );
        setState(() {
          _mapService.markers.add(searchMarker);
        });

        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _mapService.markers.remove(searchMarker);
            });
          }
        });

        _showBuildingSidebar({
          'name': result['name'],
          'id': result['id'],
          'description': MapConfig.getFeatureDescription(result['id']),
          'imageUrl':
              MapConfig.collegeImages[result['id']]?['imageUrl'] ??
              'assets/Map/MapIMG/graduation.png',
          'link': MapConfig.links[result['id']] ?? '#',
          'coordinates': coordinates,
        });

        MapFunctions.showNotification(
          context,
          'Found: ${result['name']}',
          'success',
        );
      } else {
        MapFunctions.showNotification(
          context,
          'Feature not found on map',
          'error',
        );
      }
    } else {
      MapFunctions.showNotification(
        context,
        'No results found for "$query"',
        'error',
      );
    }
    if (mounted) {
      setState(() => _isSearching = false);
    }
  }

  void _showBuildingSidebar(Map<String, dynamic> buildingData) {
    setState(() {
      _buildingData = buildingData;
      _isSidebarOpen = true;
      _isEducationalSidebarOpen = false;
      _animationController.forward();
    });
  }

  void _showEducationalSidebar() {
    setState(() {
      _isEducationalSidebarOpen = true;
      _isSidebarOpen = false;
      _animationController.forward();
    });
  }

  void _closeSidebar() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isSidebarOpen = false;
          _isEducationalSidebarOpen = false;
          _buildingData = null;
        });
      }
    });
  }

  void _startRouting(LatLng destination) {
  _mapService.setDestination(destination);
  if (_mapService.userMarker != null) {
    final start = _mapService.userMarker!.point;
    MapFunctions.calculateRoute(
      context,
      start,
      destination,
      _mapController,
      _mapService,
      _routingService,
    );
  } else {
    MapFunctions.showNotification(
      context,
      'No starting point available. Please enable location.',
      'error',
    );
  }
}

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    MapConfig.colors['EDUCATIONAL_BUILDINGS'] ?? primaryColor,
                  ),
                ),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.exclamationTriangle,
                      size: 60,
                      color: MapConfig.colors['ERROR'] ?? Colors.red,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            MapConfig.colors['PARKING_AREAS'] ?? primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _initializeMap,
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: MapConfig.mapConfig['center'],
                  initialZoom: MapConfig.mapConfig['zoom'],
                  minZoom: MapConfig.mapConfig['minZoom'],
                  maxZoom: MapConfig.mapConfig['maxZoom'],
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                      MapConfig.mapConfig['maxBounds'][0],
                      MapConfig.mapConfig['maxBounds'][1],
                    ),
                  ),
                  onTap: (tapPosition, point) {
                    if (_mapService.routingControl['handleMapClick'] != null) {
                      _mapService.routingControl['handleMapClick'](point);
                    } else if (_mapService.onMapTap != null) {
                      _mapService.onMapTap!(point);
                    }
                  },
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    maxZoom: MapConfig.mapConfig['maxZoom'],
                    minZoom: MapConfig.mapConfig['minZoom'],
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  if (_mapService.universityBorder.isNotEmpty)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _mapService.universityBorder,
                          color: (MapConfig.colors['UNIVERSITY_BORDER'] ??
                                  Colors.grey)
                              .withOpacity(0.1),
                          borderColor:
                              MapConfig.colors['UNIVERSITY_BORDER'] ??
                              Colors.grey,
                          borderStrokeWidth: 2,
                          isDotted: true,
                        ),
                      ],
                    ),
                  if (_mapService.geoJsonPolygons != null)
                    _mapService.geoJsonPolygons!,
                  if (_mapService.geoJsonPolylines != null)
                    _mapService.geoJsonPolylines!,
                  if (_mapService.geoJsonMarkers != null)
                    _mapService.geoJsonMarkers!,
                  if (_mapService.currentPath.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _mapService.currentPath,
                          color:
                              MapConfig.colors['PARKING_AREAS'] ?? Colors.blue,
                          strokeWidth: 5,
                          isDotted: true,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: _mapService.markers),
                  if (_mapService.userMarker != null)
                    MarkerLayer(markers: [_mapService.userMarker!]),
                  if (_mapService.routeArrows.isNotEmpty)
                    MarkerLayer(markers: _mapService.routeArrows),
                  if (_mapService.accuracyCircle != null)
                    _mapService.accuracyCircle!,
                ],
              ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                const SizedBox(height: 10),
                _buildSearchBar(),
                const Spacer(),
                _buildBottomNavigationBar(),
              ],
            ),
          ),
          Positioned(
            top: 100,
            right: 16,
            child: Column(
              children: [
                _buildMapControlButton(
                  icon: FontAwesomeIcons.locationArrow,
                  onPressed:
                      () => MapFunctions.getCurrentLocation(
                        context,
                        _mapController,
                        _mapService,
                        setState,
                      ),
                ),
                const SizedBox(height: 12),
                _buildMapControlButton(
                  icon: FontAwesomeIcons.route,
                  onPressed:
                      () =>
                          _mapService.routingControl['toggleRoutingMode']
                              ?.call(),
                ),
                const SizedBox(height: 12),
                _buildMapControlButton(
                  icon: FontAwesomeIcons.university,
                  onPressed: _showEducationalSidebar,
                ),
                const SizedBox(height: 12),
                _buildMapControlButton(
                  icon: FontAwesomeIcons.mapPin,
                  onPressed: () {
                    MapFunctions.showNotification(
                      context,
                      'Select destination on the map',
                      'info',
                    );
                    setState(() {
                      _mapService.onMapTap = (LatLng point) {
                        _mapService.setDestination(point);
                        _mapService.onMapTap = null;
                        setState(() {});
                      };
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildMapControlButton(
                  icon: FontAwesomeIcons.plus,
                  onPressed: () {
                    final currentZoom = _mapController.zoom;
                    if (currentZoom < MapConfig.mapConfig['maxZoom']) {
                      _mapController.move(
                        _mapController.center,
                        currentZoom + 1,
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildMapControlButton(
                  icon: FontAwesomeIcons.minus,
                  onPressed: () {
                    final currentZoom = _mapController.zoom;
                    if (currentZoom > MapConfig.mapConfig['minZoom']) {
                      _mapController.move(
                        _mapController.center,
                        currentZoom - 1,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const WeatherWidget(),
          if (_isSidebarOpen && _buildingData != null)
            ScaleTransition(
              scale: _sidebarAnimation,
              child: BuildingSidebar(
                buildingData: _buildingData!,
                onClose: _closeSidebar,
                onNavigate: _mapService.setDestination,
              ),
            ),
          if (_isEducationalSidebarOpen)
            ScaleTransition(
              scale: _sidebarAnimation,
              child: EducationalSidebar(
                buildings: _mapService.educationalBuildings,
                onClose: _closeSidebar,
                mapController: _mapController,
                onNavigate: _mapService.setDestination,
              ),
            ),
          CampusAssistantWidget(
            mapService: _mapService,
            mapController: _mapController,
            startRouting: _startRouting,
            showSidebar: _showBuildingSidebar,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MapConfig.colors['EDUCATIONAL_BUILDINGS'] ?? primaryColor,
            MapConfig.colors['PARKING_AREAS'] ?? primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.arrowLeft,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Delta University Map',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Zain',
            ),
          ),
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.microphone,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              MapFunctions.showNotification(
                context,
                'Mic functionality not implemented yet',
                'info',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              _isSearching
                  ? (MapConfig.colors['PARKING_AREAS'] ?? primaryColor)
                  : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    _searchController.text.isEmpty
                        ? 'ابحث عن مكان...'
                        : 'Search for places...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  fontFamily: 'Zain',
                  color: Colors.grey[600],
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.xmark,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                        : null,
              ),
              onSubmitted: _performSearch,
              onChanged: (value) => setState(() {}),
            ),
          ),
          _isSearching
              ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    MapConfig.colors['PARKING_AREAS'] ?? primaryColor,
                  ),
                ),
              )
              : IconButton(
                icon: FaIcon(
                  FontAwesomeIcons.magnifyingGlass,
                  color:
                      MapConfig.colors['EDUCATIONAL_BUILDINGS'] ?? primaryColor,
                ),
                onPressed: () => _performSearch(_searchController.text),
              ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor:
            MapConfig.colors['EDUCATIONAL_BUILDINGS'] ?? primaryColor,
        unselectedItemColor: Colors.grey[600],
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Zain',
        ),
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.circleQuestion),
            label: 'Help',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.circleInfo),
            label: 'About',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              break;
            case 2:
              MapFunctions.showNotification(
                context,
                'Help functionality not implemented yet',
                'info',
              );
              break;
            case 3:
              MapFunctions.showNotification(
                context,
                'About functionality not implemented yet',
                'info',
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: MapConfig.colors['EDUCATIONAL_BUILDINGS'] ?? primaryColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: MapConfig.colors['PARKING_AREAS'] ?? primaryColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}
