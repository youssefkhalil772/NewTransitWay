import 'package:flutter/material.dart';

class RouteModel {
  final int id;
  final String name;
  final String zone; // Ø¥Ø¶Ø§ÙØ© Ø­Ù‚Ù„ Ø§Ù„Ù€ zone Ù‡Ù†Ø§
  final double price; // Ø§Ù„Ø³Ø¹Ø± Ù…Ù† Ø§Ù„Ø¯Ø§ØªØ§ Ø¨ÙŠØ²
  final Color color;

  RouteModel({
    required this.id,
    required this.name,
    required this.zone,
    this.price = 0.0,
    required this.color,
  });

  static const List<Color> _routePalette = [
    Color(0xFF1B4D3E),
    Color(0xFF0D47A1),
    Color(0xFFB71C1C),
    Color(0xFF4A148C),
    Color(0xFFE65100),
    Color(0xFF004D40),
    Color(0xFF3E2723),
  ];

  static Color getColorFromName(String text) {
    String t = text.toLowerCase();
    if (t.contains("cairo")) return _routePalette[0];
    if (t.contains("shrouk")) return _routePalette[1];
    if (t.contains("route2")) return _routePalette[2];

    int hash = 0;
    for (int i = 0; i < t.length; i++) {
      hash += t.codeUnitAt(i);
    }
    return _routePalette[hash % _routePalette.length];
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    String routeName = json['name'] ?? "";
    String routeZone =
        json['zone'] ?? ""; // Ø§Ø³ØªÙ„Ø§Ù… Ø§Ù„Ø²ÙˆÙ† Ù…Ù† Ø§Ù„Ù€ API
    double routePrice = (json['price'] as num?)?.toDouble() ?? 0.0;
    return RouteModel(
      id: json['id'],
      name: routeName,
      zone: routeZone,
      price: routePrice,
      color: getColorFromName(routeName),
    );
  }
}
