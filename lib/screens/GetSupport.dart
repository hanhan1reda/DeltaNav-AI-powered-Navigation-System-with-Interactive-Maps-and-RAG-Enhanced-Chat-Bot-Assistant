import 'package:delta_n/screens/ContactScreen.dart';
import 'package:flutter/material.dart';
import 'HomeScreen.dart';

class SupportScreen extends StatefulWidget {
  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: HomeScreen.primaryColor,
        title: Text(
          "Support",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Zain',
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildOnboardingPage(
                  imagePath: "assets/images/CallCenter.gif",
                  title: "Need Assistance?",
                  description:
                      "We're here to help you navigate Delta University with ease.",
                ),
                _buildOnboardingPage(
                  imagePath: "assets/images/Contact2.gif",
                  title: "Get Support Now",
                  description:
                      "Reach out to our team for quick and reliable assistance.",
                  isLastPage: true,
                ),
              ],
            ),
          ),
          _buildPageIndicators(),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String imagePath,
    required String title,
    required String description,
    bool isLastPage = false,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color.fromARGB(255, 255, 254, 254), Colors.white],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(imagePath, height: 250, fit: BoxFit.contain),
          ),
          SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: HomeScreen.primaryColor,
              fontFamily: 'Zain',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontFamily: 'Zain',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeScreen.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: HomeScreen.primaryColor.withOpacity(0.4),
              ),
              onPressed: () {
                if (isLastPage) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContactScreen()),
                  );
                } else {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Text(
                isLastPage ? "Contact Us" : "Next",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'Zain',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 6),
          height: 10,
          width: _currentPage == index ? 30 : 10,
          decoration: BoxDecoration(
            color:
                _currentPage == index
                    ? HomeScreen.primaryColor
                    : Colors.grey[400],
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              if (_currentPage == index)
                BoxShadow(
                  color: HomeScreen.primaryColor.withOpacity(0.3),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
            ],
          ),
        );
      }),
    );
  }
}

