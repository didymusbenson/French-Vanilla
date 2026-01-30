import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../screens/rule_detail_screen.dart';
import '../screens/mtr_rule_detail_screen.dart';
import '../services/rules_data_service.dart';
import '../services/judge_docs_service.dart';

/// Mixin that provides rule linking functionality to parse and navigate to rule references
mixin RuleLinkMixin<T extends StatefulWidget> on State<T> {
  final _ruleLinkDataService = RulesDataService();
  final _judgeDocsService = JudgeDocsService();

  /// Parses text and creates TextSpan with tappable rule references
  List<TextSpan> parseTextWithLinks(String text, TextStyle? baseStyle) {
    final spans = <TextSpan>[];

    // Pattern matches:
    // 1. "rule 704", "rule 702.9a", "rules 702.9" (traditional CR format)
    // 2. Bare references like "601.2b" or "601.2f–h" (in citations)
    // 3. "MTR section 4.3" (IPG → MTR cross-reference)
    // 4. "section 2.2" (MTR → MTR cross-reference)
    final crRulePattern = RegExp(
      r'(?:'
        r'\brule(?:s)?\s+(\d{3})(?:\.(\d+)([a-z])?)?'  // Traditional: "rule 601.2b"
        r'|'
        r'\b(\d{3})\.(\d+)([a-z])?(?:[–\-][a-z])?'  // Bare: "601.2f" or "601.2f–h" or "601.2f-h"
      r')\b',
      caseSensitive: false
    );

    // MTR section references: "MTR section 4.3" or "section 4.3"
    final mtrSectionPattern = RegExp(
      r'\b(?:MTR\s+)?section\s+(\d+)\.(\d+)\b',
      caseSensitive: false
    );

    // Collect all matches with their types
    final allMatches = <({int start, int end, String type, Match match})>[];

    for (final match in crRulePattern.allMatches(text)) {
      allMatches.add((start: match.start, end: match.end, type: 'cr', match: match));
    }

    for (final match in mtrSectionPattern.allMatches(text)) {
      allMatches.add((start: match.start, end: match.end, type: 'mtr', match: match));
    }

    // Sort by position
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    int lastMatchEnd = 0;
    for (final matchData in allMatches) {
      final match = matchData.match;

      // Add text before the match
      if (matchData.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, matchData.start),
          style: baseStyle,
        ));
      }

      if (matchData.type == 'cr') {
        // Handle CR rule reference
        String baseRule, ruleNumber, fullMatch;

        if (match.group(1) != null) {
          // Traditional format: "rule 601.2b"
          baseRule = match.group(1)!;
          final minorPart = match.group(2);
          final letterPart = match.group(3);

          ruleNumber = minorPart != null
              ? '$baseRule.$minorPart${letterPart ?? ''}'
              : baseRule;
          fullMatch = match.group(0)!;
        } else {
          // Bare format: "601.2f" or "601.2f–h" (range)
          baseRule = match.group(4)!;
          final minorPart = match.group(5)!;
          final letterPart = match.group(6) ?? '';

          ruleNumber = '$baseRule.$minorPart$letterPart';
          fullMatch = match.group(0)!;
        }

        // Add the tappable link for CR rule
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
      } else if (matchData.type == 'mtr') {
        // Handle MTR section reference: "MTR section 4.3" or "section 4.3"
        final sectionNumber = match.group(1)!;
        final ruleNumber = match.group(2)!;
        final mtrRuleNumber = '$sectionNumber.$ruleNumber';
        final fullMatch = match.group(0)!;

        // Add the tappable link for MTR rule
        spans.add(TextSpan(
          text: fullMatch,
          style: baseStyle?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => navigateToMtrRule(mtrRuleNumber),
        ));
      }

      lastMatchEnd = matchData.end;
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

  /// Navigate to an MTR rule
  Future<void> navigateToMtrRule(String ruleNumber) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final rule = await _judgeDocsService.findMtrRule(ruleNumber);

      if (rule == null) {
        throw Exception('MTR rule not found');
      }

      if (!mounted) return;

      // Close loading indicator
      Navigator.pop(context);

      // Navigate to the MTR rule detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MtrRuleDetailScreen(
            rule: rule,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load MTR rule: $e')),
        );
      }
    }
  }
}
