class Rule {
  final String number;
  final String title;
  final List<SubruleGroup> subruleGroups;

  Rule({
    required this.number,
    required this.title,
    this.subruleGroups = const [],
  });

  @override
  String toString() => '$number. $title';
}

class SubruleGroup {
  final String number; // e.g., "700.1"
  final String content; // Full text including 700.1, 700.1a, 700.1b, etc.

  SubruleGroup({
    required this.number,
    required this.content,
  });

  @override
  String toString() => number;
}
