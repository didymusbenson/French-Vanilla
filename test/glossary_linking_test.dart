import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Glossary Linking Regex', () {
    // Pattern to match "See [Capitalized Terms]"
    // - Matches "See "
    // - Matches one or more capitalized words, possibly separated by space or comma
    // - Stops before a period, parenthesis, or end of line
    final pattern = RegExp(r'See (([A-Z][a-zA-Z]+(?:,?\s[A-Z][a-zA-Z]+)*))');

    test('Matches simple term', () {
      final text = "See Casualty.";
      final match = pattern.firstMatch(text);
      expect(match, isNotNull);
      expect(match!.group(1), 'Casualty');
    });

    test('Matches multi-word term', () {
      final text = "See Active Player, Nonactive Player Order.";
      final match = pattern.firstMatch(text);
      expect(match, isNotNull);
      expect(match!.group(1), 'Active Player, Nonactive Player Order');
    });

    test('Matches term inside parenthesis', () {
      final text = "(See Casualty)";
      final match = pattern.firstMatch(text);
      expect(match, isNotNull);
      expect(match!.group(1), 'Casualty');
    });

    test('Matches term with other capitalization rules', () {
      // "See rule 702" should NOT be matched as a glossary term by this regex (technically "Rule" is cap, but we might want to exclude "Rule" explicitly if needed, though "Rule 702" isn't a glossary term anyway)
      // Actually "Rule" starts with cap.
      // We might want to filter out "Rule X" later, or refine regex.
      // But "Rule 702" is handled by the OTHER regex. We should ensure they play nice.
    });
  });
}
