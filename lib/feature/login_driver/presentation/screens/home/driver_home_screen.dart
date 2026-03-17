import 'package:flutter/material.dart';
import '../../../../../core/routes/routes_manager.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Panel'),
        backgroundColor: const Color(0xFF064E3B),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => RoutesManager.navigateAndReplace(context, RoutesManager.login),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bus, size: 80, color: Color(0xFF064E3B)),
            const SizedBox(height: 20),
            const Text('Welcome Driver!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF064E3B),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              onPressed: () => Navigator.pushNamed(context, '/tripTracking'), // هنضيف المسار ده
              child: const Text('Start Trip / ابدأ الرحلة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}