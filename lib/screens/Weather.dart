import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  bool _isSidebarOpen = false;
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _nextHourWeather;
  String? _errorMessage;
  Timer? _refreshTimer;

  static const String _apiKey = "plQqewi5hwt3SzQjSEggD7UQFD4f5hZv";
  static const double _lat = 31.4408;
  static const double _lon = 31.4939;
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) => _fetchWeather());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    const url = 'https://api.tomorrow.io/v4/weather/forecast?location=$_lat,$_lon&apikey=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['timelines']?['hourly'] != null && data['timelines']['hourly'].length >= 2) {
          setState(() {
            _currentWeather = data['timelines']['hourly'][0]['values'];
            _nextHourWeather = data['timelines']['hourly'][1]['values'];
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage = 'No weather data found.';
            _currentWeather = null;
            _nextHourWeather = null;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load weather data: ${response.statusCode}';
          _currentWeather = null;
          _nextHourWeather = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading weather data: $e';
        _currentWeather = null;
        _nextHourWeather = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 600 ? 320.0 : screenWidth * 0.85;

    return Stack(
      children: [
        Positioned(
          top: 150,
          left: 16,
          child: _isSidebarOpen
              ? const SizedBox.shrink()
              : FloatingActionButton(
                  backgroundColor: primaryColor,
                  onPressed: () {
                    setState(() {
                      _isSidebarOpen = true;
                      _fetchWeather();
                    });
                  },
                  child: const FaIcon(FontAwesomeIcons.cloudSun, color: Colors.white),
                ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: _isSidebarOpen ? 0 : -sidebarWidth,
          top: 100,
          bottom: 100,
          child: Container(
            width: sidebarWidth,
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                Expanded(
                  child: _buildWeatherContent(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Weather Forecast',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Zain',
            ),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white, size: 20),
            onPressed: () {
              setState(() => _isSidebarOpen = false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(fontSize: 16, color: Colors.red, fontFamily: 'Zain'),
        ),
      );
    }

    if (_currentWeather == null || _nextHourWeather == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeatherCard(
            title: 'Current Hour',
            temperature: _currentWeather!['temperature'],
            humidity: _currentWeather!['humidity'],
            windSpeed: _currentWeather!['windSpeed'],
            cloudCover: _currentWeather!['cloudCover'],
          ),
          const SizedBox(height: 16),
          _buildWeatherCard(
            title: 'Next Hour Forecast',
            temperature: _nextHourWeather!['temperature'],
            humidity: _nextHourWeather!['humidity'],
            windSpeed: _nextHourWeather!['windSpeed'],
            cloudCover: _nextHourWeather!['cloudCover'],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard({
    required String title,
    required num temperature,
    required num humidity,
    required num windSpeed,
    required num cloudCover,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              fontFamily: 'Zain',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.temperatureHalf, color: secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Temperature: $temperature°C',
                style: const TextStyle(fontSize: 14, fontFamily: 'Zain'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.droplet, color: secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Humidity: $humidity%',
                style: const TextStyle(fontSize: 14, fontFamily: 'Zain'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.wind, color: secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Wind Speed: $windSpeed m/s',
                style: const TextStyle(fontSize: 14, fontFamily: 'Zain'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.cloud, color: secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cloud Cover: $cloudCover%',
                style: const TextStyle(fontSize: 14, fontFamily: 'Zain'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}