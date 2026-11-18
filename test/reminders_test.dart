import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/services/reminders.dart';

void main() {
  const on = ReminderSettings(enabled: true, hour: 19, minute: 30);

  test('off means nothing is scheduled', () {
    expect(
      planReminders(
        now: DateTime(2026, 11, 17, 9),
        settings: const ReminderSettings(),
        practisedToday: false,
        streak: 0,
      ),
      isEmpty,
    );
  });

  test('plans a week, today included when not practised yet', () {
    final plans = planReminders(
      now: DateTime(2026, 11, 17, 9),
      settings: on,
      practisedToday: false,
      streak: 0,
    );
    expect(plans, hasLength(7));
    expect(plans.first.at, DateTime(2026, 11, 17, 19, 30));
    expect(plans.last.at, DateTime(2026, 11, 23, 19, 30));
    expect(plans.map((p) => p.id).toSet(), hasLength(7));
  });

  test('practised today: no reminder today, starts tomorrow', () {
    final plans = planReminders(
      now: DateTime(2026, 11, 17, 9),
      settings: on,
      practisedToday: true,
      streak: 3,
    );
    expect(plans, hasLength(6));
    expect(plans.first.at, DateTime(2026, 11, 18, 19, 30));
  });

  test('time already passed today: starts tomorrow', () {
    final plans = planReminders(
      now: DateTime(2026, 11, 17, 21),
      settings: on,
      practisedToday: false,
      streak: 0,
    );
    expect(plans.first.at.day, 18);
  });

  test('a streak at risk changes today\'s message', () {
    final plans = planReminders(
      now: DateTime(2026, 11, 17, 9),
      settings: on,
      practisedToday: false,
      streak: 5,
    );
    expect(plans.first.title, contains('5-day streak'));
    expect(plans[1].title, isNot(contains('streak')));
  });

  test('handles the end of a month', () {
    final plans = planReminders(
      now: DateTime(2026, 11, 29, 9),
      settings: on,
      practisedToday: true,
      streak: 0,
    );
    expect(plans.map((p) => p.at.day), [30, 1, 2, 3, 4, 5]);
    expect(plans[1].at.month, 12);
  });

  test('settings survive a round trip', () {
    final s = ReminderSettings.fromJson(on.copyWith(offered: true).toJson());
    expect(s.enabled, isTrue);
    expect(s.hour, 19);
    expect(s.minute, 30);
    expect(s.offered, isTrue);
  });
}
