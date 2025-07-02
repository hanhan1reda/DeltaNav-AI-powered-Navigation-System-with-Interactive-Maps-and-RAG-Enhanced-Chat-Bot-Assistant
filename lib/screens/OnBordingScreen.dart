
import 'package:flutter/material.dart';
import 'LoginScreen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color primaryColor = Color(0xFF32689b);
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Navigate Your Way",
      "desc": "Find the best routes inside Delta University with ease",
      "image": "assets/images/location10.gif",
    },
    {
      "title": "AR Assistance",
      "desc": "Use Augmented Reality to explore your surroundings",
      "image": "assets/images/navigation_1.gif",
    },
    {
      "title": "Smart AI Support",
      "desc": "Get real-time assistance using AI and GPS",
      "image": "assets/images/Robot.gif",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder:
                    (context, index) => _buildPage(
                      title: onboardingData[index]["title"]!,
                      description: onboardingData[index]["desc"]!,
                      imagePath: onboardingData[index]["image"]!,
                    ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: _buildDots(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: _buildButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required String imagePath,
  }) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              imagePath,
              height: 280,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: primaryColor,
                  ),
            ),
          ),
          SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              fontFamily: 'Zain',
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 22,
              color: Colors.black87,
              fontFamily: 'Zain',
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        onboardingData.length,
        (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 6),
          width: _currentIndex == index ? 24 : 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: _currentIndex == index ? primaryColor : Colors.grey[400],
            boxShadow: [
              if (_currentIndex == index)
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 4),
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
          if (_currentIndex < onboardingData.length - 1) {
            _controller.nextPage(
              duration: Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          }
        },
        child: Text(
          _currentIndex == onboardingData.length - 1 ? "Get Started" : "Next",
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Zain',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

Widget buildPage(String title, String desc, String imagePath) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (imagePath.isNotEmpty) Image.asset(imagePath, fit: BoxFit.cover),
        SizedBox(height: 30),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFamily: 'Zain',
            color: const Color(0xFF32689b),
          ),
        ),
        SizedBox(height: 10),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ],
    ),
  );
}
