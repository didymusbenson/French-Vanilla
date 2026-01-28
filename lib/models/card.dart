class MagicCard {
  final String name;
  final String? manaCost;
  final String type;
  final String? text;
  final List<String> subtypes;
  final List<String> keywords;
  final Map<String, String> legalities;
  final List<Ruling> rulings;

  MagicCard({
    required this.name,
    this.manaCost,
    required this.type,
    this.text,
    this.subtypes = const [],
    this.keywords = const [],
    this.legalities = const {},
    this.rulings = const [],
  });

  factory MagicCard.fromJson(Map<String, dynamic> json) {
    return MagicCard(
      name: json['name'] as String,
      manaCost: json['manaCost'] as String?,
      type: json['type'] as String,
      text: json['text'] as String?,
      subtypes: (json['subtypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      legalities: (json['legalities'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
          ) ??
          {},
      rulings: (json['rulings'] as List<dynamic>?)
              ?.map((e) => Ruling.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() => name;
}

class Ruling {
  final String date;
  final String text;

  Ruling({
    required this.date,
    required this.text,
  });

  factory Ruling.fromJson(Map<String, dynamic> json) {
    return Ruling(
      date: json['date'] as String,
      text: json['text'] as String,
    );
  }

  @override
  String toString() => '$date: $text';
}
