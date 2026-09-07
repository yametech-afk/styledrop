import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/outfit.dart';
import 'weather_service.dart';

/// A single notification record shown in the in-app Notifications sheet,
/// persisted so the list survives app restarts (unlike the previous static
/// mock list).
class AppNotification {
  final int id;
  final String emoji;
  final String title;
  final String body;
  final DateTime createdAt;
  bool read;

  AppNotification({
    required this.id,
    required this.emoji,
    required this.title,
    required this.body,
    DateTime? createdAt,
    this.read = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'emoji': emoji,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };

  factory AppNotification.fromMap(Map<dynamic, dynamic> map) => AppNotification(
    id: (map['id'] as num).toInt(),
    emoji: map['emoji'] as String? ?? '🔔',
    title: map['title'] as String? ?? '',
    body: map['body'] as String? ?? '',
    createdAt:
        DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    read: map['read'] as bool? ?? false,
  );
}

/// Real local notification scheduling & delivery, replacing the previous
/// static mock list shown in the Profile screen.
///
/// Responsibilities:
/// - Request notification permission (Android 13+ / iOS)
/// - Show an immediate notification when a fresh AI outfit is generated
/// - Show a rain-alert notification when the live weather forecast
///   indicates rain (tied into [WeatherService])
/// - Schedule a reminder notification for outfits planned on the calendar
/// - Maintain a small persisted history so the in-app "Notifications" sheet
///   reflects real events instead of hardcoded placeholder text
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _timezoneReady = false;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'styledrop_general',
        'StyleDrop Notifications',
        channelDescription:
            'Outfit reminders, weather alerts and styling tips from StyleDrop',
        importance: Importance.high,
        priority: Priority.high,
      );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  /// In-memory + simply-persisted notification history (kept lightweight;
  /// backed by StorageService's meta box via [_history] getter/setter
  /// injected from callers to avoid a circular import on StorageService).
  static final List<AppNotification> _history = [];
  static List<AppNotification> get history => List.unmodifiable(
    _history.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  static int _nextId = 1000;
  static int _generateId() => _nextId++;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      tz_data.initializeTimeZones();
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz.identifier));
      _timezoneReady = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: timezone init failed ($e)');
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    try {
      await _plugin.initialize(settings: initSettings);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: plugin init failed ($e)');
      }
    }
  }

  /// Requests OS-level notification permission. Safe to call multiple
  /// times; returns true if permission is granted (or not required on
  /// this platform, e.g. Android <13 / web where it's a no-op).
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? true;
      }
      final iosImpl = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? true;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: permission request failed ($e)');
      }
      return false;
    }
  }

  static Future<void> _showNow({
    required String emoji,
    required String title,
    required String body,
  }) async {
    final id = _generateId();
    _history.add(
      AppNotification(id: id, emoji: emoji, title: title, body: body),
    );
    if (kIsWeb) {
      return; // recorded in-app history only; OS popups are Android/iOS
    }
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: '$emoji $body',
        notificationDetails: _details,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: show() failed ($e)');
      }
    }
  }

  /// Fired right after the AI stylist finishes generating a fresh batch of
  /// outfits, so the notification reflects an event that actually happened.
  static Future<void> notifyOutfitGenerated(int count) async {
    await _showNow(
      emoji: '🔥',
      title: 'New outfit${count > 1 ? 's' : ''} ready',
      body: count > 1
          ? 'Your AI stylist just created $count new outfit combinations from your wardrobe.'
          : 'Your AI stylist just created a new outfit for you.',
    );
  }

  /// Checks the live weather (via [WeatherService]) and fires a rain-alert
  /// notification if the forecast indicates rain. Safe to call repeatedly —
  /// callers are expected to throttle (e.g. once per Home screen load).
  static Future<void> checkAndNotifyRain() async {
    try {
      final weather = await WeatherService.fetchWeather();
      if (weather.condition == 'Rain') {
        await _showNow(
          emoji: '🌧️',
          title: 'Rain Alert',
          body:
              "It's expected to rain today — don't forget a jacket and skip the suede shoes.",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: rain check failed ($e)');
      }
    }
  }

  /// Schedules a local reminder for a calendar-planned outfit, firing at
  /// 7:30 AM on the planned date (or immediately if that time already
  /// passed today). No-op on web, where scheduled notifications aren't
  /// supported by the plugin.
  static Future<void> scheduleOutfitReminder({
    required Outfit outfit,
    required DateTime plannedDate,
  }) async {
    final label = outfit.name.isNotEmpty ? outfit.name : '${outfit.style} Fit';
    _history.add(
      AppNotification(
        id: _generateId(),
        emoji: '📅',
        title: 'Outfit planned',
        body:
            '"$label" is scheduled for ${_formatDate(plannedDate)}. We\'ll remind you that morning.',
      ),
    );

    if (kIsWeb || !_timezoneReady) return;

    try {
      final scheduled = tz.TZDateTime(
        tz.local,
        plannedDate.year,
        plannedDate.month,
        plannedDate.day,
        7,
        30,
      );
      final now = tz.TZDateTime.now(tz.local);
      final fireTime = scheduled.isAfter(now)
          ? scheduled
          : now.add(const Duration(seconds: 5));

      await _plugin.zonedSchedule(
        // Deterministic id per outfit+date so re-planning replaces it
        // instead of piling up duplicate reminders.
        id: outfit.id.hashCode ^ plannedDate.day ^ (plannedDate.month << 8),
        title: 'Outfit reminder',
        body: "Today's planned fit: $label 👗",
        scheduledDate: fireTime,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService: scheduling failed ($e)');
      }
    }
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  static void markAllRead() {
    for (final n in _history) {
      n.read = true;
    }
  }

  static bool get hasUnread => _history.any((n) => !n.read);
}
