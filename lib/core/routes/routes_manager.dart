import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transite_way/feature/login/login.dart';
import 'package:transite_way/feature/onboarding/screen/onboarding_screen.dart';
import 'package:transite_way/feature/role/role_select_screen.dart';
import 'package:transite_way/feature/splash/splash.dart';
import 'package:transite_way/feature/forget_password/presentation/screens/recovery_screen.dart';
import 'package:transite_way/feature/home/presentation/screens/home_screen.dart';
import 'package:transite_way/feature/home/presentation/screens/bus_tracking_screen.dart';
import 'package:transite_way/feature/home/presentation/widgets/main_wrapper.dart';
import 'package:transite_way/feature/payMent/charge_point.dart';

import '../../feature/driver/data/driver_auth_service.dart';
import '../../feature/driver/logic/driver_login_cubit.dart';
import '../../feature/driver/presentation/screens/home/driver_home_screen.dart';
import '../../feature/driver/presentation/screens/auth/login_screen.dart';
import '../../feature/notifications/data/notification_model.dart';
import '../../feature/notifications/notification_details_screen.dart';
import '../../feature/notifications/notifications_screen.dart';
import '../../feature/splash/splash_screen.dart';
import '../../feature/profile/profile_screen.dart';
import '../../feature/profile/user_edit_profile_screen.dart';
import '../../feature/tickets/tickets.dart';

abstract class RoutesManager {
  static const String splash = "/splash";
  static const String onboardingScreen = "/onboardingScreen";
  static const String login = "/login";
  static const String loginDriver = "/loginDriver";
  static const String driverSplash = "/driverSplash";
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
  static const String editUserProfile = "/editUserProfile";
  static const String qrScanner = "/qrScanner";
  static const String chargeMyPoints = "/chargeMyPoints";
  static const String notifications = "/notifications";
  static const String notificationDetails = "/notificationDetails";

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const Splash(),
    role: (context) => RoleSelectScreen(),
    onboardingScreen: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    loginDriver: (context) => BlocProvider(
          create: (context) => DriverLoginCubit(DriverAuthServices()),
          child: const DriverLoginScreen(),
        ),
    driverSplash: (context) => const DriverSplash(),
    forgetPassword: (context) => const PasswordRecoveryScreen(),
    mainWrapper: (context) => const MainWrapper(),
    home: (context) => const HomeScreen(),
    driverHome: (context) => const DriverHomeScreen(),
    busTracking: (context) => const BusTrackingScreen(),
    tickets: (context) => const MyTicketsScreen(),
    profile: (context) => const ProfileScreen(),
    editUserProfile: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return UserEditProfileScreen(
        currentName: args['name'],
        currentPhone: args['phone'],
        currentEmail: args['email'],
        currentPhoto: args['photo'],
      );
    },
    chargeMyPoints: (context) => const ChargeMyPointsScreen(),
    notifications: (context) => const NotificationsScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == notificationDetails) {
      final notification = settings.arguments as NotificationModel;
      return MaterialPageRoute(
        builder: (context) => NotificationDetailsScreen(notification: notification),
      );
    }

    final WidgetBuilder? builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }
    return null;
  }
  
  static void navigateAndRemoveUntil(BuildContext context, String routeName) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
  }

  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }
}
