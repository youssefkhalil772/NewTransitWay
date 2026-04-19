import 'package:latlong2/latlong.dart';

class StationModel {
  final int id;
  final String name;
  final String zone; // استخدمنا الزون بدلاً من الـ routeId
  final String latLong;
  final LatLng position;

  StationModel({
    required this.id,
    required this.name,
    required this.zone,
    required this.latLong,
    required this.position,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    var parts = json['latLong'].toString().split('&');
    LatLng pos = LatLng(
      double.parse(parts[0].trim()),
      double.parse(parts[1].trim()),
    );
    return StationModel(
      id: json['id'],
      name: json['name'],
      zone: json['zone'] ?? "Unknown", // استلام الزون من الـ API
      latLong: json['latLong'],
      position: pos,
    );
  }
}
