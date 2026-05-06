class ApiConstants {
  // ── Supabase Table Names ──────────────────────────────────────
  static const String usersTable = 'users';
  static const String driversTable = 'drivers';
  static const String stationsTable = 'stations';
  static const String routesTable = 'routes';
  static const String busesTable = 'buses';
  static const String ticketsTable = 'tickets';
  static const String notificationsTable = 'notifications';
  static const String walletsTable = 'wallets';
  static const String trackingTable = 'tracking';
  static const String userTripsTable = 'user_trips';

  // ── Supabase RPC Functions ────────────────────────────────────
  static const String searchTripRpc = 'search_trip';
  static const String scanPayRpc = 'scan_pay';
  static const String startTripRpc = 'start_trip';
  static const String endTripRpc = 'end_trip';

  // ── Supabase Storage Buckets ──────────────────────────────────
  static const String avatarsBucket = 'avatars';

  // ── OSRM (Public Routing Service) ────────────────────────────
  static const String osrmBaseUrl = "https://routing.openstreetmap.de/routed-car/route/v1/driving/";
}
