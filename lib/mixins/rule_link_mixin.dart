import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../screens/rule_detail_screen.dart';
import '../services/rules_data_service.dart';

/// Mixin that provides rule linking functionality to parse and navigate to rule references
mixin RuleLinkMixin<T extends StatefulWidget> on State<T> {
  final _ruleLinkDataService = RulesDataService();

  // Pattern matches: "rule 704", "rule 702.9", "rule 702.9a", "rules 702.9", etc.
  // Also matches variations like "see rule 704" or "Rule 702.9a"
  static final rulePattern = RegExp(r'\brule(?:s)?\s+(\d{3})(?:\.(\d+)([a-z])?)?\b', caseSensitive: false);

  /// Parses text and creates TextSpan with tappable rule references
  List<TextSpan> parseTextWithLinks(String text, TextStyle? baseStyle) {
    final spans = <TextSpan>[];

    int lastMatchEnd = 0;
    for (final match in rulePattern.allMatches(text)) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      // Extract rule number (e.g., "702.9a" or just "704")
      final baseRule = match.group(1)!; // Always captured (e.g., "704" or "702")
      final minorPart = match.group(2); // Optional decimal part (e.g., "9")
      final letterPart = match.group(3); // Optional letter (e.g., "a")

      final ruleNumber = minorPart != null
          ? '$baseRule.$minorPart${letterPart ?? ''}'
          : baseRule;

      final fullMatch = match.group(0)!; // Full matched text like "rule 704" or "rule 702.9a"

      // Add the tappable link
      spans.add(TextSpan(
        text: fullMatch,
        style: baseStyle?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w500,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => navigateToRule(ruleNumber),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after the last match
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }

  /// Navigate to a referenced rule
  Future<void> navigateToRule(String ruleNumber) async {
    // Parse the rule number to extract section and rule info
    // Format: "704" -> section 7, rule "704"
    // Format: "702.9a" -> section 7, rule "702", highlight subrule "702.9a"
    final ruleMatch = RegExp(r'^(\d)(\d{2})(?:\.(\d+)([a-z])?)?$').firstMatch(ruleNumber);

    if (ruleMatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to parse rule reference')),
      );
      return;
    }

    final sectionNumber = int.parse(ruleMatch.group(1)!);
    final baseRuleNumber = '${ruleMatch.group(1)}${ruleMatch.group(2)}';

    // Only highlight a specific subrule if the reference includes a decimal part
    // Strip letter suffix (e.g., "702.9a" -> "702.9") since we only index base subrules
    String? highlightSubrule;
    if (ruleMatch.group(3) != null) {
      highlightSubrule = '${ruleMatch.group(1)}${ruleMatch.group(2)}.${ruleMatch.group(3)}';
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final rules = await _ruleLinkDataService.getRulesForSection(sectionNumber);
      final targetRule = rules.firstWhere(
        (r) => r.number == baseRuleNumber,
        orElse: () => throw Exception('Rule not found'),
      );

      if (!mounted) return;

      // Close loading indicator
      Navigator.pop(context);

      // Navigate to the rule detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RuleDetailScreen(
            rule: targetRule,
            sectionNumber: sectionNumber,
            highlightSubruleNumber: highlightSubrule,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rule: $e')),
        );
      }
    }
  }
}
