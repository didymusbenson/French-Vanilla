class SectionData {
  final String title;
  final String sectionKey;
  final SectionMetadata metadata;
  final LineRange lineRange;
  final String content;

  SectionData({
    required this.title,
    required this.sectionKey,
    required this.metadata,
    required this.lineRange,
    required this.content,
  });

  factory SectionData.fromJson(Map<String, dynamic> json) {
    return SectionData(
      title: json['title'] as String,
      sectionKey: json['section_key'] as String,
      metadata: SectionMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      lineRange: LineRange.fromJson(json['line_range'] as Map<String, dynamic>),
      content: json['content'] as String,
    );
  }
}

class SectionMetadata {
  final String effectiveDate;

  SectionMetadata({
    required this.effectiveDate,
  });

  factory SectionMetadata.fromJson(Map<String, dynamic> json) {
    return SectionMetadata(
      effectiveDate: json['effective_date'] as String,
    );
  }
}

class LineRange {
  final int start;
  final int end;

  LineRange({
    required this.start,
    required this.end,
  });

  factory LineRange.fromJson(Map<String, dynamic> json) {
    return LineRange(
      start: json['start'] as int,
      end: json['end'] as int,
    );
  }
}
