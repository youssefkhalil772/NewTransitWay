class ApiConstants {
  static const String baseUrl = "https://transit-way.runasp.net/api/";
  
  // Auth
  static const String login = "Auth/login";
  static const String loginDriver = "Driver/login";
  static String getDriver(int driverId) => "Driver/$driverId"; 

  static const String googleLogin = "Auth/google-login";
  static const String register = "Auth/user/register";
  static const String getEmail = "Auth/get-email";
  static const String getDriverEmail = "Driver/get-email";
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
  static const String createManualTicket = "Tickets/manual";
  static String driverTickets(int driverId) => "Tickets/driver/$driverId";

  // Notifications
  static String userNotifications(int userId) => "User/$userId/notifications";
  static String markNotificationRead(int userId, int notificationId) => "User/$userId/notifications/$notificationId/read";
  static String markAllNotificationsRead(int userId) => "User/$userId/notifications/read-all";

  // QR Payment
  static const String scanPay = "QrPayment/scan-pay";

  // Tracking
  static const String trackUpdate = "track/update";
  static String startTrip(int busId) => "track/start-trip/$busId";
  static String endTrip(int busId) => "track/end-trip/$busId";

  // OSRM (Third-party)
  static const String osrmBaseUrl = "https://router.project-osrm.org/route/v1/driving/";
}
