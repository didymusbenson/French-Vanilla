/// Categories for glossary term filtering
enum GlossaryTermType {
  keyword,        // Keyword abilities (rule 702.X)
  keywordAction,  // Keyword actions (rule 701.X)
  cardType,       // Card types (rule 3XX)
  zone,           // Zones (rule 4XX)
  phaseStep,      // Phases and steps
  token,          // Token types (*Token)
  counter,        // Counters (rule 122)
  multiplayer,    // Multiplayer variants (rule 8XX, 9XX)
  obsolete,       // Obsolete terms
  other,          // Default/uncategorized
}

/// User-friendly display names for filter chips
extension GlossaryTermTypeExtension on GlossaryTermType {
  String get displayName {
    switch (this) {
      case GlossaryTermType.keyword:
        return 'Keywords';
      case GlossaryTermType.keywordAction:
        return 'Actions';
      case GlossaryTermType.cardType:
        return 'Card Types';
      case GlossaryTermType.zone:
        return 'Zones';
      case GlossaryTermType.phaseStep:
        return 'Phases & Steps';
      case GlossaryTermType.token:
        return 'Tokens';
      case GlossaryTermType.counter:
        return 'Counters';
      case GlossaryTermType.multiplayer:
        return 'Multiplayer';
      case GlossaryTermType.obsolete:
        return 'Obsolete';
      case GlossaryTermType.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case GlossaryTermType.keyword:
        return 'Ability keywords like Flying, Haste';
      case GlossaryTermType.keywordAction:
        return 'Game actions like Create, Destroy';
      case GlossaryTermType.cardType:
        return 'Types like Creature, Artifact';
      case GlossaryTermType.zone:
        return 'Game zones like Battlefield, Graveyard';
      case GlossaryTermType.phaseStep:
        return 'Turn phases and steps';
      case GlossaryTermType.token:
        return 'Predefined token types';
      case GlossaryTermType.counter:
        return 'Game counters like Poison, Charge';
      case GlossaryTermType.multiplayer:
        return 'Multiplayer variants and rules';
      case GlossaryTermType.obsolete:
        return 'Outdated terms no longer used';
      case GlossaryTermType.other:
        return 'General game concepts';
    }
  }
}

class GlossaryTerm {
  final String term;
  final String definition;
  final GlossaryTermType type;

  GlossaryTerm({
    required this.term,
    required this.definition,
    this.type = GlossaryTermType.other,
  });

  @override
  String toString() => term;
}
