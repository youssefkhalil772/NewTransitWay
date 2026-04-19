import 'package:flutter/material.dart';

class RouteModel {
  final int id;
  final String name;
  final Color color;

  RouteModel({
    required this.id,
    required this.name,
    required this.color,
  });

  static const List<Color> _routePalette = [
    Color(0xFF1B4D3E), // أخضر
    Color(0xFF0D47A1), // أزرق
    Color(0xFFB71C1C), // أحمر
    Color(0xFF4A148C), // بنفسجي
    Color(0xFFE65100), // برتقالي
    Color(0xFF004D40), // تيل
    Color(0xFF3E2723), // بني
  ];

  // دالة موحدة لاختيار اللون بناءً على اسم النص (الخط أو الزون)
  static Color getColorFromName(String text) {
    String t = text.toLowerCase();
    if (t.contains("cairo")) return _routePalette[0];
    if (t.contains("shrouk")) return _routePalette[1];
    if (t.contains("route2")) return _routePalette[2];

    // لو اسم جديد، بنجمع قيم الحروف عشان نطلع ID فريد للاسم
    int hash = 0;
    for (int i = 0; i < t.length; i++) {
      hash += t.codeUnitAt(i);
    }
    return _routePalette[hash % _routePalette.length];
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    String routeName = json['name'] ?? "";
    return RouteModel(
      id: json['id'],
      name: routeName,
      color: getColorFromName(routeName),
    );
  }
}
