void main() {
  // Test pattern matching for rule references
  final rulePattern = RegExp(
    r'(?:'
      r'\brule(?:s)?\s+(\d{3})(?:\.(\d+)([a-z])?)?'  // Traditional: "rule 601.2b"
      r'|'
      r'\b(\d{3})\.(\d+)([a-z])?(?:[–\-][a-z])?'  // Bare: "601.2f" or "601.2f–h" or "601.2f-h"
    r')\b',
    caseSensitive: false
  );

  // Test cases from rule 702.140a
  final testCases = [
    'Mutate [cost] means "You may pay [cost]',  // No match expected
    'see rule 601.2b and 601.2f–h',              // Should match: "rule 601.2b", "601.2b", "601.2f–h"
    '(see 601.2b and 601.2f–h)',                 // Should match: "601.2b", "601.2f–h"
    'See rules 601.2b and 601.2f-h.',            // Should match with hyphen too
    'rule 704',                                   // Traditional simple
    'rule 702.9a',                                // Traditional with letter
    '601.2b',                                     // Bare
    '601.2f–h',                                   // Range
    'This is rule 100.4 text',                    // Traditional in sentence
    'See 704.5g and 704.5h',                      // Multiple bare
  ];

  print('=' * 70);
  print('Testing Rule Pattern Matching');
  print('=' * 70);

  for (final testCase in testCases) {
    print('\nTest: "$testCase"');
    final matches = rulePattern.allMatches(testCase);

    if (matches.isEmpty) {
      print('  ❌ No matches');
    } else {
      for (final match in matches) {
        print('  ✓ Match: "${match.group(0)}"');

        // Extract rule number like in the actual code
        String ruleNumber;
        if (match.group(1) != null) {
          // Traditional format
          final baseRule = match.group(1)!;
          final minorPart = match.group(2);
          final letterPart = match.group(3);
          ruleNumber = minorPart != null
              ? '$baseRule.$minorPart${letterPart ?? ''}'
              : baseRule;
        } else {
          // Bare format
          final baseRule = match.group(4)!;
          final minorPart = match.group(5)!;
          final letterPart = match.group(6) ?? '';
          ruleNumber = '$baseRule.$minorPart$letterPart';
        }

        print('    → Will navigate to: $ruleNumber');
      }
    }
  }

  print('\n' + '=' * 70);
  print('Specific Test: Rule 702.140a Citation');
  print('=' * 70);

  final rule702140a = 'Casting a spell using its mutate ability follows the rules for paying alternative costs (see 601.2b and 601.2f–h).';

  print('\nFull text: "$rule702140a"');
  print('\nMatches found:');

  final matches = rulePattern.allMatches(rule702140a);
  if (matches.isEmpty) {
    print('  ❌ NO MATCHES FOUND - PATTERN FAILED!');
  } else {
    for (final match in matches) {
      final fullMatch = match.group(0)!;
      final start = match.start;
      final end = match.end;

      // Extract rule number
      String ruleNumber;
      if (match.group(1) != null) {
        final baseRule = match.group(1)!;
        final minorPart = match.group(2);
        final letterPart = match.group(3);
        ruleNumber = minorPart != null
            ? '$baseRule.$minorPart${letterPart ?? ''}'
            : baseRule;
      } else {
        final baseRule = match.group(4)!;
        final minorPart = match.group(5)!;
        final letterPart = match.group(6) ?? '';
        ruleNumber = '$baseRule.$minorPart$letterPart';
      }

      print('  ✓ Found: "$fullMatch" at position $start-$end');
      print('    → Will navigate to rule: $ruleNumber');
      print('    → Opens: Rule ${ruleNumber.substring(0, 3)}');
      print('    → Highlights: Subrule ${ruleNumber.substring(0, ruleNumber.length >= 5 ? 5 : ruleNumber.length)}');
    }
  }
}
