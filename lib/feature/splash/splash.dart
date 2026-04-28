import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/core/routes/routes_manager.dart';
import '../../core/resources/assest_manager.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1200)
    );
    
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn)
    );
    
    _scale = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
    );

    _controller.forward();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _startAppFlow();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startAppFlow() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final String? userRole = prefs.getString('userRole');
    final int? userId = prefs.getInt('userId');
    final int? driverId = prefs.getInt('driverId');

    if (userRole == 'driver' && driverId != null) {
      RoutesManager.navigateAndRemoveUntil(context, RoutesManager.driverHome);
    } else if (userRole == 'passenger' && userId != null && userId != 0) {
      RoutesManager.navigateAndRemoveUntil(context, RoutesManager.mainWrapper);
    } else {
      RoutesManager.navigateAndRemoveUntil(context, RoutesManager.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.green,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // تكبير اللوجو هنا
                Image.asset(ImageAssets.logo, height: 200.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
