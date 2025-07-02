import 'dart:typed_data';
import 'package:delta_n/screens/MapScreen.dart';
import 'package:delta_n/screens/ProfileScreen.dart';
import 'package:flutter/material.dart';
import 'ChatBox.dart';
import 'GetSupport.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'Indoor.dart/Indoor_Map.dart';
import 'NotesScreen.dart';

class HomeScreen extends StatefulWidget {
  static const Color primaryColor = Color(0xFF32689B);
  static const Color accentColor = Color(0xFFF6BD69);

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentImageIndex = 0;
  Uint8List? profileImageBytes;
  bool _isImageLoading = false;
  final List<String> _images = [
    "assets/images/slide1.jpg",
    "assets/images/slide2.jpg",
    "assets/images/slide3.jpeg",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
    _controller.addListener(() {
      setState(() {
        _currentImageIndex =
            (_controller.value * _images.length).floor() % _images.length;
      });
    });
    _loadProfileImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    setState(() {
      _isImageLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final imageString = prefs.getString('profile_image');
    if (imageString != null) {
      setState(() {
        profileImageBytes = base64Decode(imageString);
        _isImageLoading = false;
      });
    } else {
      setState(() {
        _isImageLoading = false;
      });
    }
  }

  String _getUserName(String? userId) {
    final Map<String, String> userMapping = {
      "4211253": "Haneen Reda Zehry",
      "4211070": "Arwa Abo-Attia",
      "112233": "Abdullah Adel",
      "445566": "Ahmed Samir",
      "778899": "Ahmed Abdelsalam",
      "990011": "Bassel Darwesh",
    };
    return userMapping[userId] ?? "Guest";
  }

  @override
  Widget build(BuildContext context) {
    final String? userId =
        ModalRoute.of(context)?.settings.arguments as String?;

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        primaryColor: HomeScreen.primaryColor,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HomeScreen.primaryColor.withOpacity(0.5),
                      Colors.white,
                      HomeScreen.accentColor.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/pattern.png"),
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                  ),
                ),
              ),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(
                                "assets/images/DeltaLogo.png",
                                height: 48,
                                fit: BoxFit.contain,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen(),
                                      settings: RouteSettings(
                                        arguments: userId,
                                      ),
                                    ),
                                  ).then((_) => _loadProfileImage());
                                },
                                child: AnimatedScale(
                                  scale: _isImageLoading ? 0.95 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.7),
                                      gradient: RadialGradient(
                                        colors: [
                                          HomeScreen.accentColor.withOpacity(
                                            0.8,
                                          ),
                                          HomeScreen.primaryColor.withOpacity(
                                            0.8,
                                          ),
                                        ],
                                        center: Alignment.center,
                                        radius: 0.9,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: Offset(0, 6),
                                          spreadRadius: 1,
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: Offset(-3, -3),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundColor: Colors.transparent,
                                          backgroundImage:
                                              profileImageBytes != null
                                                  ? MemoryImage(
                                                    profileImageBytes!,
                                                  )
                                                  : null,
                                          child:
                                              profileImageBytes == null
                                                  ? Icon(
                                                    Icons.person_rounded,
                                                    size: 30,
                                                    color:
                                                        HomeScreen.primaryColor,
                                                  )
                                                  : null,
                                        ),
                                        if (_isImageLoading)
                                          CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  HomeScreen.accentColor,
                                                ),
                                            strokeWidth: 2,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  HomeScreen.primaryColor.withOpacity(0.95),
                                  HomeScreen.accentColor.withOpacity(0.95),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: Offset(0, 6),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  AnimatedSwitcher(
                                    duration: Duration(milliseconds: 500),
                                    transitionBuilder:
                                        (child, animation) => FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                    child: Image.asset(
                                      _images[_currentImageIndex],
                                      key: ValueKey<int>(_currentImageIndex),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 180,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        _images.length,
                                        (index) => AnimatedContainer(
                                          duration: Duration(milliseconds: 300),
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          width:
                                              index == _currentImageIndex
                                                  ? 12
                                                  : 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                index == _currentImageIndex
                                                    ? HomeScreen.accentColor
                                                    : Colors.white.withOpacity(
                                                      0.6,
                                                    ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 500),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: HomeScreen.primaryColor,
                                fontFamily: 'Zain',
                                letterSpacing: 0.8,
                                shadows: [
                                  Shadow(
                                    color: HomeScreen.accentColor.withOpacity(
                                      0.5,
                                    ),
                                    blurRadius: 8,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Text("Hello, ${_getUserName(userId)}!"),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Welcome to DeltaNav!",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: HomeScreen.primaryColor,
                              fontFamily: 'Zain',
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Navigate Delta University with ease using AI-powered tools.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              fontFamily: 'Zain',
                              height: 1.4,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapScreen(),
                                  ),
                                );
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      HomeScreen.primaryColor,
                                      HomeScreen.accentColor,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: HomeScreen.accentColor.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 15,
                                      offset: Offset(0, 6),
                                      spreadRadius: 1,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: AnimatedScale(
                                  scale: 1.0,
                                  duration: Duration(milliseconds: 200),
                                  child: Text(
                                    "Start Navigating",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontFamily: 'Zain',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      delegate: SliverChildListDelegate([
                        _buildFeatureCard(
                          title: "Campus Map",
                          imagePath: "assets/images/location4.png",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapScreen(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          title: "AR Navigation",
                          imagePath: "assets/images/74-navigation.gif",
                          onTap: () {},
                        ),
                        _buildFeatureCard(
                          title: "Smart AI Guide",
                          imagePath: "assets/images/ARiCONn.gif",
                          onTap: () {},
                        ),
                        _buildFeatureCard(
                          title: "Indoor Navigation",
                          imagePath: "assets/images/indoor.png",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IndoorMapScreen(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          title: "Need Help?",
                          imagePath: "assets/images/Support.jpg",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SupportScreen(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          title: "About Us",
                          imagePath: "assets/images/about.png",
                          onTap: () => _showAboutUsDialog(context),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: Offset(0, -4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavButton(Icons.home, "Home", () {}),
              _buildNavButton(Icons.map, "Map", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapScreen()),
                );
              }),
              _buildNavButton(Icons.play_arrow, "Start", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapScreen()),
                );
              }, isHighlighted: true),
              _buildNavButton(Icons.help, "Help", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SupportScreen()),
                );
              }),
              _buildNavButton(
                Icons.info,
                "About",
                () => _showAboutUsDialog(context),
              ),
            ],
          ),
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 500),
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: Duration(milliseconds: 300),
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotesScreen(),
                          ),
                        );
                      },
                      backgroundColor: HomeScreen.primaryColor,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      mini: true,
                      child: Icon(
                        Icons.note_alt,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 600),
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: Duration(milliseconds: 300),
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatScreen()),
                        );
                      },
                      backgroundColor: HomeScreen.primaryColor,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.chat, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String imagePath,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: Matrix4.identity()..rotateZ(0.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(4, 4),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(-4, -4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                height: 95,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      height: 95,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: HomeScreen.primaryColor,
                        size: 40,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: HomeScreen.primaryColor,
                  fontFamily: 'Zain',
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    bool isHighlighted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(isHighlighted ? 12 : 10),
          decoration: BoxDecoration(
            color: isHighlighted ? HomeScreen.accentColor : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow:
                isHighlighted
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ]
                    : null,
          ),
          child: Icon(
            icon,
            color: isHighlighted ? Colors.white : HomeScreen.primaryColor,
            size: isHighlighted ? 28 : 26,
          ),
        ),
      ),
    );
  }
}

