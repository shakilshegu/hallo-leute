import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/local_store.dart';
import '../data/progress.dart';
import '../data/vocabulary.dart';

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
  ('Nur positiv ✨', 'Every word counts. Open Hallo Leute for today\'s lesson.'),
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

/// One word pop-up: a flashcard-style notification.
class PlannedPopup {
  const PlannedPopup(this.id, this.at, this.word);

  final int id;
  final DateTime at;
  final GermanWord word;
}

/// Times of day for [perDay] pop-ups, spread between 10:00 and 20:00.
List<(int, int)> popupTimes(int perDay) => switch (perDay) {
  <= 0 => const [],
  1 => const [(12, 0)],
  2 => const [(10, 0), (18, 0)],
  3 => const [(10, 0), (14, 0), (18, 0)],
  4 => const [(10, 0), (13, 0), (16, 0), (19, 0)],
  _ => const [(9, 30), (12, 0), (14, 30), (17, 0), (19, 30)],
};

/// Plans the next week of word pop-ups. Each day shows that day's words
/// (the same "words of the day" as on Home), skipping words already
/// learned.
@visibleForTesting
List<PlannedPopup> planWordPopups({
  required DateTime now,
  required int perDay,
  required List<GermanWord> Function(DateTime day) wordsFor,
  required bool Function(GermanWord word) isLearned,
}) {
  final times = popupTimes(perDay);
  final plans = <PlannedPopup>[];
  for (var offset = 0; offset < 7; offset++) {
    final day = DateTime(now.year, now.month, now.day + offset);
    final all = wordsFor(day);
    final fresh = all.where((w) => !isLearned(w)).toList();
    final words = fresh.isEmpty ? all : fresh;
    if (words.isEmpty) continue;
    for (var i = 0; i < times.length; i++) {
      final (h, m) = times[i];
      final at = DateTime(day.year, day.month, day.day, h, m);
      if (!at.isAfter(now)) continue;
      plans.add(
        PlannedPopup(200 + offset * 10 + i, at, words[i % words.length]),
      );
    }
  }
  return plans;
}

/// Daily practice reminders (local notifications; no server involved).
class Reminders extends ChangeNotifier {
  Reminders(this._store);

  static const storageKey = 'reminders.v1';
  static const popupsKey = 'word_popups.v1';

  final KeyValueStore _store;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  /// Key of the word whose pop-up the learner tapped; the app opens its
  /// flashcard and then clears this back to null.
  final openedWord = ValueNotifier<String?>(null);

  void _onTap(NotificationResponse r) {
    final payload = r.payload;
    if (payload != null && payload.startsWith(_wordPayload)) {
      openedWord.value = payload.substring(_wordPayload.length);
    }
  }

  /// Call once at start: if a word pop-up launched the app, open its card.
  Future<void> checkLaunch() async {
    if (!await _init()) return;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      final r = details?.notificationResponse;
      if ((details?.didNotificationLaunchApp ?? false) && r != null) _onTap(r);
    } on Object catch (e) {
      debugPrint('Could not read launch details: $e');
    }
  }

  ReminderSettings settings = const ReminderSettings();

  /// Word pop-ups per day (0 = off).
  int popupsPerDay = 0;

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
    popupsPerDay = int.tryParse(await _store.read(popupsKey) ?? '') ?? 0;
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
        onDidReceiveNotificationResponse: _onTap,
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

extension WordPopups on Reminders {
  /// Saves the pop-up choice and (re)schedules them.
  Future<void> setPopups(
    int perDay, {
    required List<GermanWord> Function(DateTime day) wordsFor,
    required bool Function(GermanWord word) isLearned,
  }) async {
    popupsPerDay = perDay;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    notifyListeners();
    await _store.write(Reminders.popupsKey, '$perDay');
    await reschedulePopups(wordsFor: wordsFor, isLearned: isLearned);
  }

  /// Replaces the scheduled word pop-ups (ids 200–269).
  Future<void> reschedulePopups({
    required List<GermanWord> Function(DateTime day) wordsFor,
    required bool Function(GermanWord word) isLearned,
  }) async {
    if (!await _init()) return;
    try {
      for (var id = 200; id < 270; id++) {
        await _plugin.cancel(id: id);
      }
      final plans = planWordPopups(
        now: DateTime.now(),
        perDay: popupsPerDay,
        wordsFor: wordsFor,
        isLearned: isLearned,
      );
      for (final p in plans) {
        final (title, body, details) = _popupFor(p.word);
        await _plugin.zonedSchedule(
          payload: _wordPayload + LearningProgress.keyOf(p.word),
          id: p.id,
          scheduledDate: tz.TZDateTime.from(p.at, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: title,
          body: body,
        );
      }
    } on Object catch (e) {
      debugPrint('Could not schedule word pop-ups: $e');
    }
  }
}

/// Shows one word pop-up right now, so the learner can see what they
/// look like (Profile → "Send a test pop-up").
extension WordPopupPreview on Reminders {
  Future<bool> showPopupNow(GermanWord word) async {
    if (!await _init()) return false;
    try {
      final (title, body, details) = _popupFor(word);
      await _plugin.show(
        payload: _wordPayload + LearningProgress.keyOf(word),
        id: 270,
        title: title,
        body: body,
        notificationDetails: details,
      );
      return true;
    } on Object catch (e) {
      debugPrint('Could not show a word pop-up: $e');
      return false;
    }
  }
}

const _wordPayload = 'word:';

(String, String, NotificationDetails) _popupFor(GermanWord w) {
  final german = [w.article, w.word].where((s) => s.isNotEmpty).join(' ');
  final back = [
    w.meaning,
    if (w.hasExample) '„${w.example}“',
    if (w.hasExample) w.exampleMeaning,
  ].join('\n');
  return (
    german,
    'Swipe down for the meaning · tap for the flashcard',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'word_popups',
        'Word pop-ups',
        channelDescription: 'German flashcards during the day',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: 'ic_notification',
        color: const Color(0xFF13294B),
        // Collapsed: the German word. Swipe down: meaning + example,
        // like flipping a flashcard.
        styleInformation: BigTextStyleInformation(
          back,
          contentTitle: german,
          summaryText: 'Word of the day',
        ),
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );
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
