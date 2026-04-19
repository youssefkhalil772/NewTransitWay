import 'package:flutter/material.dart';
import 'package:transite_way/feature/login/login.dart';
import 'package:transite_way/feature/onboarding/screen/onboarding_screen.dart';
import 'package:transite_way/feature/role/role_select_screen.dart';
import 'package:transite_way/feature/splash/splash.dart';
import 'package:transite_way/feature/splash/splash_screen.dart';
import 'package:transite_way/feature/forget_password/presentation/screens/recovery_screen.dart';
import 'package:transite_way/feature/home/presentation/screens/home_screen.dart';
import 'package:transite_way/feature/home/presentation/screens/bus_tracking_screen.dart';
import 'package:transite_way/feature/home/presentation/widgets/main_wrapper.dart';
import 'package:transite_way/feature/payMent/charge_point.dart'; 

import 'package:transite_way/feature/driver/presentation/screens/home/driver_home_screen.dart';
import 'package:transite_way/feature/driver/presentation/screens/auth/login_screen.dart';
import 'package:transite_way/feature/driver/presentation/screens/add_tickets/add_tickets_screen.dart';
import 'package:transite_way/feature/driver/presentation/screens/profile/profile_screen_driver.dart';
import 'package:transite_way/feature/driver/presentation/screens/routes/routes_screen.dart';
import 'package:transite_way/feature/profile/profile_screen.dart';
import 'package:transite_way/feature/tickets/tickets.dart';

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
  static const String chargeMyPoints = "/chargeMyPoints"; 
  static const String driverSplash = "/driverSplash";
  static const String driverRoutes = "/driverRoutes";
  static const String driverProfile = "/driverProfile";
  static const String addTickets = "/addTickets";

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const Splash(),
    role: (context) => RoleSelectScreen(),
    onboardingScreen: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    loginDriver: (context) => const DriverLoginScreen(),
    forgetPassword: (context) => const PasswordRecoveryScreen(),
    mainWrapper: (context) => const MainWrapper(),
    home: (context) => const HomeScreen(),
    driverHome: (context) => const DriverHomeScreen(),
    busTracking: (context) => const BusTrackingScreen(),
    tickets: (context) => const MyTicketsScreen(),
    profile: (context) => const ProfileScreen(),
    chargeMyPoints: (context) => const ChargeMyPointsScreen(), 
    driverSplash: (context) => const SplashScreen(),
    driverRoutes: (context) => const RoutesScreen(),
    driverProfile: (context) => const ProfileScreenDriver(),
    addTickets: (context) => const AddTicketsScreen(),
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