import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/config/theme/theme_manager.dart';
import 'package:transite_way/core/routes/routes_manager.dart';

// 1. تعريف الـ RouteObserver هنا ليكون متاحاً للتطبيق بالكامل
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
void main() {
  runApp(const TransitWay());
}

class TransitWay extends StatelessWidget {
  const TransitWay({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Transit Way',
          // 2. إضافة الـ navigatorObservers هنا لربط التطبيق بالـ Observer
          navigatorObservers: [routeObserver],
          initialRoute: RoutesManager.splash,
          routes: RoutesManager.routes,
          theme: ThemeManager.light,
          themeMode: ThemeMode.light,
          darkTheme: ThemeManager.dark,
        );
      },
    );
  }
}