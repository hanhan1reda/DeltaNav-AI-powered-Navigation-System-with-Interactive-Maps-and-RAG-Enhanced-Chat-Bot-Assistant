import 'package:flutter/material.dart';
import 'OnBordingScreen.dart';


void main() {
  runApp(const DeltaNavApp());
}

class DeltaNavApp extends StatelessWidget {
  const DeltaNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(),
    );
  }
}

