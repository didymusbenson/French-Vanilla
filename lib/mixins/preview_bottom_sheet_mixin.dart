import 'package:flutter/material.dart';
import '../models/rule.dart';
import '../models/mtr_rule.dart';
import '../models/ipg_infraction.dart';
import '../models/card.dart';
import '../screens/glossary_detail_screen.dart';
import '../screens/rule_detail_screen.dart';
import '../screens/mtr_section_detail_screen.dart';
import '../screens/ipg_infraction_detail_screen.dart';
import '../screens/card_detail_screen.dart';
import 'rule_link_mixin.dart';
import 'formatted_content_mixin.dart';

/// Mixin providing shared bottom sheet functionality for previewing rules and glossary terms
/// Used by BookmarksScreen and SearchScreen to reduce code duplication
/// Requires RuleLinkMixin to provide clickable rule references
/// Uses FormattedContentMixin for consistent example rendering
mixin PreviewBottomSheetMixin<T extends StatefulWidget> on State<T>, RuleLinkMixin<T>, FormattedContentMixin<T> {

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
    String? highlightSubruleNumber, // Optional - if null, no highlighting on navigation
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
                          highlightSubruleNumber: highlightSubruleNumber,
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

  /// Shows a bottom sheet preview for an MTR rule
  void showMtrBottomSheet({
    required MtrRule rule,
    required Object sectionNumber,
    required String sectionTitle,
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
                '${rule.number} ${rule.title}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'MTR — $sectionTitle',
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
                    child: buildFormattedContent(rule.content),
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
                        builder: (context) => MtrSectionDetailScreen(
                          sectionNumber: sectionNumber,
                          sectionTitle: sectionTitle,
                          highlightRuleNumber: rule.number,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('Go to $sectionTitle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a bottom sheet preview for an IPG infraction
  void showIpgBottomSheet({
    required IpgInfraction infraction,
  }) {
    // Use definition as preview content, fall back to first example
    final previewContent = infraction.definition ??
        (infraction.examples.isNotEmpty ? infraction.examples.first : '');

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
                infraction.cleanTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'IPG ${infraction.number}${infraction.penalty != null ? ' — ${infraction.penalty}' : ''}',
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
                    child: buildFormattedContent(previewContent),
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
                        builder: (context) => IpgInfractionDetailScreen(
                          infraction: infraction,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('Go to ${infraction.cleanTitle}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a bottom sheet preview for a card with rulings
  void showCardBottomSheet({
    required MagicCard card,
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
                card.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.type,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              // Content - scrollable if needed
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Oracle text
                      if (card.text != null && card.text!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            card.text!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ),
                      // Rulings count
                      if (card.rulings.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          '${card.rulings.length} ruling${card.rulings.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Show first ruling as preview
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.rulings.first.date,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                card.rulings.first.text,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
                        builder: (context) => CardDetailScreen(card: card),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('View All Rulings (${card.rulings.length})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
