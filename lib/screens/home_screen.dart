import 'package:flutter/material.dart';
import 'sections_screen.dart';
import 'glossary_screen.dart';
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
    const SectionsScreen(),
    const GlossaryScreen(),
    BookmarksScreen(key: _bookmarksKey),
    const CreditsScreen(),
  ];

  static const List<String> _titles = [
    'Rules',
    'Glossary',
    'Bookmarks',
    'Credits',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _getAppBarActions() {
    // Rules (0) and Glossary (1) have search
    if (_selectedIndex == 0 || _selectedIndex == 1) {
      return [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(),
              ),
            );
          },
          tooltip: 'Search',
        ),
      ];
    }
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
    // Credits (3) has no actions
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Rules',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Glossary',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Credits',
          ),
        ],
      ),
    );
  }
}
