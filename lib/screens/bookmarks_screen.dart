import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../widgets/bookmark_list_view.dart';

/// Landing page for bookmarks showing "All" and user's lists
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => BookmarksScreenState();
}

class BookmarksScreenState extends State<BookmarksScreen> {
  final _favoritesService = FavoritesService();
  List<BookmarkList> _lists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() => _isLoading = true);
    final lists = await _favoritesService.getAllLists();
    setState(() {
      _lists = lists;
      _isLoading = false;
    });
  }

  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateListDialog(
        onListCreated: _loadLists,
      ),
    );
  }

  void _showEditListDialog(BookmarkList list) {
    showDialog(
      context: context,
      builder: (context) => _CreateListDialog(
        existingList: list,
        onListCreated: _loadLists,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BookmarkList list) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('What would you like to do with "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'keep'),
            child: const Text('Delete list but keep bookmarks'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'delete_all'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete list and remove bookmarks'),
          ),
        ],
      ),
    );

    if (result == null || result == 'cancel') return;

    // Delete the list
    final deleteBookmarks = result == 'delete_all';
    await _favoritesService.deleteList(list.id, deleteBookmarks: deleteBookmarks);
    await _loadLists();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deleteBookmarks
              ? 'List and bookmarks deleted'
              : 'List deleted, bookmarks kept'),
        ),
      );
    }
  }

  void _showListOptions(BookmarkList list) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit list'),
              onTap: () {
                Navigator.pop(context);
                _showEditListDialog(list);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text(
                'Delete list',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(list);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateListDialog,
        tooltip: 'Create new list',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // "All" card - shows all bookmarks
        _buildListCard(
          title: 'All',
          description: 'View all your bookmarks',
          icon: Icons.bookmark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BookmarkListView(
                  listId: null, // null = show all
                  title: 'All Bookmarks',
                ),
              ),
            ).then((_) => _loadLists()); // Reload when coming back
          },
        ),

        if (_lists.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Your Lists',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          ..._lists.map((list) => _buildListCardWithActions(list)),
        ],

        if (_lists.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No lists yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Organize your bookmarks by creating lists',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _showCreateListDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Your First List'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildListCardWithActions(BookmarkList list) {
    Widget card = _buildListCard(
      title: list.name,
      description: list.description,
      icon: Icons.folder,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookmarkListView(
              listId: list.id,
              title: list.name,
            ),
          ),
        ).then((_) => _loadLists());
      },
    );

    // Wrap with long-press detector
    card = GestureDetector(
      onLongPress: () => _showListOptions(list),
      child: card,
    );

    // Wrap with Dismissible for swipe-to-delete
    card = Dismissible(
      key: Key(list.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _showDeleteConfirmation(list);
        return false; // Don't auto-dismiss, we handle it manually
      },
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: card,
    );

    return card;
  }

  Widget _buildListCard({
    required String title,
    String? description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: description != null
            ? Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Dialog for creating or editing a bookmark list
class _CreateListDialog extends StatefulWidget {
  final BookmarkList? existingList; // null = create new, otherwise edit
  final VoidCallback onListCreated;

  const _CreateListDialog({
    this.existingList,
    required this.onListCreated,
  });

  @override
  State<_CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<_CreateListDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _favoritesService = FavoritesService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingList != null) {
      _nameController.text = widget.existingList!.name;
      _descriptionController.text = widget.existingList!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.existingList == null) {
        // Create new list
        await _favoritesService.createList(
          _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        // Update existing list
        await _favoritesService.updateList(
          widget.existingList!.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          ),
        );
      }

      if (mounted) {
        widget.onListCreated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingList == null
                ? 'List created'
                : 'List updated'),
          ),
        );
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
    return AlertDialog(
      title: Text(widget.existingList == null ? 'Create List' : 'Edit List'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'List name',
                hintText: 'e.g., Commander Rules, Storm Deck',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a list name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g., Rules for my Ur-Dragon deck',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveList,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingList == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
