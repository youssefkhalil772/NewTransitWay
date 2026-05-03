import 'package:latlong2/latlong.dart';

class StationModel {
  final String id;
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
    double lat = 0.0;
    double lng = 0.0;
    
    if (json['latitude'] != null && json['longitude'] != null) {
      lat = (json['latitude'] is num) ? json['latitude'].toDouble() : double.tryParse(json['latitude'].toString()) ?? 0.0;
      lng = (json['longitude'] is num) ? json['longitude'].toDouble() : double.tryParse(json['longitude'].toString()) ?? 0.0;
    } else {
      String latLongStr = json['latLong']?.toString() ?? json['lat_long']?.toString() ?? "0.0,0.0";
      var parts = latLongStr.contains('&') ? latLongStr.split('&') : latLongStr.split(',');
      if (parts.length >= 2) {
        lat = double.tryParse(parts[0].trim()) ?? 0.0;
        lng = double.tryParse(parts[1].trim()) ?? 0.0;
      }
    }
    
    LatLng pos = LatLng(lat, lng);
    return StationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Station',
      zone: json['zone']?.toString() ?? "Unknown",
      latLong: json['latLong']?.toString() ?? json['lat_long']?.toString() ?? "$lat&$lng",
      position: pos,
    );
  }
}
