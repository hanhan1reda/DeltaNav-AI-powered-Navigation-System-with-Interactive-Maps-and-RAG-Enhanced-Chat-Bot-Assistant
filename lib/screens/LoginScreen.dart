import 'package:delta_n/screens/SignUpScreen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'HomeScreen.dart';

class LoginScreen extends StatefulWidget {
  static const Color primaryColor = Color(0xFF1E88E5); // Blue
  static const Color accentColor = Color(0xFFFF6D00); // Orange

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open $url")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/delta2.jpg"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.2),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LoginScreen.primaryColor.withOpacity(0.7),
                  LoginScreen.accentColor.withOpacity(0.6),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          // Main Content
          Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          child: Container(
                            padding: EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.98),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: Offset(0, 10),
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(
                                color: LoginScreen.accentColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Animated Title with Gradient
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      LoginScreen.primaryColor,
                                      LoginScreen.accentColor,
                                    ],
                                  ).createShader(bounds),
                                  child: AnimatedDefaultTextStyle(
                                    duration: Duration(milliseconds: 500),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Zain',
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: LoginScreen.primaryColor.withOpacity(0.5),
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text("Welcome Back!"),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Sign in to DeltaNav",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[700],
                                    fontFamily: 'Zain',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 40),
                                // ID Field
                                _buildTextField(
                                  controller: _idController,
                                  label: "User ID",
                                  icon: Icons.person_outline,
                                  keyboardType: TextInputType.number,
                                ),
                                SizedBox(height: 24),
                                // Password Field
                                _buildTextField(
                                  controller: _passwordController,
                                  label: "Password",
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  toggleVisibility: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                  isPasswordVisible: _isPasswordVisible,
                                ),
                                SizedBox(height: 40),
                                // Login Button
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        LoginScreen.primaryColor,
                                        LoginScreen.accentColor,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: LoginScreen.primaryColor.withOpacity(0.5),
                                        blurRadius: 15,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      padding: EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      shadowColor: Colors.transparent,
                                    ),
                                    onPressed: () {
                                      String enteredId = _idController.text.trim();
                                      if (enteredId.isNotEmpty && _passwordController.text.isNotEmpty) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HomeScreen(),
                                            settings: RouteSettings(arguments: enteredId),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Please enter both ID and Password"),
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'Zain',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                // Signup Button
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                                      );
                                    },
                                    child: Text(
                                      "Create an Account",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Zain',
                                        color: LoginScreen.accentColor,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor: LoginScreen.accentColor.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Social Media Icons and Copyright
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIcon(
                          icon: Icons.camera_alt,
                          url: "https://www.instagram.com/deltauniversity/?hl=en",
                        ),
                        SizedBox(width: 16),
                        _buildSocialIcon(
                          icon: Icons.facebook,
                          url: "https://www.facebook.com/deltauniv/",
                        ),
                        SizedBox(width: 16),
                        _buildSocialIcon(
                          icon: Icons.business,
                          url: "https://www.linkedin.com/school/delta-university-for-science-and-technology/",
                        ),
                        SizedBox(width: 16),
                        _buildSocialIcon(
                          icon: Icons.web,
                          url: "https://new.deltauniv.edu.eg/en/home/index",
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(0, 225, 234, 236).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "© 2025 Delta University for Science and Technology",
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color.fromARGB(228, 46, 47, 50).withOpacity(0.8),
                          fontFamily: 'Zain',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    VoidCallback? toggleVisibility,
    bool isPasswordVisible = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: LoginScreen.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !isPasswordVisible,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: LoginScreen.primaryColor.withOpacity(0.8),
            fontFamily: 'Zain',
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: LoginScreen.accentColor),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: LoginScreen.accentColor.withOpacity(0.7),
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: LoginScreen.accentColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          hintStyle: TextStyle(
            fontFamily: 'Zain',
            fontSize: 16,
            color: Colors.grey[400],
          ),
        ),
        style: TextStyle(
          fontFamily: 'Zain',
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSocialIcon({required IconData icon, required String url}) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [LoginScreen.primaryColor.withOpacity(0.8), LoginScreen.accentColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}