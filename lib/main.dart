import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/config/theme/theme_manager.dart';
import 'package:transite_way/core/routes/routes_manager.dart';

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
          navigatorObservers: [routeObserver],
          // تم إرجاع المسار الابتدائي للـ Splash ليتمكن من فحص تسجيل الدخول
          initialRoute: RoutesManager.splash, 
          onGenerateRoute: RoutesManager.onGenerateRoute,
          theme: ThemeManager.light,
          themeMode: ThemeMode.light,
          darkTheme: ThemeManager.dark,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
        );
      },
    );
  }
}
