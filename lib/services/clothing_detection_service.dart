import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/wardrobe_item.dart';
import '../utils/constants.dart';

/// AI-powered clothing attribute detection from a photo.
///
/// SECURITY: This client no longer talks to the LLM directly and NO LONGER
/// embeds any API key in the app binary. Instead it calls our own secure
/// backend proxy (a Cloudflare Worker) which holds the OpenAI key
/// server-side and forwards the vision request. The proxy endpoint is:
///
///     POST {PROXY_BASE_URL}/api/detect
///     body: {"imageBase64": "...", "suggestedCategory": "Tops"}
///
/// If the network call fails for any reason (offline, proxy error, malformed
/// response) we fall back to a local heuristic so the "Add Item" flow never
/// hard-crashes — the user can always correct any field afterwards.
class DetectionResult {
  final String category;
  final String type;
  final String color;
  final String pattern;
  final String style;
  final String fit;
  final String season;
  final double confidence;
  final bool isAiGenerated;

  const DetectionResult({
    required this.category,
    required this.type,
    required this.color,
    required this.pattern,
    required this.style,
    required this.fit,
    required this.season,
    required this.confidence,
    this.isAiGenerated = true,
  });
}

class ClothingDetectionService {
  static final Random _rng = Random();

  /// Base URL of YOUR deployed proxy (no secret here — just a public URL).
  /// Injected at build time via:
  ///   flutter build --dart-define=PROXY_BASE_URL=https://your-app.pages.dev
  static const String _proxyBaseUrl = String.fromEnvironment(
    'PROXY_BASE_URL',
    defaultValue: '',
  );

  /// Optional shared secret matching APP_SHARED_SECRET on the proxy, so only
  /// your app can call it. Injected via --dart-define=APP_SHARED_SECRET=...
  /// This is far less sensitive than the LLM key and can be rotated freely.
  static const String _appSharedSecret = String.fromEnvironment(
    'APP_SHARED_SECRET',
    defaultValue: '',
  );

  static const _typesByCategory = {
    ItemCategory.top: [
      'Oversized T-Shirt',
      'Graphic Tee',
      'Polo Shirt',
      'Hoodie',
      'Button-up Shirt',
      'Sweater',
    ],
    ItemCategory.bottom: [
      'Cargo Pants',
      'Straight Jeans',
      'Denim Shorts',
      'Sweatpants',
      'Chinos',
      'Wide-leg Trousers',
    ],
    ItemCategory.shoes: [
      'Sneakers',
      'Running Shoes',
      'Boots',
      'Loafers',
      'Sandals',
    ],
    ItemCategory.outerwear: [
      'Bomber Jacket',
      'Denim Jacket',
      'Windbreaker',
      'Overcoat',
      'Puffer Jacket',
    ],
    ItemCategory.accessory: ['Cap', 'Beanie', 'Sunglasses', 'Belt', 'Scarf'],
    ItemCategory.bag: ['Crossbody Bag', 'Backpack', 'Tote Bag', 'Duffel Bag'],
    ItemCategory.watch: ['Analog Watch', 'Digital Watch', 'Smart Watch'],
    ItemCategory.jewelry: ['Chain Necklace', 'Ring', 'Bracelet', 'Earrings'],
  };

  static const _colors = [
    'Black',
    'White',
    'Gray',
    'Beige',
    'Navy',
    'Brown',
    'Olive',
    'Cream',
    'Red',
    'Blue',
  ];

  /// Analyzes real image bytes captured/uploaded by the user by sending them
  /// to the secure proxy. [suggestedCategory] biases the prompt if the user
  /// pre-selected a category tab, but the AI can override it.
  static Future<DetectionResult> analyzeImage({
    required Uint8List imageBytes,
    String? suggestedCategory,
  }) async {
    if (_proxyBaseUrl.isEmpty) {
      // No proxy configured at build time — skip the network call entirely
      // and use the local fallback so the flow still works in dev.
      return _fallback(suggestedCategory);
    }

    try {
      final result = await _callProxy(
        imageBytes,
        suggestedCategory,
      ).timeout(const Duration(seconds: 25));
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'ClothingDetectionService: AI detection failed ($e), '
          'using fallback heuristic.',
        );
      }
      return _fallback(suggestedCategory);
    }
  }

  static Future<DetectionResult> _callProxy(
    Uint8List imageBytes,
    String? suggestedCategory,
  ) async {
    final b64 = base64Encode(imageBytes);

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_appSharedSecret.isNotEmpty) {
      headers['x-app-secret'] = _appSharedSecret;
    }

    final response = await http.post(
      Uri.parse('$_proxyBaseUrl/api/detect'),
      headers: headers,
      body: jsonEncode({
        'imageBase64': b64,
        if (suggestedCategory != null) 'suggestedCategory': suggestedCategory,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Proxy returned ${response.statusCode}: ${response.body}',
      );
    }

    final parsed = jsonDecode(response.body) as Map<String, dynamic>;
    if (parsed.containsKey('error')) {
      throw Exception('Proxy error: ${parsed['error']}');
    }

    // The proxy already validates/repairs enum values, but we defensively
    // re-validate here so a proxy version mismatch can never corrupt data.
    return DetectionResult(
      category: _pickValid(
        parsed['category'] as String?,
        ItemCategory.all,
        suggestedCategory ?? ItemCategory.top,
      ),
      type: (parsed['type'] as String?)?.trim().isNotEmpty == true
          ? (parsed['type'] as String).trim()
          : 'Item',
      color: (parsed['color'] as String?)?.trim().isNotEmpty == true
          ? (parsed['color'] as String).trim()
          : 'Black',
      pattern: _pickValid(
        parsed['pattern'] as String?,
        AppConstants.patterns,
        'Plain',
      ),
      style: _pickValid(
        parsed['style'] as String?,
        AppConstants.styles,
        'Casual',
      ),
      fit: _pickValid(parsed['fit'] as String?, AppConstants.fits, 'Regular'),
      season: _pickValid(
        parsed['season'] as String?,
        AppConstants.seasons,
        'All Season',
      ),
      confidence: ((parsed['confidence'] as num?)?.toDouble() ?? 0.85).clamp(
        0.0,
        1.0,
      ),
      isAiGenerated: true,
    );
  }

  static String _pickValid(
    String? value,
    List<String> allowed,
    String fallback,
  ) {
    if (value == null) return fallback;
    final match = allowed.firstWhere(
      (a) => a.toLowerCase() == value.toLowerCase(),
      orElse: () => '',
    );
    return match.isNotEmpty ? match : fallback;
  }

  /// Local heuristic used only when the proxy is unavailable/fails, so the
  /// Add Item flow degrades gracefully instead of breaking.
  static DetectionResult _fallback(String? suggestedCategory) {
    final category = suggestedCategory ?? ItemCategory.top;
    final types = _typesByCategory[category] ?? ['Item'];
    return DetectionResult(
      category: category,
      type: types[_rng.nextInt(types.length)],
      color: _colors[_rng.nextInt(_colors.length)],
      pattern: 'Plain',
      style: 'Casual',
      fit: 'Regular',
      season: 'All Season',
      confidence: 0.5,
      isAiGenerated: false,
    );
  }
}
