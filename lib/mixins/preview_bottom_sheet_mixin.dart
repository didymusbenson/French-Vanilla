import 'package:flutter/material.dart';
import '../models/rule.dart';
import '../screens/glossary_detail_screen.dart';
import '../screens/rule_detail_screen.dart';
import 'rule_link_mixin.dart';

/// Mixin providing shared bottom sheet functionality for previewing rules and glossary terms
/// Used by BookmarksScreen and SearchScreen to reduce code duplication
/// Requires RuleLinkMixin to provide clickable rule references
mixin PreviewBottomSheetMixin<T extends StatefulWidget> on State<T>, RuleLinkMixin<T> {
  /// Builds formatted subrule content with spacing between subsections
  Widget buildFormattedContent(String content) {
    // Strip the leading subrule number from the first line since it's shown in the header
    // Matches "201.1. " or "702.90a " (period OR letter after minor number)
    final leadingNumberPattern = RegExp(r'^\d{3}\.\d+([a-z]|\.)\s+');
    String processedContent = content;
    if (leadingNumberPattern.hasMatch(content)) {
      processedContent = content.replaceFirst(leadingNumberPattern, '');
    }

    final lines = processedContent.split('\n');
    final subsections = <String>[];
    // Matches "100.1." or "100.1a" (note: letter variants have NO dot after them)
    final subsectionPattern = RegExp(r'^\d{3}\.\d+([a-z]|\.)\s');

    var currentSubsection = StringBuffer();

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Check if this is the start of a new subsection
      if (subsectionPattern.hasMatch(trimmedLine)) {
        // Save the previous subsection if it exists
        if (currentSubsection.isNotEmpty) {
          subsections.add(currentSubsection.toString().trim());
          currentSubsection = StringBuffer();
        }
        currentSubsection.writeln(line);
      } else if (trimmedLine.isNotEmpty) {
        currentSubsection.writeln(line);
      }
    }

    // Don't forget the last subsection
    if (currentSubsection.isNotEmpty) {
      subsections.add(currentSubsection.toString().trim());
    }

    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.6,
    );

    // Build the widget with spacing between subsections
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < subsections.length; i++) ...[
          RichText(
            text: TextSpan(
              children: parseTextWithLinks(subsections[i], baseStyle),
            ),
          ),
          if (i < subsections.length - 1)
            Center(
              child: Text(
                '—',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// Shows a bottom sheet preview for a glossary term
  void showGlossaryBottomSheet({
    required String term,
    required String definition,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                term,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Glossary Term',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              // Content - scrollable if needed
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: parseTextWithLinks(
                          definition,
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Action button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    // Navigate to glossary screen with this term highlighted
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GlossaryDetailScreen(
                          highlightTerm: term,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Go to Glossary'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a bottom sheet preview for a rule subrule
  void showRuleBottomSheet({
    required Rule rule,
    required int sectionNumber,
    required String subruleNumber,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                '${rule.number}. ${rule.title}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Subrule $subruleNumber',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              // Content - scrollable if needed
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: buildFormattedContent(content),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Action button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RuleDetailScreen(
                          rule: rule,
                          sectionNumber: sectionNumber,
                          highlightSubruleNumber: subruleNumber,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('Go to Rule ${rule.number}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
