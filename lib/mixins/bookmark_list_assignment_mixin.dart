import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../widgets/list_selection_sheet.dart';

/// Mixin for showing "Add to list" snackbar after bookmarking
mixin BookmarkListAssignmentMixin<T extends StatefulWidget> on State<T> {
  /// Show snackbar with "Add to list" action after bookmarking
  void showBookmarkSnackbarWithListAction({
    required String identifier,
    required BookmarkType type,
    required bool isNowBookmarked,
  }) {
    if (!isNowBookmarked) {
      // Item was unbookmarked, show simple message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark removed')),
      );
      return;
    }

    // Item was bookmarked, show "Add to list" action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bookmarked'),
        action: SnackBarAction(
          label: 'Add to list',
          onPressed: () => showListSelectionSheet(
            identifier: identifier,
            type: type,
          ),
        ),
      ),
    );
  }

  /// Show the list selection bottom sheet
  Future<void> showListSelectionSheet({
    required String identifier,
    required BookmarkType type,
  }) async {
    // Get current bookmark to check list memberships
    final favoritesService = FavoritesService();
    final bookmarks = await favoritesService.getBookmarks();
    final bookmark = bookmarks.firstWhere(
      (b) => b.identifier == identifier && b.type == type,
      orElse: () => BookmarkedItem(
        identifier: identifier,
        content: '',
        type: type,
        timestamp: DateTime.now(),
        listIds: [],
      ),
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ListSelectionSheet(
        bookmarkIdentifier: identifier,
        bookmarkType: type,
        currentListIds: bookmark.listIds,
      ),
    );
  }
}
