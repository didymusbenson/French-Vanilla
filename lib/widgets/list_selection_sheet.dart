import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

/// Bottom sheet for selecting which lists a bookmark belongs to
class ListSelectionSheet extends StatefulWidget {
  final String bookmarkIdentifier;
  final BookmarkType bookmarkType;
  final List<String> currentListIds;

  const ListSelectionSheet({
    super.key,
    required this.bookmarkIdentifier,
    required this.bookmarkType,
    required this.currentListIds,
  });

  @override
  State<ListSelectionSheet> createState() => _ListSelectionSheetState();
}

class _ListSelectionSheetState extends State<ListSelectionSheet> {
  final _favoritesService = FavoritesService();
  List<BookmarkList> _allLists = [];
  Set<String> _selectedListIds = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedListIds = Set.from(widget.currentListIds);
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    final lists = await _favoritesService.getAllLists();
    if (!mounted) return;
    setState(() {
      _allLists = lists;
      _isLoading = false;
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      // Update bookmark with new list memberships
      await _favoritesService.updateBookmarkLists(
        widget.bookmarkIdentifier,
        widget.bookmarkType,
        _selectedListIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Add to Lists',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (_isSaving)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: _saveChanges,
                    child: const Text('Done'),
                  ),
              ],
            ),
          ),
          const Divider(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_allLists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No lists yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a list from the Bookmarks tab to organize your bookmarks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _allLists.length,
                itemBuilder: (context, index) {
                  final list = _allLists[index];
                  final isSelected = _selectedListIds.contains(list.id);

                  return CheckboxListTile(
                    title: Text(list.name),
                    subtitle: list.description != null
                        ? Text(
                            list.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    value: isSelected,
                    onChanged: _isSaving
                        ? null
                        : (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedListIds.add(list.id);
                              } else {
                                _selectedListIds.remove(list.id);
                              }
                            });
                          },
                  );
                },
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                _selectedListIds.isEmpty
                    ? 'Not in any lists'
                    : '${_selectedListIds.length} list${_selectedListIds.length == 1 ? '' : 's'} selected',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
