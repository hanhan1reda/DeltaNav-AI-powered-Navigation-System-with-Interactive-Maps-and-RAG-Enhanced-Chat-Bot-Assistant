import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dijkstra/dijkstra.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Define color scheme
const Color primaryColor = Color.fromARGB(182, 130, 178, 233); // Soft blue
const Color primaryDark = Color.fromARGB(238, 69, 119, 152); // Deep calm blue
const Color secondaryColor = Color.fromARGB(255, 241, 192, 123); // Warm orange
const Color backgroundLight = Color(0xFFF0F4F8); // Light gray

class Floor {
  final int id;
  final String name;
  final String shortName;
  final String description;
  final String svgPath;

  Floor({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.svgPath,
  });

  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['id'],
      name: json['name'],
      shortName: json['shortName'],
      description: json['description'],
      svgPath: json['svgPath'],
    );
  }
}

class LocationDetail {
  final String number;
  final String description;

  LocationDetail({required this.number, required this.description});

  factory LocationDetail.fromJson(Map<String, dynamic> json) {
    return LocationDetail(
      number: json['number'],
      description: json['description'],
    );
  }
}

class VertexData {
  final String id;
  final double cx;
  final double cy;
  final String? objectName;
  final String? description;

  VertexData({
    required this.id,
    required this.cx,
    required this.cy,
    this.objectName,
    this.description,
  });

  factory VertexData.fromJson(
    Map<String, dynamic> json,
    List<LocationDetail> locationDetails,
  ) {
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
      id: json['id'],
      cx: json['cx'].toDouble(),
      cy: json['cy'].toDouble(),
      objectName: objectName,
      description: description?.isNotEmpty == true ? description : null,
    );
  }
}

class EdgeData {
  final String id;
  final String from;
  final String to;

  EdgeData({required this.id, required this.from, required this.to});

  factory EdgeData.fromJson(Map<String, dynamic> json) {
    return EdgeData(id: json['id'], from: json['from'], to: json['to']);
  }
}

class GraphData {
  final List<VertexData> vertices;
  final List<EdgeData> edges;

  GraphData({required this.vertices, required this.edges});

  factory GraphData.fromJson(
    Map<String, dynamic> json,
    List<LocationDetail> locationDetails,
  ) {
    return GraphData(
      vertices: (json['vertices'] as List)
          .map((v) => VertexData.fromJson(v, locationDetails))
          .toList(),
      edges: (json['edges'] as List).map((e) => EdgeData.fromJson(e)).toList(),
    );
  }

  Map<String, Map<String, num>> toDijkstraGraph() {
    final graph = <String, Map<String, num>>{};
    for (var vertex in vertices) {
      graph[vertex.id] = {};
    }
    for (var edge in edges) {
      graph[edge.from]![edge.to] = 1;
      graph[edge.to]![edge.from] = 1;
    }
    return graph;
  }
}

class MapState with ChangeNotifier {
  int _currentFloorIndex = 1;
  double _zoom = 1.0;
  Offset _pan = Offset.zero;
  String? _selectedStart;
  String? _selectedEnd;
  List<VertexData> _path = [];
  AnimationController? _pathAnimationController;

  int get currentFloorIndex => _currentFloorIndex;
  double get zoom => _zoom;
  Offset get pan => _pan;
  String? get selectedStart => _selectedStart;
  String? get selectedEnd => _selectedEnd;
  List<VertexData> get path => _path;

  void setFloorIndex(int index) {
    _currentFloorIndex = index;
    notifyListeners();
  }

  void setZoom(double zoom) {
    _zoom = zoom.clamp(0.5, 2.5); // تقليل الحد الأدنى للـ Zoom إلى 0.5
    notifyListeners();
  }

  void zoomIn() {
    setZoom(_zoom + 0.1);
  }

  void zoomOut() {
    setZoom(_zoom - 0.1);
  }

  void setPan(Offset pan) {
    _pan = pan;
    notifyListeners();
  }

  void setSelectedStart(String? start) {
    _selectedStart = start;
    notifyListeners();
  }

  void setSelectedEnd(String? end) {
    _selectedEnd = end;
    notifyListeners();
  }

  void setPath(List<VertexData> path, TickerProvider vsync) {
    _path = path;
    if (_pathAnimationController == null) {
      _pathAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: vsync,
      )..forward();
    } else {
      _pathAnimationController!.reset();
      _pathAnimationController!.forward();
    }
    notifyListeners();
  }

  void resetPath() {
    _selectedStart = null;
    _selectedEnd = null;
    _path = [];
    _pathAnimationController?.dispose();
    _pathAnimationController = null;
    notifyListeners();
  }
}

