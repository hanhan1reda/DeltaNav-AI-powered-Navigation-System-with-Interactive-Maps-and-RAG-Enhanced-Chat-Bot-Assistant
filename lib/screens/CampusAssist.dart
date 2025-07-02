import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'MapConfig.dart';
import 'MapService.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CampusAssistantWidget extends StatefulWidget {
  final MapService mapService;
  final MapController mapController;
  final Function(LatLng) startRouting;
  final Function(Map<String, dynamic>) showSidebar;

  const CampusAssistantWidget({
    super.key,
    required this.mapService,
    required this.mapController,
    required this.startRouting,
    required this.showSidebar,
  });

  @override
  _CampusAssistantWidgetState createState() => _CampusAssistantWidgetState();
}

class _CampusAssistantWidgetState extends State<CampusAssistantWidget> {
  bool _isChatOpen = false;
  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Welcome to Campus Assistant! How can I help you navigate Delta University? Try asking "Where is the Faculty of Engineering?" or "Navigate to the Cafeteria".',
      'sender': 'bot',
      'icon': FontAwesomeIcons.robot,
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        'text': _controller.text,
        'sender': 'user',
        'icon': FontAwesomeIcons.user,
      });
      _isLoading = true;
      _controller.clear();
    });

    // Process the message
    _processMessage(_messages.last['text']);
  }

  void _processMessage(String message) {
    final lowerMessage = message.toLowerCase().trim();
    String response = 'Sorry, I didn\'t understand that. Try asking "Where is [place]?" or "Navigate to [place]".';
    IconData? responseIcon;

    // Check for location-related commands
    if (lowerMessage.contains('where is') || lowerMessage.contains('find') || lowerMessage.contains('show')) {
      final query = lowerMessage
          .replaceAll('where is', '')
          .replaceAll('find', '')
          .replaceAll('show', '')
          .trim();
      final results = widget.mapService.searchFeatures(query);
      if (results.isNotEmpty) {
        final result = results[0];
        final feature = widget.mapService.geoJsonFeatures.firstWhere(
          (f) => f['properties']['name'] == result['id'],
          orElse: () => {},
        );

        final coordinates = feature['geometry']['coordinates'][0];
        final points = coordinates.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        final center = widget.mapService.calculateCenter(points);

        // Move map to location
        widget.mapController.move(center, 18);

        // Add temporary marker
        final searchMarker = Marker(
          point: center,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: MapConfig.colors['PARKING_AREAS']!,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
            ),
            child: Icon(Icons.location_pin, color: Colors.white, size: 16),
          ),
        );
        widget.mapService.markers.add(searchMarker);

        // Remove marker after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              widget.mapService.markers.remove(searchMarker);
            });
          }
        });

        // Show sidebar
        widget.showSidebar({
          'name': result['name'],
          'id': result['id'],
          'description': MapConfig.getFeatureDescription(result['id']),
          'imageUrl': MapConfig.collegeImages[result['id']]?['imageUrl'] ?? 'assets/images/default.jpg',
          'link': MapConfig.links[result['id']] ?? '#',
        });

        response = 'Found ${result['name']} on the map!';
        responseIcon = FontAwesomeIcons.mapPin;
            } else {
        response = 'No results found for "$query". Try another place.';
        responseIcon = FontAwesomeIcons.exclamationTriangle;
      }
    }
    // Check for navigation commands
    else if (lowerMessage.contains('navigate to') || lowerMessage.contains('go to')) {
      final query = lowerMessage
          .replaceAll('navigate to', '')
          .replaceAll('go to', '')
          .trim();
      final results = widget.mapService.searchFeatures(query);
      if (results.isNotEmpty) {
        final result = results[0];
        final feature = widget.mapService.geoJsonFeatures.firstWhere(
          (f) => f['properties']['name'] == result['id'],
          orElse: () => {},
        );

        final coordinates = feature['geometry']['coordinates'][0];
        final points = coordinates.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        final center = widget.mapService.calculateCenter(points);

        // Start routing
        widget.startRouting(center);

        response = 'Starting navigation to ${result['name']}!';
        responseIcon = FontAwesomeIcons.route;
            } else {
        response = 'No results found for "$query". Try another place.';
        responseIcon = FontAwesomeIcons.exclamationTriangle;
      }
    }

    // Add bot response
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': response,
            'sender': 'bot',
            'icon': responseIcon ?? FontAwesomeIcons.robot,
          });
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isChatOpen ? 350 : 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isChatOpen
            ? Column(
                children: [
                  _buildChatHeader(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isBot = message['sender'] == 'bot';
                        return Align(
                          alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isBot
                                  ? Colors.grey[100]
                                  : MapConfig.colors['PARKING_AREAS']!,
                              borderRadius: BorderRadius.circular(20).copyWith(
                                bottomLeft: isBot ? const Radius.circular(0) : null,
                                bottomRight: isBot ? null : const Radius.circular(0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isBot)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FaIcon(
                                      message['icon'] as IconData,
                                      color: MapConfig.colors['EDUCATIONAL_BUILDINGS'],
                                      size: 16,
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    message['text']!,
                                    style: TextStyle(
                                      color: isBot ? Colors.black87 : Colors.white,
                                      fontFamily: 'Zain',
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (!isBot)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: FaIcon(
                                      message['icon'] as IconData,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildChatInput(),
                ],
              )
            : GestureDetector(
                onTap: () => setState(() => _isChatOpen = true),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MapConfig.colors['EDUCATIONAL_BUILDINGS']!,
                        MapConfig.colors['PARKING_AREAS']!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.comments, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'Campus Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Zain',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MapConfig.colors['EDUCATIONAL_BUILDINGS']!,
            MapConfig.colors['PARKING_AREAS']!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Campus Assistant',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Zain',
            ),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.times, color: Colors.white, size: 20),
            onPressed: () => setState(() => _isChatOpen = false),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: _isLoading ? 'Processing...' : 'Ask about a place...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: MapConfig.colors['PARKING_AREAS']!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintStyle: const TextStyle(fontFamily: 'Zain', color: Colors.grey),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MapConfig.colors['PARKING_AREAS'],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FaIcon(
                FontAwesomeIcons.paperPlane,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}