class BusModel {
  final String busNumber;
  final String driverName;
  final String arrivalTime;
  final String status;
  final double lat; // لإحداثيات الخريطة
  final double lng;

  BusModel({
    required this.busNumber,
    required this.driverName,
    required this.arrivalTime,
    required this.status,
    required this.lat,
    required this.lng,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      busNumber: json['bus_number'] ?? '',
      driverName: json['driver_name'] ?? 'Unknown',
      arrivalTime: json['arrival_time'] ?? '--',
      status: json['status'] ?? 'On Way',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'bus_number': busNumber,
    'driver_name': driverName,
    'arrival_time': arrivalTime,
    'status': status,
    'lat': lat,
    'lng': lng,
  };
}