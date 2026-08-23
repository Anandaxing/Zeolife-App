import 'package:flutter/material.dart';
import 'control_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
    // Color definitions
  static const Color darkerGreen = Color(0xFF063B00);
  static const Color darkGreen   = Color(0xFF266210);
  static const Color lightGreen  = Color(0xFF90B800);
  static const Color lime        = Color(0xFFE1E100);
  static const Color darkGray    = Color(0xFF333333);
  static const Color gainsboro   = Color(0xFFDCDCDC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Control Your Device!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              const Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ControlPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lime, // lime button
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 20, color: darkGray, fontWeight: FontWeight.bold),  
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
