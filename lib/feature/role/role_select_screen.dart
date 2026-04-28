import 'package:flutter/material.dart';
import 'package:transite_way/core/routes/routes_manager.dart';
import '../../core/resources/assest_manager.dart';

class RoleSelectScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E37),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            Image.asset(ImageAssets.logo)
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(60),
                          topRight: Radius.circular(60),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Welcome to TransitWay",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Choose how you want to Sign In",
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                          const SizedBox(height: 30),
                
                          // Passenger Image
                          Image.asset(
                            'assets/images/sgin in user.png',
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          buildSignButton(
                            text: "Sign In as Passenger",
                            color: const Color(0XFF054F3A),
                            onPressed: () {
                              Navigator.pushNamed(context, RoutesManager.onboardingScreen);
                            },
                          ),
                
                          const SizedBox(height: 30),
                
                          // Driver Image
                          Image.asset(
                            'assets/images/sgin in driver.png',
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          buildSignButton(
                            text: "Sign In as Driver",
                            color: const Color(0XFF054F3A),
                            onPressed: () {
                              Navigator.pushNamed(context, RoutesManager.driverSplash);
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildSignButton({required String text, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
