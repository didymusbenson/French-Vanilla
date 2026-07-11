import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum BookmarkType { rule, glossary, card, mtr, ipg }

class BookmarkedItem {
  final String identifier; // Rule number (e.g., "702.9a") or glossary term name
  final String content; // Full text of the subrule or definition
  final BookmarkType type;
  final DateTime timestamp;
  final List<String> listIds; // IDs of lists this bookmark belongs to

  BookmarkedItem({
    required this.identifier,
    required this.content,
    required this.type,
    required this.timestamp,
    this.listIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'content': content,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'listIds': listIds,
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
        listIds: json['listIds'] != null
            ? List<String>.from(json['listIds'] as List)
            : [], // Migration-safe: default to empty array
      );

  /// Create a copy with updated listIds
  BookmarkedItem copyWith({
    String? identifier,
    String? content,
    BookmarkType? type,
    DateTime? timestamp,
    List<String>? listIds,
  }) {
    return BookmarkedItem(
      identifier: identifier ?? this.identifier,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      listIds: listIds ?? this.listIds,
    );
  }
}

class BookmarkList {
  final String id; // Unique identifier (UUID)
  final String name; // List name (user-provided)
  final String? description; // Optional short description
  final DateTime createdAt; // Creation timestamp

  BookmarkList({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BookmarkList.fromJson(Map<String, dynamic> json) => BookmarkList(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// Create a copy with updated fields
  BookmarkList copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return BookmarkList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FavoritesService {
  static const String _key = 'bookmarked_items';
  static const String _listsKey = 'bookmark_lists';

  // Singleton pattern
  static final FavoritesService _instance = FavoritesService._internal();

  factory FavoritesService() {
    return _instance;
  }

  FavoritesService._internal();

  SharedPreferences? _prefsCache;
  Future<void>? _operationQueue;

  Future<SharedPreferences> _getPrefs() async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!;
  }

  /// Queue operations to prevent race conditions on rapid bookmark toggles
  Future<T> _queueOperation<T>(Future<T> Function() operation) async {
    final previousOperation = _operationQueue;
    final completer = Completer<T>();

    _operationQueue = Future(() async {
      // Wait for previous operation to complete
      if (previousOperation != null) {
        await previousOperation;
      }

      // Execute this operation
      try {
        final result = await operation();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
        rethrow;
      }
    });

    return completer.future;
  }

  /// Get all bookmarked items, ordered alphabetically
  Future<List<BookmarkedItem>> getBookmarks() async {
    final prefs = await _getPrefs();
    final bookmarksJson = prefs.getStringList(_key) ?? [];

    final bookmarks = bookmarksJson
        .map((jsonStr) => BookmarkedItem.fromJson(
            json.decode(jsonStr) as Map<String, dynamic>))
        .toList();

    // Sort: type priority, then alphabetically within type
    // Priority: Rules → Glossary → Cards → MTR → IPG
    bookmarks.sort((a, b) {
      // Group by type first
      if (a.type != b.type) {
        final typeOrder = {
          BookmarkType.rule: 0,
          BookmarkType.glossary: 1,
          BookmarkType.card: 2,
          BookmarkType.mtr: 3,
          BookmarkType.ipg: 4,
        };
        return (typeOrder[a.type] ?? 5).compareTo(typeOrder[b.type] ?? 5);
      }
      // Within same type, sort appropriately
      if (a.type == BookmarkType.rule || a.type == BookmarkType.mtr || a.type == BookmarkType.ipg) {
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

  /// Internal helper: Add bookmark without queueing (for use within queued operations)
  Future<void> _addBookmarkInternal(String identifier, String content, BookmarkType type) async {
    final prefs = await _getPrefs();
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

  /// Internal helper: Remove bookmark without queueing (for use within queued operations)
  Future<void> _removeBookmarkInternal(String identifier, BookmarkType type) async {
    final prefs = await _getPrefs();
    var bookmarks = await getBookmarks();

    // Remove the bookmark
    bookmarks.removeWhere((bookmark) =>
      bookmark.identifier == identifier && bookmark.type == type);

    // Save to preferences
    final bookmarksJson =
        bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList();
    await prefs.setStringList(_key, bookmarksJson);
  }

  /// Add an item to bookmarks
  Future<void> addBookmark(String identifier, String content, BookmarkType type) async {
    return _queueOperation(() async {
      await _addBookmarkInternal(identifier, content, type);
    });
  }

  /// Remove an item from bookmarks
  Future<void> removeBookmark(String identifier, BookmarkType type) async {
    return _queueOperation(() async {
      await _removeBookmarkInternal(identifier, type);
    });
  }

  /// Toggle bookmark status
  Future<void> toggleBookmark(String identifier, String content, BookmarkType type) async {
    return _queueOperation(() async {
      if (await isBookmarked(identifier, type)) {
        await _removeBookmarkInternal(identifier, type);
      } else {
        await _addBookmarkInternal(identifier, content, type);
      }
    });
  }

  /// Refresh the stored snapshot content of an existing bookmark in place,
  /// preserving its list membership and timestamp. No-op if the bookmark
  /// doesn't exist or the content is already current. Used to self-heal rule
  /// bookmarks after a content update changes the underlying text.
  Future<void> refreshBookmarkContent(
      String identifier, BookmarkType type, String content) async {
    return _queueOperation(() async {
      final prefs = await _getPrefs();
      final bookmarks = await getBookmarks();
      final index = bookmarks.indexWhere(
          (b) => b.identifier == identifier && b.type == type);
      if (index == -1 || bookmarks[index].content == content) return;

      bookmarks[index] = bookmarks[index].copyWith(content: content);
      final bookmarksJson =
          bookmarks.map((b) => json.encode(b.toJson())).toList();
      await prefs.setStringList(_key, bookmarksJson);
    });
  }

  /// Clear all bookmarks
  Future<void> clearAllBookmarks() async {
    return _queueOperation(() async {
      final prefs = await _getPrefs();
      await prefs.remove(_key);
    });
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

  // ===== LIST MANAGEMENT METHODS =====

  /// Get all bookmark lists, sorted alphabetically by name
  Future<List<BookmarkList>> getAllLists() async {
    final prefs = await _getPrefs();
    final listsJson = prefs.getStringList(_listsKey) ?? [];

    final lists = listsJson
        .map((jsonStr) => BookmarkList.fromJson(
            json.decode(jsonStr) as Map<String, dynamic>))
        .toList();

    // Sort alphabetically by name
    lists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return lists;
  }

  /// Create a new list
  Future<BookmarkList> createList(String name, {String? description}) async {
    return _queueOperation(() async {
      final prefs = await _getPrefs();
      var lists = await getAllLists();

      // Generate unique ID
      const uuid = Uuid();
      final newList = BookmarkList(
        id: uuid.v4(),
        name: name,
        description: description,
        createdAt: DateTime.now(),
      );

      lists.add(newList);

      // Save to preferences
      final listsJson =
          lists.map((list) => json.encode(list.toJson())).toList();
      await prefs.setStringList(_listsKey, listsJson);

      return newList;
    });
  }

  /// Update an existing list
  Future<void> updateList(BookmarkList updatedList) async {
    return _queueOperation(() async {
      final prefs = await _getPrefs();
      var lists = await getAllLists();

      // Find and replace the list
      final index = lists.indexWhere((list) => list.id == updatedList.id);
      if (index != -1) {
        lists[index] = updatedList;

        // Save to preferences
        final listsJson =
            lists.map((list) => json.encode(list.toJson())).toList();
        await prefs.setStringList(_listsKey, listsJson);
      }
    });
  }

  /// Delete a list and optionally delete its bookmarks
  /// If deleteBookmarks is true, removes bookmarks that are only in this list
  /// If false, just removes the list membership
  Future<void> deleteList(String listId, {bool deleteBookmarks = false}) async {
    return _queueOperation(() async {
      final prefs = await _getPrefs();
      var lists = await getAllLists();
      var bookmarks = await getBookmarks();

      // Remove the list
      lists.removeWhere((list) => list.id == listId);

      if (deleteBookmarks) {
        // Remove bookmarks that are ONLY in this list
        bookmarks.removeWhere((bookmark) =>
            bookmark.listIds.contains(listId) && bookmark.listIds.length == 1);
      }

      // Always remove list membership from remaining bookmarks
      for (var i = 0; i < bookmarks.length; i++) {
        if (bookmarks[i].listIds.contains(listId)) {
          bookmarks[i] = bookmarks[i].copyWith(
            listIds: bookmarks[i].listIds.where((id) => id != listId).toList(),
          );
        }
      }

      // Save both lists and bookmarks
      final listsJson =
          lists.map((list) => json.encode(list.toJson())).toList();
      await prefs.setStringList(_listsKey, listsJson);

      final bookmarksJson =
          bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList();
      await prefs.setStringList(_key, bookmarksJson);
    });
  }

  /// Get bookmarks in a specific list
  Future<List<BookmarkedItem>> getBookmarksInList(String listId) async {
    final bookmarks = await getBookmarks();
    return bookmarks.where((bookmark) => bookmark.listIds.contains(listId)).toList();
  }

  /// Add a bookmark to a list
  Future<void> addBookmarkToList(String identifier, BookmarkType type, String listId) async {
    return _queueOperation(() async {
      final prefs = await _getPrefs();
      var bookmarks = await getBookmarks();

      // Find the bookmark
      final index = bookmarks.indexWhere(
        (bookmark) => bookmark.identifier == identifier && bookmark.type == type,
      );

      if (index != -1) {
        // Add list ID if not already present
        if (!bookmarks[index].listIds.contains(listId)) {
          bookmarks[index] = bookmarks[index].copyWith(
            listIds: [...bookmarks[index].listIds, listId],
          );

          // Save to preferences
          final bookmarksJson =
              bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList();
          await prefs.setStringList(_key, bookmarksJson);
        }
      }
    });
  }

  /// Remove a bookmark from a list
  Future<void> removeBookmarkFromList(String identifier, BookmarkType type, String listId) async {
    return _queueOperation(() async {
      final prefs = await _getPrefs();
      var bookmarks = await getBookmarks();

      // Find the bookmark
      final index = bookmarks.indexWhere(
        (bookmark) => bookmark.identifier == identifier && bookmark.type == type,
      );

      if (index != -1) {
        // Remove list ID
        bookmarks[index] = bookmarks[index].copyWith(
          listIds: bookmarks[index].listIds.where((id) => id != listId).toList(),
        );

        // Save to preferences
        final bookmarksJson =
            bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList();
        await prefs.setStringList(_key, bookmarksJson);
      }
    });
  }

  /// Add a bookmark to multiple lists at once
  Future<void> updateBookmarkLists(String identifier, BookmarkType type, List<String> listIds) async {
    return _queueOperation(() async {
      final prefs = await _getPrefs();
      var bookmarks = await getBookmarks();

      // Find the bookmark
      final index = bookmarks.indexWhere(
        (bookmark) => bookmark.identifier == identifier && bookmark.type == type,
      );

      if (index != -1) {
        bookmarks[index] = bookmarks[index].copyWith(listIds: listIds);

        // Save to preferences
        final bookmarksJson =
            bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList();
        await prefs.setStringList(_key, bookmarksJson);
      }
    });
  }

  /// Bulk remove bookmarks (optimized for deleting multiple at once)
  Future<void> removeBookmarks(List<String> identifiers, List<BookmarkType> types) async {
    if (identifiers.length != types.length) {
      throw ArgumentError('identifiers and types must have same length');
    }

    return _queueOperation(() async {
      final prefs = await _getPrefs();
      var bookmarks = await getBookmarks();

      // Remove all bookmarks in one pass
      for (var i = 0; i < identifiers.length; i++) {
        bookmarks.removeWhere((bookmark) =>
            bookmark.identifier == identifiers[i] && bookmark.type == types[i]);
      }

      // Single write operation
      final bookmarksJson =
          bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList();
      await prefs.setStringList(_key, bookmarksJson);
    });
  }

  /// Bulk remove bookmarks from a specific list (optimized for deleting multiple at once)
  Future<void> removeBookmarksFromList(
      List<String> identifiers, List<BookmarkType> types, String listId) async {
    if (identifiers.length != types.length) {
      throw ArgumentError('identifiers and types must have same length');
    }

    return _queueOperation(() async {
      final prefs = await _getPrefs();
      var bookmarks = await getBookmarks();

      // Remove list membership from all specified bookmarks in one pass
      for (var i = 0; i < identifiers.length; i++) {
        final index = bookmarks.indexWhere(
          (bookmark) =>
              bookmark.identifier == identifiers[i] && bookmark.type == types[i],
        );

        if (index != -1) {
          bookmarks[index] = bookmarks[index].copyWith(
            listIds:
                bookmarks[index].listIds.where((id) => id != listId).toList(),
          );
        }
      }

      // Single write operation
      final bookmarksJson =
          bookmarks.map((bookmark) => json.encode(bookmark.toJson())).toList();
      await prefs.setStringList(_key, bookmarksJson);
    });
  }
}
