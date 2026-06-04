class BusModel {
  final String busNumber;
  final String? driverName;
  final String? arrivalTime;
  final String? status;
  final double lat;
  final double lng;
  final String? distanceToStation;
  final String? tripDistance;

  BusModel({
    required this.busNumber,
    this.driverName,
    this.arrivalTime,
    this.status,
    this.lat = 0.0,
    this.lng = 0.0,
    this.distanceToStation,
    this.tripDistance,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      busNumber:
          json['busNumber']?.toString() ?? json['bus_number']?.toString() ?? '',
      driverName: json['driverName'] ?? json['driver_name'] ?? 'Unknown',

      arrivalTime: json['estimatedArrivalTime'] ?? json['arrival_time'] ?? '--',
      distanceToStation: json['distanceToStationKm']?.toString(),
      tripDistance: json['tripDistanceKm']?.toString(),

      status: json['status'] ?? 'On Way',

      lat: (json['latitude'] ?? json['lat'] ?? 0.0) is num
          ? (json['latitude'] ?? json['lat'] ?? 0.0).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      lng: (json['longitude'] ?? json['lng'] ?? 0.0) is num
          ? (json['longitude'] ?? json['lng'] ?? 0.0).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'busNumber': busNumber,
    'driverName': driverName,
    'estimatedArrivalTime': arrivalTime,
    'status': status,
    'latitude': lat,
    'longitude': lng,
    'distanceToStationKm': distanceToStation,
    'tripDistanceKm': tripDistance,
  };
}
