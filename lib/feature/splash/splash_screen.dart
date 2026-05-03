import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/core/resources/color_manager.dart';
import 'package:transite_way/core/resources/assest_manager.dart';
import 'package:transite_way/core/routes/routes_manager.dart';

class CommonSplashScreen extends StatefulWidget {
  final String? subTitle;
  final String nextRoute;
  final Color? backgroundColor;

  const CommonSplashScreen({
    super.key,
    this.subTitle,
    required this.nextRoute,
    this.backgroundColor,
  });

  @override
  State<CommonSplashScreen> createState() => _CommonSplashScreenState();
}

class _CommonSplashScreenState extends State<CommonSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.75, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        RoutesManager.navigateAndRemoveUntil(context, widget.nextRoute);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? ColorManager.green,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: widget.subTitle == 'Driver' 
              ? _buildDriverSplashContent() 
              : _buildDefaultSplashContent(),
          ),
        ),
      ),
    );
  }

  // Driver splash content
  Widget _buildDriverSplashContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(ImageAssets.logo, height: 180.h), // Main logo with bus and marker
            Positioned(
              right: 90.w, // Position text next to the marker in the logo
              top: 50.h,  // Align vertically with the marker position
              child: Text(
                'Driver',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultSplashContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(ImageAssets.logo, height: 120.h),
      ],
    );
  }
}

class DriverSplash extends StatelessWidget {
  const DriverSplash({super.key});
  @override
  Widget build(BuildContext context) {
    return const CommonSplashScreen(
      subTitle: 'Driver',
      backgroundColor: Color(0XFF34C759), // lightGreen color #34C759
      nextRoute: RoutesManager.loginDriver,
    );
  }
}
