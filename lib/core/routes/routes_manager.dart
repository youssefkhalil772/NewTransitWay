import 'package:flutter/material.dart';
import 'package:transite_way/feature/login/login.dart';
import 'package:transite_way/feature/onboarding/screen/onboarding_screen.dart';
import 'package:transite_way/feature/role/role_select_screen.dart';
import 'package:transite_way/feature/splash/splash.dart';
import 'package:transite_way/feature/forget_password/presentation/screens/recovery_screen.dart';
import 'package:transite_way/feature/home/presentation/screens/home_screen.dart';
import 'package:transite_way/feature/home/presentation/screens/bus_tracking_screen.dart';
import 'package:transite_way/feature/home/presentation/widgets/main_wrapper.dart';

import '../../feature/profile/profile_screen.dart';
import '../../feature/tickets/tickets.dart';

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
  static const String busTracking = "/busTracking";
  static const String tickets = "/tickets";
  static const String profile = "/profile";
  static const String qrScanner = "/qrScanner";

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const Splash(),
    role: (context) => RoleSelectScreen(),
    onboardingScreen: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    forgetPassword: (context) => const PasswordRecoveryScreen(),
    mainWrapper: (context) => const MainWrapper(),

    home: (context) => const HomeScreen(),
    busTracking: (context) => const BusTrackingScreen(),

    tickets: (context) => const MyTicketsScreen(),

    profile: (context) => const ProfileScreen(),

  };

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