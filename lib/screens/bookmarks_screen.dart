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

  @override
  Widget build(BuildContext context) {
    return _buildBody();
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
          ..._lists.map((list) => _buildListCard(
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
                  ).then((_) => _loadLists()); // Reload when coming back
                },
              )),
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
                  onPressed: () {
                    // TODO: Show create list dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('List creation coming in Step 3')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Your First List'),
                ),
              ],
            ),
          ),
      ],
    );
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
