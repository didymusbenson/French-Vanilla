/// Model for a Magic Tournament Rules (MTR) rule.
class MtrRule {
  final String number; // e.g., "1.1"
  final String title; // e.g., "Tournament Types"
  final String content; // Full text content

  MtrRule({
    required this.number,
    required this.title,
    required this.content,
  });

  factory MtrRule.fromJson(Map<String, dynamic> json) {
    return MtrRule(
      number: json['number'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'title': title,
      'content': content,
    };
  }
}

/// Model for an MTR section containing multiple rules.
class MtrSection {
  final int sectionNumber; // e.g., 1
  final String title; // e.g., "1. Tournament Fundamentals"
  final String sectionKey; // e.g., "mtr_section_1"
  final Map<String, dynamic> metadata;
  final List<MtrRule> rules;

  MtrSection({
    required this.sectionNumber,
    required this.title,
    required this.sectionKey,
    required this.metadata,
    required this.rules,
  });

  factory MtrSection.fromJson(Map<String, dynamic> json) {
    final rulesList = json['rules'] as List<dynamic>? ?? [];

    return MtrSection(
      sectionNumber: json['section_number'] as int,
      title: json['title'] as String,
      sectionKey: json['section_key'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      rules: rulesList.map((r) => MtrRule.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }

  String get effectiveDate => metadata['effective_date'] as String? ?? 'Unknown';
}

/// Model for MTR index (table of contents).
class MtrIndex {
  final String title; // "Magic Tournament Rules"
  final String documentType; // "mtr"
  final Map<String, dynamic> metadata;
  final List<MtrSectionInfo> sections;

  MtrIndex({
    required this.title,
    required this.documentType,
    required this.metadata,
    required this.sections,
  });

  factory MtrIndex.fromJson(Map<String, dynamic> json) {
    final sectionsList = json['sections'] as List<dynamic>? ?? [];

    return MtrIndex(
      title: json['title'] as String,
      documentType: json['document_type'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      sections: sectionsList.map((s) => MtrSectionInfo.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }

  String get effectiveDate => metadata['effective_date'] as String? ?? 'Unknown';
}

/// Brief section info from the index.
class MtrSectionInfo {
  final int sectionNumber;
  final String title;
  final String sectionKey;
  final int ruleCount;

  MtrSectionInfo({
    required this.sectionNumber,
    required this.title,
    required this.sectionKey,
    required this.ruleCount,
  });

  factory MtrSectionInfo.fromJson(Map<String, dynamic> json) {
    return MtrSectionInfo(
      sectionNumber: json['section_number'] as int,
      title: json['title'] as String,
      sectionKey: json['section_key'] as String,
      ruleCount: json['rule_count'] as int,
    );
  }
}
