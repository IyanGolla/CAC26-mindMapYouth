/// Decides when to gently offer the Crisis Hub. The result is used once to
/// show a prompt and is never stored or sent anywhere.
class RiskSignalDetector {
  const RiskSignalDetector();

  static const lowestMood = 1;
  static const lowMoodDays = 3;

  // Deliberately general phrases; no method language.
  static const _phrases = [
    'kill myself',
    'killing myself',
    'end my life',
    'end it all',
    'want to die',
    'wanna die',
    'wish i was dead',
    'wish i were dead',
    'better off dead',
    'better off without me',
    'suicide',
    'suicidal',
    'hurt myself',
    'hurting myself',
    'harm myself',
    'self harm',
    'self-harm',
    'no reason to live',
    "don't want to be here",
    'dont want to be here',
    "can't go on",
    'cant go on',
    'kms',
  ];

  bool textHasSignal(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final t = ' ${text.toLowerCase().replaceAll(RegExp(r"[’`]"), "'").replaceAll(RegExp(r'\s+'), ' ')} ';
    for (final p in _phrases) {
      // Whole-word match so "kms" doesn't fire inside other words.
      if (RegExp('(?<![a-z])${RegExp.escape(p)}(?![a-z])').hasMatch(t)) {
        return true;
      }
    }
    return false;
  }

  /// True when the lowest mood was logged on [lowMoodDays] different days
  /// within the last 7 days.
  bool moodPatternHasSignal(
    List<({DateTime at, int mood})> entries, {
    required DateTime now,
  }) {
    final cutoff = now.subtract(const Duration(days: 7));
    final days = <String>{};
    for (final e in entries) {
      if (e.mood <= lowestMood && e.at.isAfter(cutoff)) {
        days.add('${e.at.year}-${e.at.month}-${e.at.day}');
      }
    }
    return days.length >= lowMoodDays;
  }
}
