import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum BookmarkType { rule, glossary }

class BookmarkedItem {
  final String identifier; // Rule number (e.g., "702.9a") or glossary term name
  final String content; // Full text of the subrule or definition
  final BookmarkType type;
  final DateTime timestamp;

  BookmarkedItem({
    required this.identifier,
    required this.content,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'content': content,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BookmarkedItem.fromJson(Map<String, dynamic> json) =>
      BookmarkedItem(
        identifier: json['identifier'] as String,
        content: json['content'] as String,
        type: BookmarkType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => BookmarkType.rule,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class FavoritesService {
  static const String _key = 'bookmarked_items';

  /// Get all bookmarked items, ordered alphabetically
  Future<List<BookmarkedItem>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList(_key) ?? [];

    final bookmarks = bookmarksJson
        .map((jsonStr) => BookmarkedItem.fromJson(
            json.decode(jsonStr) as Map<String, dynamic>))
        .toList();

    // Sort: rules by number, glossary terms alphabetically
    bookmarks.sort((a, b) {
      // Group by type first (rules before glossary)
      if (a.type != b.type) {
        return a.type == BookmarkType.rule ? -1 : 1;
      }
      // Within same type, sort appropriately
      if (a.type == BookmarkType.rule) {
        return _compareRuleNumbers(a.identifier, b.identifier);
      } else {
        return a.identifier.toLowerCase().compareTo(b.identifier.toLowerCase());
      }
    });

    return bookmarks;
  }

  /// Check if an item is bookmarked
  Future<bool> isBookmarked(String identifier, BookmarkType type) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((bookmark) =>
      bookmark.identifier == identifier && bookmark.type == type);
  }

  /// Add an item to bookmarks
  Future<void> addBookmark(String identifier, String content, BookmarkType type) async {
    final prefs = await SharedPreferences.getInstance();
    var bookmarks = await getBookmarks();

    // Remove existing bookmark if it exists
    bookmarks.removeWhere((bookmark) =>
      bookmark.identifier == identifier && bookmark.type == type);

    // Add new bookmark
    bookmarks.add(
      BookmarkedItem(
        identifier: identifier,
        content: content,
        type: type,
        timestamp: DateTime.now(),
      ),
    );

    // Save to preferences
    final bookmarksJson =
        bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList();
    await prefs.setStringList(_key, bookmarksJson);
  }

  /// Remove an item from bookmarks
  Future<void> removeBookmark(String identifier, BookmarkType type) async {
    final prefs = await SharedPreferences.getInstance();
    var bookmarks = await getBookmarks();

    // Remove the bookmark
    bookmarks.removeWhere((bookmark) =>
      bookmark.identifier == identifier && bookmark.type == type);

    // Save to preferences
    final bookmarksJson =
        bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList();
    await prefs.setStringList(_key, bookmarksJson);
  }

  /// Toggle bookmark status
  Future<void> toggleBookmark(String identifier, String content, BookmarkType type) async {
    if (await isBookmarked(identifier, type)) {
      await removeBookmark(identifier, type);
    } else {
      await addBookmark(identifier, content, type);
    }
  }

  /// Clear all bookmarks
  Future<void> clearAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Compare rule numbers for alphabetical sorting
  /// Handles formats like "702.9", "702.9a", "702.10", etc.
  int _compareRuleNumbers(String a, String b) {
    // Split by dot to get major.minor parts
    final aParts = a.split('.');
    final bParts = b.split('.');

    // Compare major numbers
    final aMajor = int.tryParse(aParts[0]) ?? 0;
    final bMajor = int.tryParse(bParts[0]) ?? 0;
    if (aMajor != bMajor) return aMajor.compareTo(bMajor);

    // Compare minor parts (may have letters like "9a")
    if (aParts.length > 1 && bParts.length > 1) {
      final aMinor = aParts[1];
      final bMinor = bParts[1];

      // Extract numeric part
      final aMinorNum = int.tryParse(aMinor.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final bMinorNum = int.tryParse(bMinor.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      if (aMinorNum != bMinorNum) return aMinorNum.compareTo(bMinorNum);

      // If numbers are same, compare letter suffix (e.g., "9a" vs "9b")
      return aMinor.compareTo(bMinor);
    }

    return 0;
  }
}
