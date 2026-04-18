import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:transite_way/feature/login/login.dart';
import 'package:transite_way/feature/onboarding/screen/onboarding_screen.dart';
import 'package:transite_way/feature/role/role_select_screen.dart';
import 'package:transite_way/feature/splash/splash.dart';
import 'package:transite_way/feature/forget_password/presentation/screens/recovery_screen.dart';
import 'package:transite_way/feature/home/presentation/screens/home_screen.dart';
import 'package:transite_way/feature/home/presentation/screens/bus_tracking_screen.dart';
import 'package:transite_way/feature/home/presentation/widgets/main_wrapper.dart';
import 'package:transite_way/feature/payMent/charge_point.dart';

import '../../feature/login_driver/presentation/screens/home/driver_home_screen.dart';
import '../../feature/login_driver/presentation/screens/login_driver_screen.dart';
import '../../feature/profile/profile_screen.dart';
import '../../feature/tickets/tickets.dart';
import '../../feature/tracking/presentation/screens/trip_tracking_screen.dart';

abstract class RoutesManager {
  static const String splash = "/splash";
  static const String onboardingScreen = "/onboardingScreen";
  static const String login = "/login";
  static const String loginDriver = "/loginDriver";
  static const String signUp = "/signUp";
  static const String role = "/role";
  static const String forgetPassword = "/forgetPassword";
  static const String changePassword = "/changePassword";
  static const String mainWrapper = "/mainWrapper";
  static const String home = "/home";
  static const String driverHome = "/driverHome";
  static const String busTracking = "/busTracking";
  static const String tickets = "/tickets";
  static const String profile = "/profile";
  static const String qrScanner = "/qrScanner";
  static const String tripTracking = "/tripTracking";
  static const String chargeMyPoints = "/chargeMyPoints";

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return CupertinoPageRoute(builder: (_) => const Splash());
      case role:
        return CupertinoPageRoute(builder: (_) => RoleSelectScreen());
      case onboardingScreen:
        return CupertinoPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return CupertinoPageRoute(builder: (_) => const LoginScreen());
      case loginDriver:
        return CupertinoPageRoute(builder: (_) => const DriverLoginScreen());
      case forgetPassword:
        return CupertinoPageRoute(builder: (_) => const PasswordRecoveryScreen());
      case mainWrapper:
        return CupertinoPageRoute(builder: (_) => const MainWrapper());
      case tripTracking:
        return CupertinoPageRoute(builder: (_) => const TripTrackingScreen());
      case home:
        return CupertinoPageRoute(builder: (_) => const HomeScreen());
      case driverHome:
        return CupertinoPageRoute(builder: (_) => const DriverHomeScreen());
      case busTracking:
        return CupertinoPageRoute(builder: (_) => const BusTrackingScreen(), settings: settings);
      case tickets:
        return CupertinoPageRoute(builder: (_) => const MyTicketsScreen());
      case profile:
        return CupertinoPageRoute(builder: (_) => const ProfileScreen());
      case chargeMyPoints:
        return CupertinoPageRoute(builder: (_) => const ChargeMyPointsScreen());
      default:
        return CupertinoPageRoute(builder: (_) => const Splash());
    }
  }

  static void navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  static void navigateAndReplace(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }

  static void navigateAndRemoveUntil(BuildContext context, String routeName) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
  }

  static void goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}
