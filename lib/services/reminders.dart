import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/local_store.dart';

/// The learner's reminder choice.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 19,
    this.minute = 0,
    this.offered = false,
  });

  factory ReminderSettings.fromJson(Map<String, dynamic> j) => ReminderSettings(
    enabled: j['enabled'] as bool? ?? false,
    hour: j['hour'] as int? ?? 19,
    minute: j['minute'] as int? ?? 0,
    offered: j['offered'] as bool? ?? false,
  );

  final bool enabled;
  final int hour;
  final int minute;

  /// We asked once after the first lesson; never nag again.
  final bool offered;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    bool? offered,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    offered: offered ?? this.offered,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'offered': offered,
  };
}

/// One planned notification.
class PlannedReminder {
  const PlannedReminder(this.id, this.at, this.title, this.body);

  final int id;
  final DateTime at;
  final String title;
  final String body;
}

const _messages = [
  ('Zeit für Deutsch! ☕', 'A few minutes of German today keeps it growing.'),
  ('Hallo! 👋', 'Your words are waiting. Just one short lesson?'),
  ('Kleine Schritte 🌱', 'Small steps every day beat cramming. Ready?'),
  ('Los geht\'s! 🚀', 'Learn a few new words in about five minutes.'),
  ('Guten Abend 🌙', 'Finish the day with a quick German review.'),
  ('Weiter so! 💪', 'You\'re building a real habit. Keep it going.'),
  ('Viel Erfolg! ✨', 'Every word counts. Open Poppylo for today\'s lesson.'),
];

/// Plans the next week of reminders. Today is skipped when the learner has
/// already practised (or the time has passed); when a streak is at risk,
/// today's message says so.
@visibleForTesting
List<PlannedReminder> planReminders({
  required DateTime now,
  required ReminderSettings settings,
  required bool practisedToday,
  required int streak,
}) {
  if (!settings.enabled) return const [];
  final plans = <PlannedReminder>[];
  for (var offset = 0; offset < 7; offset++) {
    final at = DateTime(
      now.year,
      now.month,
      now.day + offset,
      settings.hour,
      settings.minute,
    );
    if (offset == 0 && (practisedToday || !at.isAfter(now))) continue;
    final dayIndex = at.difference(DateTime(2026)).inDays;
    var (title, body) = _messages[dayIndex % _messages.length];
    if (offset == 0 && streak > 0) {
      title = 'Your $streak-day streak 🔥';
      body = 'Practise today to keep it alive. It only takes a few minutes.';
    }
    plans.add(PlannedReminder(100 + offset, at, title, body));
  }
  return plans;
}

/// Daily practice reminders (local notifications; no server involved).
class Reminders extends ChangeNotifier {
  Reminders(this._store);

  static const storageKey = 'reminders.v1';

  final KeyValueStore _store;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;
  ReminderSettings settings = const ReminderSettings();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_practice',
      'Daily practice',
      channelDescription: 'A gentle daily reminder to practise German',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'ic_notification',
      color: Color(0xFF13294B),
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> load() async {
    final raw = await _store.read(storageKey);
    if (raw != null) {
      try {
        settings = ReminderSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } on FormatException {
        settings = const ReminderSettings();
      }
    }
  }

  Future<bool> _init() async {
    if (_initialised) return true;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialised = true;
      return true;
    } on Object catch (e) {
      debugPrint('Reminders unavailable: $e');
      return false;
    }
  }

  /// Asks for notification permission (Android 13+, iOS). Returns false if
  /// the learner declines.
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return true;
  }

  Future<void> update(
    ReminderSettings next, {
    required bool practisedToday,
    required int streak,
  }) async {
    settings = next;
    notifyListeners();
    await _store.write(storageKey, jsonEncode(next.toJson()));
    await reschedule(practisedToday: practisedToday, streak: streak);
  }

  /// Replaces the scheduled reminders. Call on start and after practice.
  Future<void> reschedule({
    required bool practisedToday,
    required int streak,
  }) async {
    if (!await _init()) return;
    try {
      for (var id = 100; id < 107; id++) {
        await _plugin.cancel(id: id);
      }
      final plans = planReminders(
        now: DateTime.now(),
        settings: settings,
        practisedToday: practisedToday,
        streak: streak,
      );
      for (final p in plans) {
        await _plugin.zonedSchedule(
          id: p.id,
          scheduledDate: tz.TZDateTime.from(p.at, tz.local),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: p.title,
          body: p.body,
        );
      }
    } on Object catch (e) {
      debugPrint('Could not schedule reminders: $e');
    }
  }
}

/// Provides [Reminders] to the widget tree (null in tests/previews).
class RemindersScope extends InheritedNotifier<Reminders> {
  const RemindersScope({
    super.key,
    required Reminders? reminders,
    required super.child,
  }) : super(notifier: reminders);

  static Reminders? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RemindersScope>()?.notifier;
}
