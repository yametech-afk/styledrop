import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherInfo {
  final double temperatureC;
  final String condition; // "Sunny", "Partly Cloudy", "Rain", "Cloudy", "Clear"
  final String emoji;
  final String recommendation;
  final bool isLive; // true = real API data, false = fallback/mocked
  final String? locationLabel; // e.g. "Manila, PH" or null if unknown

  const WeatherInfo({
    required this.temperatureC,
    required this.condition,
    required this.emoji,
    required this.recommendation,
    this.isLive = false,
    this.locationLabel,
  });
}

/// Real weather service backed by the device's GPS location (via
/// [geolocator] + runtime permission requests) and the free, no-API-key
/// Open-Meteo forecast API.
///
/// Falls back to a clearly-labeled simulated reading if location permission
/// is denied, GPS is unavailable, or the network call fails — so the Home
/// screen and AI generator never break, but the user can tell the
/// difference between a live reading and a fallback.
class WeatherService {
  static final Random _rng = Random();
  static WeatherInfo? _cached;

  /// WMO weather codes (used by Open-Meteo) mapped to a simplified
  /// condition name + emoji used across the app / outfit matching logic.
  static Map<String, String> _mapWeatherCode(int code, bool isDay) {
    if (code == 0) {
      return isDay
          ? {'name': 'Sunny', 'emoji': '☀️'}
          : {'name': 'Clear', 'emoji': '🌙'};
    }
    if (code == 1 || code == 2) {
      return {'name': 'Partly Cloudy', 'emoji': '⛅'};
    }
    if (code == 3) {
      return {'name': 'Cloudy', 'emoji': '☁️'};
    }
    if (code >= 45 && code <= 48) {
      return {'name': 'Cloudy', 'emoji': '🌫️'};
    }
    if ((code >= 51 && code <= 67) ||
        (code >= 80 && code <= 82) ||
        (code >= 95 && code <= 99)) {
      return {'name': 'Rain', 'emoji': '🌧️'};
    }
    if (code >= 71 && code <= 77) {
      return {'name': 'Cloudy', 'emoji': '🌨️'};
    }
    return isDay
        ? {'name': 'Sunny', 'emoji': '☀️'}
        : {'name': 'Clear', 'emoji': '🌙'};
  }

  static String _recommendationFor(String condition, double tempC) {
    if (condition == 'Rain') {
      return 'Rain is expected, so avoid suede or canvas shoes and bring a light jacket.';
    } else if (tempC >= 30) {
      return "It's hot today — go for breathable fabrics and skip heavy layers.";
    } else if (tempC <= 20) {
      return "It's cool today — a jacket or outerwear layer is recommended.";
    }
    return 'Pleasant conditions today — most outfits will work comfortably.';
  }

  /// Requests location permission and returns the device's current
  /// position, or null if permission is denied / location services are
  /// disabled / any platform error occurs (e.g. unsupported on web without
  /// HTTPS, desktop without GPS, etc.).
  static Future<Position?> _getDevicePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WeatherService: location unavailable ($e)');
      }
      return null;
    }
  }

  static Future<String?> _reverseGeocodeLabel(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/reverse'
        '?latitude=$lat&longitude=$lon&count=1&language=en&format=json',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final r = results.first as Map<String, dynamic>;
      final name = r['name'] as String?;
      final country = r['country_code'] as String?;
      if (name == null) return null;
      return country != null ? '$name, $country' : name;
    } catch (_) {
      return null;
    }
  }

  static Future<WeatherInfo?> _fetchLiveWeather() async {
    final position = await _getDevicePosition();
    if (position == null) return null;

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${position.latitude}&longitude=${position.longitude}'
      '&current=temperature_2m,weather_code,is_day&timezone=auto',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Open-Meteo returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final current = decoded['current'] as Map<String, dynamic>?;
    if (current == null) throw Exception('No current weather in response');

    final tempC = (current['temperature_2m'] as num).toDouble();
    final code = (current['weather_code'] as num).toInt();
    final isDay = (current['is_day'] as num).toInt() == 1;

    final conditionData = _mapWeatherCode(code, isDay);
    final condition = conditionData['name']!;
    final emoji = conditionData['emoji']!;

    final label = await _reverseGeocodeLabel(
      position.latitude,
      position.longitude,
    );

    return WeatherInfo(
      temperatureC: tempC,
      condition: condition,
      emoji: emoji,
      recommendation: _recommendationFor(condition, tempC),
      isLive: true,
      locationLabel: label,
    );
  }

  /// Simulated fallback used only when GPS/permission/network is
  /// unavailable, so the app still functions but is honest that this
  /// reading isn't real via [WeatherInfo.isLive] == false.
  static WeatherInfo _fallbackWeather() {
    const conditions = [
      {'name': 'Sunny', 'emoji': '☀️'},
      {'name': 'Partly Cloudy', 'emoji': '⛅'},
      {'name': 'Cloudy', 'emoji': '☁️'},
      {'name': 'Rain', 'emoji': '🌧️'},
    ];
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour > 19;
    final conditionData = isNight
        ? {'name': 'Clear', 'emoji': '🌙'}
        : conditions[_rng.nextInt(conditions.length)];
    final tempC = (24 + _rng.nextInt(10)).toDouble();
    final condition = conditionData['name']!;

    return WeatherInfo(
      temperatureC: tempC,
      condition: condition,
      emoji: conditionData['emoji']!,
      recommendation: _recommendationFor(condition, tempC),
      isLive: false,
      locationLabel: null,
    );
  }

  static Future<WeatherInfo> fetchWeather({bool forceRefresh = false}) async {
    if (_cached != null && !forceRefresh) return _cached!;

    try {
      final live = await _fetchLiveWeather();
      if (live != null) {
        _cached = live;
        return live;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WeatherService: live fetch failed ($e), using fallback.');
      }
    }

    _cached = _fallbackWeather();
    return _cached!;
  }
}
