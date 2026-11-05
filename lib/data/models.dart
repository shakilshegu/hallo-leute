/// German grammatical gender of a noun.
enum Article { der, die, das }

/// Why the learner wants German – decides which topics come first.
enum LearningReason {
  studies('🎓', 'Studies', 'Lectures, exams & campus life'),
  work('💼', 'Work', 'Meetings, emails & small talk'),
  living('🏠', 'Life in Germany', 'Shopping, doctors & neighbours'),
  fun('✨', 'Just for fun', 'Travel, films & curiosity');

  const LearningReason(this.emoji, this.title, this.subtitle);

  final String emoji;
  final String title;
  final String subtitle;
}

/// Common European Framework (CEFR) language level.
enum CefrLevel {
  a1('A1', 'Beginner', 'Hallo and Danke… and that’s about it'),
  a2('A2', 'Elementary', 'I can order a coffee and introduce myself'),
  b1('B1', 'Intermediate', 'I can chat about my day, with a few pauses'),
  b2('B2', 'Upper intermediate', 'I follow most conversations just fine'),
  c1('C1', 'Advanced', 'I’m here to polish my vocabulary');

  const CefrLevel(this.code, this.title, this.description);

  final String code;
  final String title;
  final String description;
}

/// Daily word goal options shown during onboarding.
class DailyGoalOption {
  const DailyGoalOption({
    required this.words,
    required this.emoji,
    required this.label,
    required this.minutes,
    this.popular = false,
  });

  final int words;
  final String emoji;
  final String label;
  final int minutes;
  final bool popular;

  static const all = [
    DailyGoalOption(words: 5, emoji: '🌱', label: 'Easy-going', minutes: 3),
    DailyGoalOption(
      words: 10,
      emoji: '🔥',
      label: 'Steady',
      minutes: 7,
      popular: true,
    ),
    DailyGoalOption(words: 20, emoji: '🚀', label: 'Ambitious', minutes: 15),
  ];
}
