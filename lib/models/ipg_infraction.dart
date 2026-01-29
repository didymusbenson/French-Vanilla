/// Model for an IPG (Infraction Procedure Guide) infraction.
class IpgInfraction {
  final String number; // e.g., "2.1"
  final String title; // e.g., "Game Play Error — Missed Trigger"
  final String? penalty; // e.g., "Warning", "No Penalty", etc.
  final String? definition;
  final List<String> examples;
  final String? philosophy;
  final String? additionalRemedy;
  final String? upgrade;

  IpgInfraction({
    required this.number,
    required this.title,
    this.penalty,
    this.definition,
    required this.examples,
    this.philosophy,
    this.additionalRemedy,
    this.upgrade,
  });

  factory IpgInfraction.fromJson(Map<String, dynamic> json) {
    final examplesList = json['examples'] as List<dynamic>? ?? [];

    return IpgInfraction(
      number: json['number'] as String,
      title: json['title'] as String,
      penalty: json['penalty'] as String?,
      definition: json['definition'] as String?,
      examples: examplesList.map((e) => e as String).toList(),
      philosophy: json['philosophy'] as String?,
      additionalRemedy: json['additional_remedy'] as String?,
      upgrade: json['upgrade'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'title': title,
      'penalty': penalty,
      'definition': definition,
      'examples': examples,
      'philosophy': philosophy,
      'additional_remedy': additionalRemedy,
      'upgrade': upgrade,
    };
  }

  /// Get a user-friendly title without the penalty suffix.
  String get cleanTitle {
    if (penalty != null && title.endsWith(penalty!)) {
      return title.substring(0, title.length - penalty!.length).trim();
    }
    return title;
  }
}

/// Model for an IPG section containing multiple infractions.
class IpgSection {
  final int sectionNumber; // e.g., 2
  final String title; // e.g., "2. Game Play Errors"
  final String sectionKey; // e.g., "ipg_section_2"
  final Map<String, dynamic> metadata;
  final List<IpgInfraction> infractions;

  IpgSection({
    required this.sectionNumber,
    required this.title,
    required this.sectionKey,
    required this.metadata,
    required this.infractions,
  });

  factory IpgSection.fromJson(Map<String, dynamic> json) {
    final infractionsList = json['infractions'] as List<dynamic>? ?? [];

    return IpgSection(
      sectionNumber: json['section_number'] as int,
      title: json['title'] as String,
      sectionKey: json['section_key'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      infractions: infractionsList.map((i) => IpgInfraction.fromJson(i as Map<String, dynamic>)).toList(),
    );
  }

  String get effectiveDate => metadata['effective_date'] as String? ?? 'Unknown';
}

/// Model for IPG index (table of contents).
class IpgIndex {
  final String title; // "Infraction Procedure Guide"
  final String documentType; // "ipg"
  final Map<String, dynamic> metadata;
  final List<IpgSectionInfo> sections;

  IpgIndex({
    required this.title,
    required this.documentType,
    required this.metadata,
    required this.sections,
  });

  factory IpgIndex.fromJson(Map<String, dynamic> json) {
    final sectionsList = json['sections'] as List<dynamic>? ?? [];

    return IpgIndex(
      title: json['title'] as String,
      documentType: json['document_type'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      sections: sectionsList.map((s) => IpgSectionInfo.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }

  String get effectiveDate => metadata['effective_date'] as String? ?? 'Unknown';
}

/// Brief section info from the index.
class IpgSectionInfo {
  final int sectionNumber;
  final String title;
  final String sectionKey;
  final int infractionCount;

  IpgSectionInfo({
    required this.sectionNumber,
    required this.title,
    required this.sectionKey,
    required this.infractionCount,
  });

  factory IpgSectionInfo.fromJson(Map<String, dynamic> json) {
    return IpgSectionInfo(
      sectionNumber: json['section_number'] as int,
      title: json['title'] as String,
      sectionKey: json['section_key'] as String,
      infractionCount: json['infraction_count'] as int,
    );
  }
}
