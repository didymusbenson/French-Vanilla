import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryEntry {
  final String query;
  final int resultCount;
  final DateTime timestamp;

  SearchHistoryEntry({
    required this.query,
    required this.resultCount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'resultCount': resultCount,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SearchHistoryEntry(
        query: json['query'] as String,
        resultCount: json['resultCount'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class SearchHistoryService {
  static const String _key = 'search_history';
  static const int _maxHistorySize = 15;

  /// Get all recent searches, ordered by most recent first
  Future<List<SearchHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_key) ?? [];

    return historyJson
        .map((jsonStr) => SearchHistoryEntry.fromJson(
            json.decode(jsonStr) as Map<String, dynamic>))
        .toList();
  }

  /// Add a search to history (or move to top if already exists)
  Future<void> addSearch(String query, int resultCount) async {
    final prefs = await SharedPreferences.getInstance();
    var history = await getHistory();

    // Remove existing entry with same query (case-insensitive)
    history.removeWhere(
        (entry) => entry.query.toLowerCase() == query.toLowerCase());

    // Add new entry at the beginning
    history.insert(
      0,
      SearchHistoryEntry(
        query: query,
        resultCount: resultCount,
        timestamp: DateTime.now(),
      ),
    );

    // Limit to max size
    if (history.length > _maxHistorySize) {
      history = history.sublist(0, _maxHistorySize);
    }

    // Save to preferences
    final historyJson =
        history.map((entry) => json.encode(entry.toJson())).toList();
    await prefs.setStringList(_key, historyJson);
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
