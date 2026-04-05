import 'package:flutter/material.dart';
import 'package:transite_way/core/resources/assest_manager.dart';
import 'package:transite_way/feature/login/login.dart';

import '../forget_password/presentation/screens/success_screen.dart';
import 'Points.dart';

class ChargePointsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Charge My Points", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(height: 20),
            // Step Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStep(1, isCompleted: true),
                _buildLine(),
                _buildStep(2, isActive: true),
                _buildLine(),
                _buildStep(3),
              ],
            ),
            SizedBox(height: 30),
            // Credit Card Design
           Image.asset(ImageAssets.card),
            SizedBox(height: 30),
            // Input Fields
            _buildTextField("1234 **** **** 456"),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildTextField("8/26")),
                SizedBox(width: 15),
                Expanded(child: _buildTextField("432")),
              ],
            ),
            SizedBox(height: 15),
            _buildTextField("Jumana Shahien"),
            SizedBox(height: 40),
            Text("Pay 100 Egp = 100 Points", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 20),
            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1B4D3E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PointsScreen()));
                },
                child: Text("Pay Now", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int n, {bool isActive = false, bool isCompleted = false}) {
    return Container(
      width: 35, height: 35,
      decoration: BoxDecoration(
        color: isCompleted || isActive ? Color(0xFF1B4D3E) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(child: Text("$n", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildLine() {
    return Container(width: 40, height: 2, color: Colors.grey[300]);
  }

  Widget _buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}