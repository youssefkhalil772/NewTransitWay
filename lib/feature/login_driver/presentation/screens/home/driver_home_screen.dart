import 'package:flutter/material.dart';

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
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              '/login',
            ), // Ø¹Ø¯Ù„ Ø§Ù„Ù…Ø³Ø§Ø± Ø­Ø³Ø¨ Ù…Ø´Ø±ÙˆØ¹Ùƒ
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 80, color: Color(0xFF064E3B)),
            SizedBox(height: 20),
            Text(
              'Welcome Driver!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Your trip management system will be here.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
