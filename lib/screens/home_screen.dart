import 'package:flutter/material.dart';
import 'rules_categories_screen.dart';
import 'credits_screen.dart';
import 'search_screen.dart';
import 'bookmarks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _bookmarksKey = GlobalKey<BookmarksScreenState>();

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

  List<Widget> _getAppBarActions() {
    // Bookmarks (2) has edit button
    if (_selectedIndex == 2) {
      return [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            _bookmarksKey.currentState?.toggleEditMode();
          },
          tooltip: 'Edit bookmarks',
        ),
      ];
    }
    // Other tabs have no actions
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: _getAppBarActions(),
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
          const NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Credits',
          ),
        ],
      ),
    );
  }
}
