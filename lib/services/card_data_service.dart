import 'dart:convert';
import 'package:flutter/services.dart';
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

    final jsonString = await rootBundle.loadString('assets/carddata/all_cards.json');
    final jsonList = json.decode(jsonString) as List<dynamic>;

    _allCards = jsonList
        .map((cardJson) => MagicCard.fromJson(cardJson as Map<String, dynamic>))
        .toList();

    // Sort alphabetically by name
    _allCards!.sort((a, b) => a.name.compareTo(b.name));

    return _allCards!;
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
}
