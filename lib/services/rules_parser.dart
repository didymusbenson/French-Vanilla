import '../models/rule.dart';
import '../models/glossary_term.dart';

class RulesParser {
  /// Parses a section's content to extract major rules (e.g., 100, 101, 102)
  /// Each major rule is broken into subrule groups (100.1, 100.2, etc.)
  static List<Rule> parseSection(String content) {
    final rules = <Rule>[];
    final lines = content.split('\n');

    // Pattern to match major rules like "100. General"
    final majorRulePattern = RegExp(r'^(\d{3})\.\s+(.+)$');
    // Pattern to match first-level subrules like "100.1."
    final firstLevelSubrulePattern = RegExp(r'^(\d{3})\.(\d+)\.\s');

    String? currentRuleNumber;
    String? currentRuleTitle;
    List<SubruleGroup> currentSubruleGroups = [];

    String? currentSubruleNumber;
    StringBuffer currentSubruleContent = StringBuffer();

    void saveCurrentSubrule() {
      final subruleNum = currentSubruleNumber;
      if (subruleNum != null && currentSubruleContent.isNotEmpty) {
        currentSubruleGroups.add(
          SubruleGroup(
            number: subruleNum,
            content: currentSubruleContent.toString().trim(),
          ),
        );
        currentSubruleNumber = null;
        currentSubruleContent = StringBuffer();
      }
    }

    void saveCurrentRule() {
      saveCurrentSubrule();
      final ruleNum = currentRuleNumber;
      final ruleTitle = currentRuleTitle;
      if (ruleNum != null && ruleTitle != null) {
        rules.add(
          Rule(
            number: ruleNum,
            title: ruleTitle,
            subruleGroups: List.from(currentSubruleGroups),
          ),
        );
        currentSubruleGroups = [];
      }
    }

    for (var line in lines) {
      final trimmedLine = line.trim();

      // Check for major rule (e.g., "100. General")
      final majorMatch = majorRulePattern.firstMatch(trimmedLine);
      if (majorMatch != null) {
        saveCurrentRule();
        currentRuleNumber = majorMatch.group(1);
        currentRuleTitle = majorMatch.group(2);
        continue;
      }

      // Skip if we're not in a rule yet
      if (currentRuleNumber == null) continue;

      // Check for first-level subrule (e.g., "100.1")
      final subruleMatch = firstLevelSubrulePattern.firstMatch(trimmedLine);
      if (subruleMatch != null) {
        saveCurrentSubrule();
        currentSubruleNumber =
            '${subruleMatch.group(1)}.${subruleMatch.group(2)}';
        currentSubruleContent.writeln(trimmedLine);
        continue;
      }

      // Add to current subrule content if we're in one
      if (currentSubruleNumber != null && trimmedLine.isNotEmpty) {
        currentSubruleContent.writeln(trimmedLine);
      }
    }

    // Save the last rule
    saveCurrentRule();

    return rules;
  }

  /// Parses the glossary content to extract terms and definitions
  /// Structure: Term, followed by definition lines, followed by blank line
  static List<GlossaryTerm> parseGlossary(String content) {
    final terms = <GlossaryTerm>[];
    final lines = content.split('\n');

    String? currentTerm;
    final currentDefinition = StringBuffer();
    var startParsing = false;
    var lastLineWasEmpty = true; // Start as true to catch first term

    void saveCurrentTerm() {
      final term = currentTerm;
      if (term != null) {
        final def = currentDefinition.toString().trim();
        if (def.isNotEmpty) {
          terms.add(
            GlossaryTerm(
              term: term,
              definition: def,
              type: _classifyGlossaryTerm(term, def),
            ),
          );
        }
        currentTerm = null;
        currentDefinition.clear();
      }
    }

    for (var line in lines) {
      if (line.trim() == 'Glossary') {
        startParsing = true;
        continue;
      }

      if (!startParsing) continue;

      final trimmedLine = line.trim();

      // Empty line signals end of current term's definition
      if (trimmedLine.isEmpty) {
        saveCurrentTerm();
        lastLineWasEmpty = true;
        continue;
      }

      // First non-empty line after a blank line (or start) is a new term
      if (lastLineWasEmpty) {
        currentTerm = trimmedLine;
        lastLineWasEmpty = false;
      } else {
        // Subsequent non-empty lines are part of the definition
        if (currentDefinition.isNotEmpty) {
          currentDefinition.writeln();
        }
        currentDefinition.write(trimmedLine);
      }
    }

    // Don't forget the last term if file doesn't end with blank line
    saveCurrentTerm();

    return terms;
  }

  /// Classifies a glossary term based on its name and definition content.
  /// Priority order matters: more specific matches take precedence.
  static GlossaryTermType _classifyGlossaryTerm(
    String term,
    String definition,
  ) {
    // Obsolete terms are explicitly marked
    if (definition.contains('(Obsolete)')) {
      return GlossaryTermType.obsolete;
    }

    // Tokens have a consistent naming pattern
    if (term.endsWith(' Token')) {
      return GlossaryTermType.token;
    }

    // Counters: End in "Counter", reference rule 122, or involve +1/+1 / -1/-1
    if (term.endsWith(' Counter') ||
        definition.contains('rule 122') ||
        definition.contains('+1/+1') ||
        definition.contains('-1/-1')) {
      return GlossaryTermType.counter;
    }

    // Multiplayer: Reference rule 8XX or 9XX
    if (RegExp(r'rule [89]\d{2}').hasMatch(definition)) {
      return GlossaryTermType.multiplayer;
    }

    // Keyword abilities reference rule 702.X
    if (RegExp(r'rule 702\.\d').hasMatch(definition)) {
      return GlossaryTermType.keyword;
    }

    // Keyword actions reference rule 701.X
    if (RegExp(r'rule 701\.\d').hasMatch(definition)) {
      return GlossaryTermType.keywordAction;
    }

    // Phases and steps - check term name first for accuracy
    if (term.contains('Step') || term.contains('Phase')) {
      return GlossaryTermType.phaseStep;
    }

    // Zones reference rule 4XX (400-499)
    if (RegExp(r'rule 4\d{2}').hasMatch(definition)) {
      return GlossaryTermType.zone;
    }

    // Card types reference rule 3XX (300-399) or explicitly say "card type"
    if (RegExp(r'rule 3\d{2}').hasMatch(definition) ||
        definition.contains('card type') ||
        definition.contains('A card type')) {
      return GlossaryTermType.cardType;
    }

    return GlossaryTermType.other;
  }
}
