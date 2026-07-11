import 'package:flutter/material.dart';
import 'rules_categories_screen.dart';
import 'credits_screen.dart';
import 'search_screen.dart';
import 'bookmarks_screen.dart';
import '../services/content_update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<BookmarksScreenState> _bookmarksKey = GlobalKey<BookmarksScreenState>();

  List<Widget> get _screens => [
    const RulesCategoriesScreen(),
    const SearchScreen(),
    BookmarksScreen(key: _bookmarksKey),
    const CreditsScreen(),
  ];

  static const List<String> _titles = [
    'Rules',
    'Search',
    'Bookmarks',
    'Credits',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Credits tab icon, badged with a small dot when content updates are
  /// available (populated by the silent launch-time check).
  Widget _creditsIcon(IconData icon) {
    return ValueListenableBuilder<bool>(
      valueListenable: ContentUpdateService.instance.hasUpdates,
      builder: (context, hasUpdates, child) =>
          hasUpdates ? Badge(smallSize: 10, child: child) : child!,
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          // Show "Create List" button only on Bookmarks tab
          if (_selectedIndex == 2)
            TextButton(
              onPressed: () {
                _bookmarksKey.currentState?.showCreateListDialog();
              },
              child: const Text('Add'),
            ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Rules',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          NavigationDestination(
            icon: _creditsIcon(Icons.info_outline),
            selectedIcon: _creditsIcon(Icons.info),
            label: 'Credits',
          ),
        ],
      ),
    );
  }
}
