import 'package:flutter/material.dart';

/// Why someone is learning German. The German word doubles as a mini lesson.
enum LearningGoal {
  study('Study', 'das Studium', Icons.school_outlined),
  work('Work', 'die Arbeit', Icons.work_outline_rounded),
  living('Living there', 'das Leben', Icons.home_outlined),
  travel('Travel', 'die Reise', Icons.flight_takeoff_rounded),
  family('Family & friends', 'die Familie', Icons.favorite_border_rounded),
  fun('Just for fun', 'der Spaß', Icons.auto_awesome_outlined);

  const LearningGoal(this.label, this.german, this.icon);

  final String label;
  final String german;
  final IconData icon;
}

enum GermanLevel {
  a0('A0', 'Brand new', 'Starting from zero'),
  a1('A1', 'A few words', 'I know basics like Hallo and Danke'),
  a2('A2', 'Simple chats', 'I can introduce myself and order food'),
  b1('B1', 'Getting there', 'I can handle everyday conversations');

  const GermanLevel(this.code, this.title, this.description);

  final String code;
  final String title;
  final String description;
}

enum DailyGoal {
  casual(5, 'Casual', 3),
  regular(10, 'Regular', 5),
  serious(20, 'Serious', 10),
  intense(30, 'Intense', 15);

  const DailyGoal(this.words, this.title, this.minutes);

  final int words;
  final String title;
  final int minutes;
}

/// Answers collected during onboarding.
class OnboardingData {
  OnboardingData();

  factory OnboardingData.fromJson(Map<String, dynamic> j) {
    T? byName<T extends Enum>(List<T> values, Object? name) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return null;
    }

    final data = OnboardingData()
      ..name = j['name'] as String? ?? ''
      ..level = byName(GermanLevel.values, j['level'])
      ..dailyGoal =
          byName(DailyGoal.values, j['dailyGoal']) ?? DailyGoal.regular;
    for (final g in (j['goals'] as List? ?? const [])) {
      final goal = byName(LearningGoal.values, g);
      if (goal != null) data.goals.add(goal);
    }
    return data;
  }

  String name = '';
  final Set<LearningGoal> goals = {};
  GermanLevel? level;
  DailyGoal dailyGoal = DailyGoal.regular;

  /// Word pop-ups per day chosen during setup (0 = off).
  int wordPopups = 3;

  Map<String, dynamic> toJson() => {
    'name': name,
    'goals': [for (final g in goals) g.name],
    'level': level?.name,
    'dailyGoal': dailyGoal.name,
    'wordPopups': wordPopups,
  };
}
