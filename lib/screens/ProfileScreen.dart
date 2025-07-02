import 'dart:math';
import 'package:delta_n/screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF32689B);
  static const Color accentColor = Color(0xFFF6BD69);
  static const Color secondaryColor = Color(0xFF4A90E2);
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // User data
  String? userId;
  String userName = "";
  String email = "example@email.com";
  String password = "********";
  bool isDarkMode = false;
  bool isLaptopMode = false;
  bool notificationsEnabled = true;
  Color themeColor = primaryColor;
  Uint8List? profileImageBytes;
  bool _isImageLoading = false;

  // Controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // User data mapping
  Map<String, dynamic> _getUserData(String? userId) {
    final Map<String, Map<String, String>> userMapping = {
      "4211253": {"name": "Haneen", "email": "haneen.re@delta.edu"},
      "654321": {"name": "Sara Mohamed", "email": "sara.mohamed@delta.edu"},
      "112233": {"name": "Omar Hassan", "email": "omar.hassan@delta.edu"},
      "445566": {"name": "Laila Ali", "email": "laila.ali@delta.edu"},
      "778899": {"name": "Youssef Gamal", "email": "youssef.gamal@delta.edu"},
      "990011": {"name": "Nada Ibrahim", "email": "nada.ibrahim@delta.edu"},
    };
    return userMapping[userId] ?? {"name": "Guest", "email": "guest@delta.edu"};
  }

  // Motivational quotes
  final List<String> motivationalQuotes = [
    "Empower your journey with DeltaNav!",
    "Navigate success, one step at a time.",
    "Your campus companion, always by your side.",
    "Explore, learn, and thrive with DeltaNav.",
    "Unleash your potential with smart navigation.",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _loadProfileImage();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Load profile image from SharedPreferences
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imageString = prefs.getString('profile_image');
    if (imageString != null) {
      setState(() {
        profileImageBytes = base64Decode(imageString);
      });
    }
  }

  // Save profile image to SharedPreferences
  Future<void> _saveProfileImage(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    final imageString = base64Encode(bytes);
    await prefs.setString('profile_image', imageString);
  }

  @override
  Widget build(BuildContext context) {
    userId = ModalRoute.of(context)?.settings.arguments as String?;
    var userData = _getUserData(userId);
    if (userName.isEmpty) {
      userName = userData["name"];
      email = userData["email"];
      _nameController.text = userName;
      _emailController.text = email;
      _passwordController.text = password;
    }

    return Theme(
      data: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: themeColor,
        scaffoldBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      ),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Glassmorphic background with subtle pattern
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [Colors.black87, Colors.grey[900]!]
                        : [
                            themeColor.withOpacity(0.4),
                            Colors.white,
                            accentColor.withOpacity(0.3)
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.6, 1.0],
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
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          // Profile avatar with glassmorphic effect
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: GestureDetector(
                              onTap: _changeProfileImage,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDarkMode
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.white.withOpacity(0.3),
                                      gradient: RadialGradient(
                                        colors: [
                                          accentColor.withOpacity(0.8),
                                          themeColor.withOpacity(0.8)
                                        ],
                                        center: Alignment.center,
                                        radius: 0.9,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 30,
                                          offset: Offset(0, 12),
                                          spreadRadius: 3,
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withOpacity(isDarkMode ? 0.15 : 0.4),
                                          blurRadius: 20,
                                          offset: Offset(-8, -8),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 90,
                                      backgroundColor: Colors.transparent,
                                      backgroundImage: profileImageBytes != null
                                          ? MemoryImage(profileImageBytes!)
                                          : null,
                                      child: profileImageBytes == null
                                          ? Icon(
                                              Icons.person_rounded,
                                              size: 100,
                                              color: themeColor.withOpacity(0.8),
                                            )
                                          : null,
                                    ),
                                  ),
                                  if (_isImageLoading)
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                      strokeWidth: 3,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          // User name with refined typography
                          AnimatedDefaultTextStyle(
                            duration: Duration(milliseconds: 400),
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: isDarkMode ? Colors.white : themeColor,
                              fontFamily: 'Zain',
                              letterSpacing: 1.0,
                              shadows: [
                                Shadow(
                                  color: accentColor.withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: Offset(4, 4),
                                ),
                              ],
                            ),
                            child: Text(userName),
                          ),
                          SizedBox(height: 8),
                          Text(
                            userName == "Guest" ? email : "Delta University Student",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontFamily: 'Zain',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 32),
                          // Info card with glassmorphic design
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[850]!.withOpacity(0.8)
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 25,
                                  offset: Offset(8, 8),
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.3),
                                  blurRadius: 25,
                                  offset: Offset(-8, -8),
                                  spreadRadius: 3,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              backgroundBlendMode: BlendMode.overlay,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildEditableInfoRow("Name", _nameController),
                                SizedBox(height: 20),
                                _buildEditableInfoRow("Email", _emailController),
                                SizedBox(height: 20),
                                _buildEditableInfoRow(
                                  "Password",
                                  _passwordController,
                                  isPassword: true,
                                ),
                                SizedBox(height: 28),
                                _buildSwitchRow("Dark Mode", isDarkMode, (value) {
                                  setState(() => isDarkMode = value);
                                }),
                                SizedBox(height: 20),
                                _buildSwitchRow("Laptop Mode", isLaptopMode, (value) {
                                  setState(() => isLaptopMode = value);
                                }),
                                SizedBox(height: 20),
                                _buildSwitchRow("Notifications", notificationsEnabled, (value) {
                                  _toggleNotifications(value);
                                }),
                                SizedBox(height: 28),
                                _buildOptionRow(
                                  "Custom Theme",
                                  Icons.palette_rounded,
                                  _changeTheme,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 32),
                          // Logout button with ripple effect
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(40),
                              onTap: _confirmLogout,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 70, vertical: 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [themeColor, themeColor.withOpacity(0.8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: Offset(0, 8),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.logout_rounded, size: 26, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text(
                                      "Logout",
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Zain',
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 32),
                          // Motivational quote with adjusted size and animation
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 800),
                              style: TextStyle(
                                fontSize: 14, // Reduced font size
                                fontStyle: FontStyle.italic,
                                color: isDarkMode ? accentColor : themeColor,
                                fontFamily: 'Knewave',
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: isDarkMode ? Colors.black54 : Colors.grey[300]!,
                                    blurRadius: 8,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                motivationalQuotes[Random().nextInt(motivationalQuotes.length)],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Back button with glassmorphic design
              Positioned(
                top: 16,
                left: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode
                            ? Colors.grey[850]!.withOpacity(0.8)
                            : Colors.white.withOpacity(0.7),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: Offset(4, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.3),
                            blurRadius: 15,
                            offset: Offset(-4, -4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: themeColor,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableInfoRow(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            fontFamily: 'Zain',
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(
          width: 230,
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : themeColor,
              fontFamily: 'Zain',
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.grey[800]!.withOpacity(0.8)
                  : Colors.grey[200]!.withOpacity(0.9),
              contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              suffixIcon: isPassword
                  ? Icon(
                      Icons.lock_rounded,
                      color: isDarkMode ? Colors.grey[400] : themeColor,
                      size: 20,
                    )
                  : null,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
            onSubmitted: (value) {
              setState(() {
                if (label == "Name") userName = value;
                if (label == "Email") email = value;
                if (label == "Password") password = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$label updated successfully!"),
                  backgroundColor: themeColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  margin: EdgeInsets.all(16),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            fontFamily: 'Zain',
            letterSpacing: 0.5,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: accentColor,
          activeTrackColor: themeColor.withOpacity(0.6),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[700],
          materialTapTargetSize: MaterialTapTargetSize.padded,
        ),
      ],
    );
  }

  Widget _buildOptionRow(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                  fontFamily: 'Zain',
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                icon,
                color: isDarkMode ? accentColor : themeColor,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeProfileImage() async {
    try {
      setState(() {
        _isImageLoading = true;
      });
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          profileImageBytes = bytes;
          _isImageLoading = false;
        });
        await _saveProfileImage(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profile picture updated successfully!"),
            backgroundColor: themeColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.all(16),
          ),
        );
      } else {
        setState(() {
          _isImageLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isImageLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load image. Please try again."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _changeTheme() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: isDarkMode
            ? Colors.grey[850]!.withOpacity(0.9)
            : Colors.grey[100]!.withOpacity(0.9),
        title: Text(
          "Choose Theme Color",
          style: TextStyle(
            fontFamily: 'Zain',
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : themeColor,
            fontSize: 20,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(8),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildColorOption(Colors.blueAccent, "Blue"),
              _buildColorOption(Colors.greenAccent, "Green"),
              _buildColorOption(Colors.purpleAccent, "Purple"),
              _buildColorOption(Colors.redAccent, "Red"),
              _buildColorOption(Colors.orangeAccent, "Orange"),
              _buildColorOption(Colors.tealAccent, "Teal"),
              _buildColorOption(Colors.pinkAccent, "Pink"),
              _buildColorOption(primaryColor, "Default"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: themeColor,
                fontFamily: 'Zain',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color, String name) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          setState(() {
            themeColor = color;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Theme changed to $name!"),
              backgroundColor: themeColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: EdgeInsets.all(16),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                fontFamily: 'Zain',
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 12,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleNotifications(bool value) {
    setState(() {
      notificationsEnabled = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notificationsEnabled
              ? "Notifications enabled!"
              : "Notifications disabled!",
        ),
        backgroundColor: themeColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: isDarkMode
            ? Colors.grey[850]!.withOpacity(0.9)
            : Colors.grey[100]!.withOpacity(0.9),
        title: Text(
          "Confirm Logout",
          style: TextStyle(
            fontFamily: 'Zain',
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : themeColor,
            fontSize: 20,
          ),
        ),
        content: Text(
          "Are you sure you want to logout?",
          style: TextStyle(
            fontFamily: 'Zain',
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: themeColor,
                fontFamily: 'Zain',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text(
              "Logout",
              style: TextStyle(
                color: Colors.redAccent,
                fontFamily: 'Zain',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}