void _showAboutUsDialog(BuildContext context) {
  const Color primaryColor = Color(0xFF387594);

  showDialog(
    context: context,
    builder:
        (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.grey[100]!.withOpacity(0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "About Us",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          fontFamily: 'Zain',
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        "Meet the brilliant minds behind DeltaNav!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontFamily: 'Zain',
                          height: 1.4,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.8,
                        children: [
                          _buildTeamMember(
                            "Abullah Adel",
                            "assets/images/عبد الله عادل.jpg",
                          ),
                          _buildTeamMember(
                            "Ahmed Samir",
                            "assets/images/أحمد سمير.jpg",
                          ),
                          _buildTeamMember(
                            "Haneen Reda",
                            "assets/images/حنين رضا .jpg",
                          ),
                          _buildTeamMember(
                            "Arwa Abu-Attia",
                            "assets/images/أروى عطية.jpg",
                          ),
                          _buildTeamMember(
                            "Bassel Darwesh",
                            "assets/images/باسل درويش.jpg",
                          ),
                          _buildTeamMember(
                            "Ahmed Abdellsalam",
                            "assets/images/أحمد عبد السلام.jpg",
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -12,
                top: -12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
  );
}

Widget _buildTeamMember(String name, String imagePath) {
  const Color primaryColor = Color(0xFF387594);

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              Image.asset(
                imagePath,
                width: 95,
                height: 95,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: 95,
                      height: 95,
                      color: Colors.grey[200],
                      child: Icon(Icons.person, size: 55, color: primaryColor),
                    ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {},
                    splashColor: primaryColor.withOpacity(0.2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: 10),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: primaryColor,
            fontFamily: 'Zain',
            letterSpacing: 0.5,
          ),
        ),
      ),
    ],
  );
}
