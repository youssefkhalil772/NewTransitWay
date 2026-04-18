class ApiConstants {
  static const String baseUrl = "https://transit-way.runasp.net/api/";
  
  // Auth
  static const String login = "Auth/login";
  static const String googleLogin = "Auth/google-login";
  static const String register = "Auth/user/register";
  static const String getEmail = "Auth/get-email";
  static const String requestReset = "Auth/request-reset";
  static const String verifyCode = "Auth/verify-code";
  static const String confirmReset = "Auth/confirm-reset";

  // Home
  static const String stations = "Stations";
  static const String routes = "Routes";
  static const String userTripSearch = "UserTrip/search";
  static const String adminBuses = "admin/buses";

  // Profile & Points
  static const String userProfile = "Auth/user/profile";
  static String userBalance(int userId) => "Wallet/balance/$userId";
  
  // Tickets
  static String userTickets(int userId) => "Tickets/user/$userId";

  // QR Payment
  static const String scanPay = "QrPayment/scan-pay";

  // Tracking
  static const String trackUpdate = "track/update";

  // OSRM (Third-party)
  static const String osrmBaseUrl = "https://router.project-osrm.org/route/v1/driving/";
}
