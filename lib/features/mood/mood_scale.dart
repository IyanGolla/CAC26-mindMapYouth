import 'package:flutter/material.dart';

const moodLabels = {1: 'Really low', 2: 'Low', 3: 'Okay', 4: 'Good', 5: 'Great'};

const moodIcons = {
  1: Icons.sentiment_very_dissatisfied,
  2: Icons.sentiment_dissatisfied,
  3: Icons.sentiment_neutral,
  4: Icons.sentiment_satisfied,
  5: Icons.sentiment_very_satisfied,
};

const emotionTags = [
  'anxious', 'sad', 'angry', 'numb', 'stressed', 'lonely', 'tired', 'calm', 'hopeful', 'happy',
];

const contextTags = ['school', 'friends', 'family', 'sleep', 'social media', 'health', 'future'];

class ThinkingTrap {
  const ThinkingTrap(this.name, this.example);
  final String name;
  final String example;
}

const thinkingTraps = [
  ThinkingTrap('All-or-nothing',
      '"I got a B, so I\'m a failure." Things are only perfect or terrible.'),
  ThinkingTrap('Catastrophizing',
      '"If I mess up this presentation, my whole year is ruined."'),
  ThinkingTrap('Mind-reading',
      '"They didn\'t text back. They must hate me."'),
  ThinkingTrap('"Should" statements',
      '"I should be able to handle this. I shouldn\'t need help."'),
  ThinkingTrap('Emotional reasoning',
      '"I feel like a burden, so I must be one."'),
  ThinkingTrap('Overgeneralizing',
      '"This always happens. Nothing ever works out."'),
  ThinkingTrap('Not sure', 'That\'s fine. Naming it is optional.'),
];

String formatWhen(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '${months[d.month - 1]} ${d.day}, $h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}
