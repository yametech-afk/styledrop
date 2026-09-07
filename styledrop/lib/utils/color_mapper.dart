import 'package:flutter/material.dart';

/// Maps a color name string (as detected/stored on WardrobeItem) to an
/// actual Flutter Color for UI swatches.
class ColorMapper {
  ColorMapper._();

  static const Map<String, Color> _map = {
    'black': Color(0xFF1C1B19),
    'white': Color(0xFFFAFAF7),
    'gray': Color(0xFF9C9689),
    'grey': Color(0xFF9C9689),
    'beige': Color(0xFFE3D5B8),
    'cream': Color(0xFFF1E9D8),
    'navy': Color(0xFF1F2A44),
    'brown': Color(0xFF6B4A34),
    'olive': Color(0xFF6E7B4A),
    'tan': Color(0xFFC8A97E),
    'khaki': Color(0xFFC3B091),
    'red': Color(0xFFB5533C),
    'blue': Color(0xFF3B5A8A),
    'silver': Color(0xFFC7C7C7),
    'gold': Color(0xFFB89664),
    'pink': Color(0xFFE0A6B0),
    'purple': Color(0xFF6E5A8A),
    'yellow': Color(0xFFD8B84A),
    'orange': Color(0xFFC97A3D),
    'green': Color(0xFF6E8B5B),
  };

  static Color fromName(String name) {
    return _map[name.toLowerCase().trim()] ?? const Color(0xFFB0A88F);
  }
}