class IndoorMapScreen extends StatelessWidget {
  const IndoorMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapState(),
      child: const IndoorMapScreenContent(),
    );
  }
}

class IndoorMapScreenContent extends StatefulWidget {
  const IndoorMapScreenContent({super.key});

  @override
  _IndoorMapScreenContentState createState() => _IndoorMapScreenContentState();
}

class _IndoorMapScreenContentState extends State<IndoorMapScreenContent>
    with TickerProviderStateMixin {
  List<Floor> floors = [];
  GraphData? graphData;
  List<LocationDetail> locationDetails = [];
  bool isPanning = false;
  Offset? panStart;
  TextEditingController startController = TextEditingController();
  TextEditingController endController = TextEditingController();
  Offset? lastTapPosition;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _loadData() async {
    try {
      await Future.wait([
        _loadFloors(),
        _loadGraphData(),
        _loadLocationDetails(),
      ]);
      return true;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
      });
      return false;
    }
  }

  Future<void> _loadFloors() async {
    final String jsonString = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/Indoor/floors.json');
    final List<dynamic> jsonData = jsonDecode(jsonString);
    floors = jsonData.map((json) => Floor.fromJson(json)).toList();
  }

  Future<void> _loadGraphData() async {
    final String jsonString = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/Indoor/4th.json');
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    graphData = GraphData.fromJson(jsonData, locationDetails);
  }

  Future<void> _loadLocationDetails() async {
    final String jsonString = await DefaultAssetBundle.of(
      context,
    ).loadString('assets/Indoor/LocationDetails.json');
    final List<dynamic> jsonData = jsonDecode(jsonString);
    locationDetails =
        jsonData.map((json) => LocationDetail.fromJson(json)).toList();
  }

  void handleVertexClick(VertexData vertex, BuildContext context) {
    final mapState = Provider.of<MapState>(context, listen: false);
    if (mapState.selectedStart == null) {
      mapState.setSelectedStart(vertex.id);
      startController.text =
          vertex.description ?? vertex.objectName ?? vertex.id;
    } else if (mapState.selectedEnd == null &&
        vertex.id != mapState.selectedStart) {
      mapState.setSelectedEnd(vertex.id);
      endController.text = vertex.description ?? vertex.objectName ?? vertex.id;
      if (graphData != null) {
        final dijkstraGraph = graphData!.toDijkstraGraph();
        final pathIds = Dijkstra.findPathFromGraph(
          dijkstraGraph,
          mapState.selectedStart!,
          mapState.selectedEnd!,
        );
        final path =
            pathIds
                .map((id) => graphData!.vertices.firstWhere((v) => v.id == id))
                .toList();
        mapState.setPath(path, this);
        Fluttertoast.showToast(
          msg: "Path calculated!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: primaryColor,
          textColor: Colors.white,
        );
      }
    }
  }

  VertexData? getVertexAtPosition(Offset position, double zoom, Offset pan) {
    if (graphData == null) return null;
    final inverseZoom = 1 / zoom;
    final adjustedX = (position.dx - pan.dx) * inverseZoom;
    final adjustedY = (position.dy - pan.dy) * inverseZoom;

    const double clickRadius = 15.0;
    for (var vertex in graphData!.vertices) {
      final dx = adjustedX - vertex.cx;
      final dy = adjustedY - vertex.cy;
      if (dx * dx + dy * dy < clickRadius * clickRadius) {
        return vertex;
      }
    }
    return null;
  }

  @override
  void dispose() {
    Provider.of<MapState>(
      context,
      listen: false,
    )._pathAnimationController?.dispose();
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = Provider.of<MapState>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          leading: Center(
            child: IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.bars,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/DeltaLogo.png', height: 40, width: 40),
              const SizedBox(width: 12),
              const Text(
                'DeltaNav',
                style: TextStyle(
                  fontFamily: 'Zain',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  primaryDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: MapDrawer(
        floors: floors,
        graphData: graphData,
        startController: startController,
        endController: endController,
        onFloorSelected: (index) {
          mapState.setFloorIndex(index);
        },
        onSearch: (controller, isStart) {
          if (graphData == null) return;
          final query = controller.text.toLowerCase();
          final vertex = graphData!.vertices.firstWhere(
            (v) =>
                (v.description?.toLowerCase().contains(query) ?? false) ||
                (v.objectName?.toLowerCase().contains(query) ?? false) ||
                v.id.toLowerCase().contains(query),
            orElse: () => graphData!.vertices.first,
          );
          if (isStart) {
            mapState.setSelectedStart(vertex.id);
            controller.text =
                vertex.description ?? vertex.objectName ?? vertex.id;
          } else {
            mapState.setSelectedEnd(vertex.id);
            controller.text =
                vertex.description ?? vertex.objectName ?? vertex.id;
          }
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundLight, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<bool>(
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              );
            } else if (snapshot.hasError || _errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.exclamationTriangle,
                      size: 60,
                      color: Color.fromARGB(255, 222, 125, 118),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage ?? 'An error occurred while loading data',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return GestureDetector(
                onScaleStart: (details) {
                  setState(() {
                    isPanning = true;
                    panStart = details.focalPoint;
                  });
                },
                onScaleUpdate: (details) {
                  mapState.setZoom(details.scale * mapState.zoom);
                  if (isPanning && panStart != null) {
                    mapState.setPan(
                      mapState.pan + (details.focalPoint - panStart!),
                    );
                    panStart = details.focalPoint;
                  }
                },
                onScaleEnd: (details) {
                  setState(() {
                    isPanning = false;
                    panStart = null;
                  });
                },
                onTapUp: (details) {
                  lastTapPosition = details.localPosition;
                  final vertex = getVertexAtPosition(
                    details.localPosition,
                    mapState.zoom,
                    mapState.pan,
                  );
                  if (vertex != null) {
                    handleVertexClick(vertex, context);
                  }
                },
                onLongPressUp: () {
                  if (lastTapPosition == null) return;
                  final vertex = getVertexAtPosition(
                    lastTapPosition!,
                    mapState.zoom,
                    mapState.pan,
                  );
                  if (vertex != null) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: primaryDark,
                        title: Text(
                          vertex.objectName ?? vertex.id,
                          style: const TextStyle(
                            fontFamily: 'Zain',
                            color: Colors.white,
                          ),
                        ),
                        content: Text(
                          vertex.description ?? 'No description available',
                          style: const TextStyle(
                            fontFamily: 'Knewave',
                            color: Colors.white70,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Close',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Stack(
                  children: [
                    Transform(
                      transform: Matrix4.identity()
                        ..scale(mapState.zoom)
                        ..translate(
                          mapState.pan.dx / mapState.zoom,
                          mapState.pan.dy / mapState.zoom,
                        ),
                      child: SizedBox(
                        width: screenWidth,
                        height: screenHeight,
                        child: SvgPicture.asset(
                          floors[mapState.currentFloorIndex].svgPath,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                    if (mapState.path.isNotEmpty)
                      AnimatedBuilder(
                        animation: mapState._pathAnimationController!,
                        builder: (context, child) {
                          return Transform(
                            transform: Matrix4.identity()
                              ..scale(mapState.zoom)
                              ..translate(
                                mapState.pan.dx / mapState.zoom,
                                mapState.pan.dy / mapState.zoom,
                              ),
                            child: CustomPaint(
                              painter: CreativePathPainter(
                                path: mapState.path,
                                animationValue:
                                    mapState._pathAnimationController!.value,
                              ),
                              child: Container(),
                            ),
                          );
                        },
                      ),
                    Transform(
                      transform: Matrix4.identity()
                        ..scale(mapState.zoom)
                        ..translate(
                          mapState.pan.dx / mapState.zoom,
                          mapState.pan.dy / mapState.zoom,
                        ),
                      child: CustomPaint(
                        painter: MarkerPainter(
                          vertices: graphData!.vertices,
                          selectedStart: mapState.selectedStart,
                          selectedEnd: mapState.selectedEnd,
                        ),
                        child: Container(),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildControlButton(
            icon: FontAwesomeIcons.bars,
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          const SizedBox(height: 10),
          _buildControlButton(
            icon: FontAwesomeIcons.searchPlus,
            onPressed: () {
              Provider.of<MapState>(context, listen: false).zoomIn();
              Fluttertoast.showToast(
                msg: "Zoom In!",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: primaryColor,
                textColor: Colors.white,
              );
            },
          ),
          const SizedBox(height: 10),
          _buildControlButton(
            icon: FontAwesomeIcons.searchMinus,
            onPressed: () {
              Provider.of<MapState>(context, listen: false).zoomOut();
              Fluttertoast.showToast(
                msg: "Zoom Out!",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: primaryColor,
                textColor: Colors.white,
              );
            },
          ),
          const SizedBox(height: 10),
          _buildControlButton(
            icon: FontAwesomeIcons.redo,
            onPressed: () {
              Provider.of<MapState>(context, listen: false).resetPath();
              startController.clear();
              endController.clear();
              Fluttertoast.showToast(
                msg: "Path reset!",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: const Color.fromARGB(255, 220, 152, 148),
                textColor: Colors.white,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
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
          border: Border.all(color: primaryColor, width: 2),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: FaIcon(icon, color: secondaryColor, size: 24)),
      ),
    );
  }
}

class MapDrawer extends StatelessWidget {
  final List<Floor> floors;
  final GraphData? graphData;
  final TextEditingController startController;
  final TextEditingController endController;
  final Function(int) onFloorSelected;
  final Function(TextEditingController, bool) onSearch;

  const MapDrawer({
    super.key,
    required this.floors,
    this.graphData,
    required this.startController,
    required this.endController,
    required this.onFloorSelected,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/DeltaLogo.png',
                    height: 60,
                    width: 60,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'DeltaNav',
                    style: TextStyle(
                      fontFamily: 'Zain',
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ExpansionTile(
              leading: const FaIcon(
                FontAwesomeIcons.route,
                color: Colors.white,
              ),
              title: const Text(
                'Route',
                style: TextStyle(fontFamily: 'Zain', color: Colors.white),
              ),
              initiallyExpanded: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: startController,
                        decoration: InputDecoration(
                          labelText: 'Starting Point',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: const OutlineInputBorder(),
                          prefixIcon: const FaIcon(
                            FontAwesomeIcons.mapMarkerAlt,
                            color: Colors.white,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        onChanged: (value) {
                          onSearch(startController, true);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: endController,
                        decoration: InputDecoration(
                          labelText: 'Destination',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: const OutlineInputBorder(),
                          prefixIcon: const FaIcon(
                            FontAwesomeIcons.mapMarkerAlt,
                            color: Colors.white,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        onChanged: (value) {
                          onSearch(endController, false);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ExpansionTile(
              leading: const FaIcon(
                FontAwesomeIcons.building,
                color: Colors.white,
              ),
              title: const Text(
                'Floor',
                style: TextStyle(fontFamily: 'Zain', color: Colors.white),
              ),
              children:
                  floors
                      .map(
                        (floor) => ListTile(
                          title: Text(
                            floor.name,
                            style: const TextStyle(
                              fontFamily: 'Zain',
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            floor.description,
                            style: const TextStyle(
                              fontFamily: 'Knewave',
                              color: Colors.white70,
                            ),
                          ),
                          onTap: () {
                            onFloorSelected(floor.id);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class CreativePathPainter extends CustomPainter {
  final List<VertexData> path;
  final double animationValue;

  CreativePathPainter({required this.path, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          secondaryColor.withOpacity(0.8),
          Colors.white.withOpacity(0.2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10)
      ..color = secondaryColor.withOpacity(0.3);

    final animatedPath = Path();
    for (var i = 0; i < (path.length * animationValue).floor(); i++) {
      final vertex = path[i];
      if (i == 0) {
        animatedPath.moveTo(vertex.cx, vertex.cy);
      } else {
        final controlPoint = Offset(
          (path[i - 1].cx + vertex.cx) / 2,
          (path[i - 1].cy + vertex.cy) / 2 + 50 * (i % 2 == 0 ? 1 : -1),
        );
        animatedPath.quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          vertex.cx,
          vertex.cy,
        );
      }
    }

    canvas.drawPath(animatedPath, paint);
    canvas.drawPath(animatedPath, glowPaint);

    final dotPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;
    for (var i = 0; i < (path.length * animationValue).floor(); i++) {
      canvas.drawCircle(Offset(path[i].cx, path[i].cy), 6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MarkerPainter extends CustomPainter {
  final List<VertexData> vertices;
  final String? selectedStart;
  final String? selectedEnd;

  MarkerPainter({required this.vertices, this.selectedStart, this.selectedEnd});

  @override
  void paint(Canvas canvas, Size size) {
    final defaultPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final startPaint = Paint()
      ..shader = const LinearGradient(
        colors: [primaryColor, primaryDark],
      ).createShader( Rect.fromCircle(center: Offset(0, 0), radius: 12))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final endPaint = Paint()
      ..shader = LinearGradient(
        colors: [secondaryColor, Colors.orange.withOpacity(0.7)],
      ).createShader( Rect.fromCircle(center: Offset(0, 0), radius: 12))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (var vertex in vertices) {
      final paint = vertex.id == selectedStart
          ? startPaint
          : vertex.id == selectedEnd
              ? endPaint
              : defaultPaint;
      final radius = vertex.id == selectedStart || vertex.id == selectedEnd
          ? 12.0
          : 8.0;
      canvas.drawCircle(Offset(vertex.cx, vertex.cy), radius, paint);
      if (vertex.id == selectedStart || vertex.id == selectedEnd) {
        canvas.drawCircle(
          Offset(vertex.cx, vertex.cy),
          radius / 2,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}