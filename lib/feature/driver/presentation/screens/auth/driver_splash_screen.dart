import 'dart:async';
import 'package:flutter/material.dart';
import 'package:transite_way/core/resources/assest_manager.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/core/routes/routes_manager.dart';

class DriverSplash extends StatefulWidget {
  const DriverSplash({super.key});

  @override
  State<DriverSplash> createState() => _DriverSplashState();
}

class _DriverSplashState extends State<DriverSplash> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, RoutesManager.loginDriver);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.lightGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              ImageAssets.logo, // تأكد أن اللوجو يحتوي على كلمة Driver كما في الصورة
              width: 250,
            ),
          ],
        ),
      ),
    );
  }
}
