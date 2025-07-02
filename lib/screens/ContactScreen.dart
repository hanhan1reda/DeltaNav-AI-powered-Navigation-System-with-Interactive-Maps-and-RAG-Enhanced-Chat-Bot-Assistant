import 'package:delta_n/screens/MapScreen.dart';
import 'package:flutter/material.dart';
import 'HomeScreen.dart';

class ContactScreen extends StatelessWidget {
  static const Color primaryColor = Color(
    0xFF32689B,
  ); // Assuming this matches HomeScreen.primaryColor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[100]!, Colors.white],
          ),
          image: DecorationImage(
            image: AssetImage(
              'assets/images/Untitledesign.jpg',
            ), // Add your image here
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.1),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 80), // Space for the floating app bar
                    Text(
                      "Reach Out Anytime!",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        fontFamily: 'Zain',
                        shadows: [
                          Shadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Our team is available 24/7 to assist you.",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontFamily: 'Zain',
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 40),
                    _buildContactItem(
                      icon: Icons.phone,
                      title: "Phone Numbers",
                      details: ["+20 123 456 7890", "+20 987 654 3210"],
                    ),
                    SizedBox(height: 24),
                    _buildContactItem(
                      icon: Icons.email,
                      title: "Email Support",
                      details: ["Contact us at: support@deltauniv.edu"],
                    ),
                    SizedBox(height: 100), // Space for bottom navigation
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildAppBar(context),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomNavigationBar(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "Contact Us",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Zain',
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
          SizedBox(width: 48), // Balance the layout
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color.fromARGB(255, 114, 167, 193),
        currentIndex: 2, // Highlight Contact as active
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Zain',
        ),
        unselectedLabelStyle: TextStyle(fontFamily: 'Zain'),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_mail),
            label: "Contact",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: "About"),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MapScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AboutDialog(),
              ), // Assuming you have an AboutScreen
            );
          }
        },
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required List<String> details,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.1),
            ),
            child: Icon(icon, size: 30, color: primaryColor),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    fontFamily: 'Zain',
                  ),
                ),
                SizedBox(height: 8),
                ...details.map(
                  (detail) => Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      detail,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        fontFamily: 'Zain',
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
