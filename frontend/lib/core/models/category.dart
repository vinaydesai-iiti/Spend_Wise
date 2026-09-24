import 'package:flutter/material.dart';

/// A spend category, e.g. "Food & Dining".
/// Backend sends `icon` as a short key (see [Category.iconFor]) and
/// `color` as a 6-digit hex string without the leading '#'.
@immutable
class Category {
  final String id;
  final String name;
  final String iconKey;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.color,
  });

  IconData get icon => iconFor(iconKey);

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: json['icon'] as String,
      color: _colorFromHex(json['color'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': iconKey,
        'color': _hexFromColor(color),
      };

  static Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String _hexFromColor(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0').substring(2);
  }

  static IconData iconFor(String key) {
    switch (key) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'groceries':
        return Icons.local_grocery_store_rounded;
      case 'transport':
        return Icons.directions_car_filled_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'health':
        return Icons.local_hospital_rounded;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
