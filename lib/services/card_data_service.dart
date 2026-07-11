import 'dart:convert';
import 'content_resolver.dart';
import '../models/card.dart';

class CardDataService {
  static final CardDataService _instance = CardDataService._internal();
  factory CardDataService() => _instance;
  CardDataService._internal();

  // Cache for loaded cards
  List<MagicCard>? _allCards;

  /// Load all cards from assets
  Future<List<MagicCard>> loadAllCards() async {
    if (_allCards != null) return _allCards!;

    final jsonString = await ContentResolver.instance
        .loadString('rulings', 'all_cards.json');
    final jsonList = json.decode(jsonString) as List<dynamic>;

    _allCards = jsonList
        .map((cardJson) => MagicCard.fromJson(cardJson as Map<String, dynamic>))
        .toList();

    // Sort alphabetically by name
    _allCards!.sort((a, b) => a.name.compareTo(b.name));

    return _allCards!;
  }

  /// Drop the cached card list so the next load reads the (possibly
  /// just-updated) active source. Called after an over-the-air rulings update.
  void reset() {
    _allCards = null;
  }

  /// Get cards with rulings only
  Future<List<MagicCard>> getCardsWithRulings() async {
    final allCards = await loadAllCards();
    return allCards.where((card) => card.rulings.isNotEmpty).toList();
  }

  /// Search cards by name
  Future<List<MagicCard>> searchCards(String query) async {
    if (query.trim().isEmpty) {
      return await loadAllCards();
    }

    final allCards = await loadAllCards();
    final lowerQuery = query.toLowerCase();

    return allCards
        .where((card) => card.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get a specific card by exact name
  Future<MagicCard?> getCardByName(String name) async {
    final allCards = await loadAllCards();
    try {
      return allCards.firstWhere(
        (card) => card.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Search cards with rulings by name (for universal search)
  Future<List<MagicCard>> searchCardRulings(String query) async {
    if (query.trim().isEmpty) return [];

    final cardsWithRulings = await getCardsWithRulings();
    final lowerQuery = query.toLowerCase();

    return cardsWithRulings
        .where((card) => card.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
