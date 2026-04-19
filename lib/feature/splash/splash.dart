import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/core/routes/routes_manager.dart';
import '../../core/resources/assest_manager.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    
    // إعداد شكل الـ status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    _startAppFlow();
  }

  Future<void> _startAppFlow() async {
    // ننتظر ثانيتين لعرض اللوجو
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // فحص هل المستخدم مسجل دخول بالفعل؟
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');

    if (userId != null && userId != 0) {
      // لو مسجل، يدخل ع الأبلكيشن فوراً
      Navigator.pushReplacementNamed(context, RoutesManager.mainWrapper);
    } else {
      // لو مش مسجل، يروح لصفحة اختيار الدور (Role) أو اللوجين
      Navigator.pushReplacementNamed(context, RoutesManager.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.green,
      body: Center(
        child: Image.asset(ImageAssets.logo),
      ),
    );
  }
}
